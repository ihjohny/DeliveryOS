import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { RedisService } from '../../common/redis/redis.service';
import { TrackingGateway } from '../realtime/tracking.gateway';
import { OrderFlowMode, UpdateOrderFlowDto } from './dto/update-order-flow.dto';
import { OrderStatus } from '@prisma/client';

interface OrderFlowSettingValue {
  mode?: OrderFlowMode;
  rider_search_timeout_seconds?: number;
}

interface AddressSnapshot {
  addressLine?: string;
  [key: string]: unknown;
}

@Injectable()
export class OrderFlowService {
  private readonly logger = new Logger(OrderFlowService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly trackingGateway: TrackingGateway,
  ) {}

  /**
   * 1. Get Active Order Flow Configuration
   * Reads from Redis cache (or Postgres fallback) to determine whether
   * the system is operating in RIDER_FIRST or VENDOR_FIRST.
   */
  async getOrderFlowConfig(): Promise<{
    mode: OrderFlowMode;
    riderSearchTimeoutSeconds: number;
  }> {
    const setting = await this.prisma.systemSetting.findUnique({
      where: { key: 'order_flow_config' },
    });

    const val = (setting?.value as OrderFlowSettingValue | null) || {};
    return {
      mode: val.mode === OrderFlowMode.VENDOR_FIRST ? OrderFlowMode.VENDOR_FIRST : OrderFlowMode.RIDER_FIRST,
      riderSearchTimeoutSeconds: val.rider_search_timeout_seconds || 90,
    };
  }

  /**
   * 2. Update Order Flow Configuration
   */
  async setOrderFlowConfig(dto: UpdateOrderFlowDto) {
    const updated = await this.prisma.systemSetting.upsert({
      where: { key: 'order_flow_config' },
      update: {
        value: {
          mode: dto.mode,
          rider_search_timeout_seconds: dto.riderSearchTimeoutSeconds ?? 90,
          description:
            dto.mode === OrderFlowMode.RIDER_FIRST
              ? 'Zero Food Waste Mode: Secures rider before kitchen begins prep.'
              : 'Traditional Retail Mode: Store preps first, broadcasts to riders when ready.',
        },
      },
      create: {
        key: 'order_flow_config',
        value: {
          mode: dto.mode,
          rider_search_timeout_seconds: dto.riderSearchTimeoutSeconds ?? 90,
        },
        description: 'Order fulfillment flow sequence (RIDER_FIRST vs VENDOR_FIRST)',
      },
    });

    this.logger.log(`Order flow mode updated to: ${dto.mode}`);
    return updated.value;
  }

  /**
   * 3. Update Rider Real-time Location in Redis Spatial Index
   */
  async updateRiderLocation(riderId: string, latitude: number, longitude: number) {
    await this.redis.geoadd('riders:locations:active', longitude, latitude, riderId);
  }

  /**
   * 4. Find Nearby Available Online Riders within Proximity Radius (km)
   */
  async findNearbyAvailableRiders(
    vendorLat: number,
    vendorLng: number,
    radiusKm: number = 5,
  ): Promise<Array<{ riderId: string; distanceKm: number }>> {
    const rawResults = await this.redis.geosearch(
      'riders:locations:active',
      vendorLng,
      vendorLat,
      radiusKm,
    );

    const availableRiders: Array<{ riderId: string; distanceKm: number }> = [];

    for (const item of rawResults) {
      // item is [riderId, distanceString]
      const riderId = Array.isArray(item) ? item[0] : item;
      const distanceKm = Array.isArray(item) ? parseFloat(item[1]) : 0;

      // Check if rider is currently busy on an active delivery
      const isBusy = await this.redis.get(`rider:active_order:${riderId}`);
      if (isBusy) continue;

      // Verify rider is online in database
      const rider = await this.prisma.rider.findUnique({
        where: { id: riderId },
        select: { isOnline: true },
      });

      if (rider && rider.isOnline) {
        availableRiders.push({ riderId, distanceKm });
      }
    }

    return availableRiders;
  }

