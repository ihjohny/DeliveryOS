import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { DeliverOrderDto } from './dto/deliver-order.dto';
import { OrderStatus, PaymentMethod, PaymentStatus, SettlementStatus } from '@prisma/client';
import { TrackingGateway } from '../realtime/tracking.gateway';
import { OrderFlowService } from '../order-flow/order-flow.service';

@Injectable()
export class RiderService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly trackingGateway: TrackingGateway,
    private readonly orderFlowService: OrderFlowService,
  ) {}

  /**
   * Helper: Retrieve rider profile by userId
   */
  async getRiderProfile(userId: string) {
    const rider = await this.prisma.rider.findUnique({
      where: { userId },
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            phone: true,
            email: true,
            role: true,
            status: true,
          },
        },
      },
    });

    if (!rider) {
      throw new NotFoundException('Rider profile not found for this user account');
    }

    return rider;
  }

  /**
   * 1. Toggle Duty State (Online/Offline)
   */
  async toggleDuty(userId: string, isOnline: boolean) {
    const rider = await this.getRiderProfile(userId);

    return this.prisma.rider.update({
      where: { id: rider.id },
      data: { isOnline },
    });
  }

  /**
   * 2. Claim Broadcasted Order
   */
  async claimOrder(userId: string, orderId: string) {
    return this.orderFlowService.claimOrder(userId, orderId);
  }

  /**
   * 3. Confirm Order Pickup at Vendor Outlet
   */
  async pickupOrder(userId: string, orderId: string) {
    const rider = await this.getRiderProfile(userId);

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    if (order.riderId && order.riderId !== rider.id) {
      throw new ForbiddenException('This order is assigned to another delivery rider');
    }

    if (
      order.status !== OrderStatus.READY_FOR_PICKUP &&
      order.status !== OrderStatus.PREPARING &&
      order.status !== OrderStatus.ACCEPTED &&
      order.status !== OrderStatus.RIDER_ASSIGNED
    ) {
      throw new BadRequestException(
        `Order cannot be picked up in status "${order.status}". Must be ready or in prep.`,
      );
    }

    const updatedOrder = await this.prisma.order.update({
      where: { id: orderId },
      data: {
        riderId: rider.id,
        status: OrderStatus.DISPATCHED,
        pickedUpAt: new Date(),
      },
    });

    // Realtime Broadcast: order:status:changed (DISPATCHED)
    this.trackingGateway.notifyOrderStatusChanged(
      order.id,
      order.customerId,
      order.status,
      OrderStatus.DISPATCHED,
      { riderId: rider.id },
    );

    return updatedOrder;
  }

  /**
   * 3. Confirm Delivery & COD Collection
   * Records cash collected on COD orders and records entry in rider_trip_ledgers.
   */
  async deliverOrder(userId: string, orderId: string, dto: DeliverOrderDto) {
    const rider = await this.getRiderProfile(userId);

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { riderTrip: true },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    if (order.riderId && order.riderId !== rider.id) {
      throw new ForbiddenException('You are not the assigned rider for this order');
    }

    if (order.status !== OrderStatus.DISPATCHED) {
      throw new BadRequestException(
        `Cannot deliver order in status "${order.status}". Order must be DISPATCHED.`,
      );
    }

    const codCollected = dto.amountCollected ?? (dto.codCashCollected ? Number(order.totalAmount) : 0);

    const result = await this.prisma.$transaction(async (tx) => {
      // 1. Update Order Status
      const updatedOrder = await tx.order.update({
        where: { id: orderId },
        data: {
          riderId: rider.id,
          status: OrderStatus.DELIVERED,
          deliveredAt: new Date(),
          paymentStatus:
            order.paymentMethod === PaymentMethod.CASH_ON_DELIVERY && dto.codCashCollected
              ? PaymentStatus.PAID
              : order.paymentStatus,
        },
      });

      // 2. If COD cash collected, add to rider cashInHand
      if (codCollected > 0) {
        await tx.rider.update({
          where: { id: rider.id },
          data: {
            cashInHand: { increment: codCollected },
          },
        });
      }

      // 3. Upsert Trip Ledger
      const tripLedger = await tx.riderTripLedger.upsert({
        where: { orderId },
        create: {
          orderId,
          riderId: rider.id,
          deliveryEarnings: order.deliveryFee,
          codCollected,
          status: SettlementStatus.PENDING,
        },
        update: {
          deliveryEarnings: order.deliveryFee,
          codCollected,
        },
      });

      return {
        order: updatedOrder,
        tripLedger,
      };
    });

    // Realtime Broadcast: order:status:changed (DELIVERED)
    this.trackingGateway.notifyOrderStatusChanged(
      order.id,
      order.customerId,
      order.status,
      OrderStatus.DELIVERED,
      { codCollected },
    );

    // Release rider active trip state in Redis
    await this.orderFlowService.releaseRiderActiveTrip(rider.id);

    return result;
  }
}