  /**
   * 5. Dispatch Event Handler: Triggered immediately when customer places order
   */
  async handleOrderPlaced(orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        vendor: true,
        orderItems: true,
        customer: { select: { fullName: true, phone: true } },
      },
    });

    if (!order) return;

    const { mode, riderSearchTimeoutSeconds } = await this.getOrderFlowConfig();

    if (mode === OrderFlowMode.RIDER_FIRST) {
      // RIDER_FIRST: Zero Food Waste Mode
      // Broadcast immediately to nearby riders in riders_pool.
      // Vendor chime is withheld until a delivery rider is secured!
      const deliveryAddress = (order.deliveryAddressSnapshot as AddressSnapshot | null)?.addressLine || 'Customer Address';
      const riderEarnings = Math.round(Number(order.deliveryFee) * 0.8 * 100) / 100;

      this.trackingGateway.broadcastDispatch({
        orderId: order.id,
        orderNumber: order.orderNumber,
        vendorId: order.vendorId,
        vendorName: order.vendor.name,
        vendorAddress: order.vendor.addressText,
        deliveryArea: deliveryAddress,
        itemCount: order.orderItems.reduce((acc, i) => acc + i.quantity, 0),
        totalAmount: Number(order.totalAmount),
        riderEarnings,
        timeoutSeconds: riderSearchTimeoutSeconds,
      });

      this.logger.log(
        `[RIDER_FIRST] Order ${order.orderNumber} broadcasted to riders_pool. Vendor chime held until rider claim.`,
      );
    } else {
      // VENDOR_FIRST: Traditional Retail Mode
      // Trigger vendor chime immediately
      this.trackingGateway.notifyNewOrder(order.vendorId, {
        orderId: order.id,
        orderNumber: order.orderNumber,
        vendorId: order.vendorId,
        vendorName: order.vendor.name,
        itemCount: order.orderItems.reduce((acc, i) => acc + i.quantity, 0),
        totalAmount: Number(order.totalAmount),
        paymentMethod: order.paymentMethod,
        customerNotes: order.customerNotes,
        items: order.orderItems.map((i) => ({
          name: i.productNameSnapshot,
          quantity: i.quantity,
        })),
        placedAt: order.placedAt.toISOString(),
      });

      this.logger.log(`[VENDOR_FIRST] Order ${order.orderNumber} sent directly to vendor kitchen console.`);
    }
  }

  /**
   * 6. Dispatch Event Handler: Triggered when vendor marks order READY_FOR_PICKUP
   */
  async handleOrderReady(orderId: string) {
    const { mode, riderSearchTimeoutSeconds } = await this.getOrderFlowConfig();

    // In VENDOR_FIRST mode, rider broadcast is triggered when food is packaged
    if (mode === OrderFlowMode.VENDOR_FIRST) {
      const order = await this.prisma.order.findUnique({
        where: { id: orderId },
        include: { vendor: true, orderItems: true },
      });

      if (!order || order.riderId) return; // already assigned or not found

      const deliveryAddress = (order.deliveryAddressSnapshot as AddressSnapshot | null)?.addressLine || 'Customer Address';
      const riderEarnings = Math.round(Number(order.deliveryFee) * 0.8 * 100) / 100;

      this.trackingGateway.broadcastDispatch({
        orderId: order.id,
        orderNumber: order.orderNumber,
        vendorId: order.vendorId,
        vendorName: order.vendor.name,
        vendorAddress: order.vendor.addressText,
        deliveryArea: deliveryAddress,
        itemCount: order.orderItems.reduce((acc, i) => acc + i.quantity, 0),
        totalAmount: Number(order.totalAmount),
        riderEarnings,
        timeoutSeconds: riderSearchTimeoutSeconds,
      });

      this.logger.log(`[VENDOR_FIRST] Order ${order.orderNumber} READY_FOR_PICKUP broadcasted to riders_pool.`);
    }
  }

  /**
   * 7. Atomic Rider Order Claim protected by Redis Distributed Mutex
   */
  async claimOrder(riderUserId: string, orderId: string) {
    const rider = await this.prisma.rider.findUnique({
      where: { userId: riderUserId },
      include: {
        user: { select: { fullName: true, phone: true } },
      },
    });

    if (!rider || !rider.isOnline) {
      throw new BadRequestException('Rider is offline or profile not found');
    }

    // Check if rider already has an active order
    const alreadyBusy = await this.redis.get(`rider:active_order:${rider.id}`);
    if (alreadyBusy) {
      throw new BadRequestException('You already have an active assigned delivery trip');
    }

    // Acquire Redis Distributed Mutex (10-second TTL)
    const lockKey = `lock:order_claim:${orderId}`;
    const acquired = await this.redis.acquireLock(lockKey, rider.id, 10);

    if (!acquired) {
      throw new ConflictException('This order is currently being claimed by another rider.');
    }

    try {
      const { mode } = await this.getOrderFlowConfig();

      const updatedOrder = await this.prisma.$transaction(async (tx) => {
        const order = await tx.order.findUnique({
          where: { id: orderId },
          include: { vendor: true, orderItems: true },
        });

        if (!order) {
          throw new NotFoundException('Order not found');
        }

        if (order.riderId !== null) {
          throw new ConflictException('This order has already been secured by another delivery rider.');
        }

        if (order.status === OrderStatus.CANCELLED || order.status === OrderStatus.DELIVERED) {
          throw new BadRequestException(`Order cannot be claimed in status "${order.status}"`);
        }

        const newStatus = mode === OrderFlowMode.RIDER_FIRST ? OrderStatus.RIDER_ASSIGNED : order.status;

        const updated = await tx.order.update({
          where: { id: orderId },
          data: {
            riderId: rider.id,
            status: newStatus,
          },
          include: {
            vendor: true,
            orderItems: true,
          },
        });

        // Mark rider as busy in Redis
        await this.redis.set(`rider:active_order:${rider.id}`, orderId);

        return updated;
      });

      // Side Effects outside DB transaction:
      if (mode === OrderFlowMode.RIDER_FIRST) {
        // Emit RIDER_ASSIGNED to customer tracking
        this.trackingGateway.notifyOrderStatusChanged(
          updatedOrder.id,
          updatedOrder.customerId,
          OrderStatus.PLACED,
          OrderStatus.RIDER_ASSIGNED,
          {
            riderId: rider.id,
            riderName: rider.user.fullName,
            riderPhone: rider.user.phone,
          },
        );

        // NOW trigger Vendor kitchen chime with Rider Guaranteed Badge!
        this.trackingGateway.notifyNewOrder(updatedOrder.vendorId, {
          orderId: updatedOrder.id,
          orderNumber: updatedOrder.orderNumber,
          vendorId: updatedOrder.vendorId,
          vendorName: updatedOrder.vendor.name,
          riderAssigned: true,
          riderName: rider.user.fullName,
          riderPhone: rider.user.phone,
          itemCount: updatedOrder.orderItems.reduce((acc, i) => acc + i.quantity, 0),
          totalAmount: Number(updatedOrder.totalAmount),
          paymentMethod: updatedOrder.paymentMethod,
          customerNotes: updatedOrder.customerNotes,
          items: updatedOrder.orderItems.map((i) => ({
            name: i.productNameSnapshot,
            quantity: i.quantity,
          })),
          placedAt: updatedOrder.placedAt.toISOString(),
        });

        this.logger.log(
          `[RIDER_FIRST] Rider ${rider.user.fullName} secured order ${updatedOrder.orderNumber}. Kitchen console alerted!`,
        );
      } else {
        // VENDOR_FIRST: Emit status update with assigned rider
        this.trackingGateway.notifyOrderStatusChanged(
          updatedOrder.id,
          updatedOrder.customerId,
          updatedOrder.status,
          updatedOrder.status,
          {
            riderId: rider.id,
            riderName: rider.user.fullName,
            riderPhone: rider.user.phone,
          },
        );
      }

      return updatedOrder;
    } finally {
      // Safely release Redis distributed lock
      await this.redis.releaseLock(lockKey, rider.id);
    }
  }

  /**
   * 8. Release Rider Active Order (called upon delivery)
   */
  async releaseRiderActiveTrip(riderId: string) {
    await this.redis.del(`rider:active_order:${riderId}`);
  }
}
