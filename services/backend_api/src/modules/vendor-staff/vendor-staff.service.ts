import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { AcceptOrderDto } from './dto/accept-order.dto';
import { OrderStatus, PermissionScope, User, UserRole } from '@prisma/client';

@Injectable()
export class VendorStaffService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Enforces 2-Tier Vendor Staff Scope:
   * - SUPER_ADMIN: Global authority across all outlets.
   * - ALL_OUTLETS_MASTER: Permitted across any outlet sharing the brandId.
   * - PARTICULAR_OUTLET: Strictly locked to the designated vendorId.
   */
  async validateStaffOutletAccess(user: User, vendorId: string) {
    if (user.role === UserRole.SUPER_ADMIN) {
      return true;
    }

    if (user.role !== UserRole.VENDOR_ADMIN) {
      throw new ForbiddenException('Access restricted to vendor staff');
    }

    const staffRecords = await this.prisma.vendorStaff.findMany({
      where: { userId: user.id, isActive: true },
    });

    if (staffRecords.length === 0) {
      throw new ForbiddenException('No active vendor staff assignment found for this user');
    }

    const targetVendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
    });

    if (!targetVendor) {
      throw new NotFoundException('Vendor outlet not found');
    }

    // Check permissions
    for (const record of staffRecords) {
      if (record.scope === PermissionScope.ALL_OUTLETS_MASTER) {
        if (record.brandId && targetVendor.brandId === record.brandId) {
          return true;
        }
      } else if (record.scope === PermissionScope.PARTICULAR_OUTLET) {
        if (record.vendorId === vendorId) {
          return true;
        }
      }
    }

    throw new ForbiddenException('You do not have permission to manage this vendor outlet');
  }

  /**
   * 1. Get Live Kitchen Orders
   */
  async getLiveOrders(user: User, vendorId?: string) {
    let targetVendorIds: string[] = [];

    if (user.role === UserRole.SUPER_ADMIN) {
      if (vendorId) {
        targetVendorIds = [vendorId];
      }
    } else {
      const staffRecords = await this.prisma.vendorStaff.findMany({
        where: { userId: user.id, isActive: true },
      });

      if (staffRecords.length === 0) {
        throw new ForbiddenException('No active vendor staff assignment found');
      }

      if (vendorId) {
        await this.validateStaffOutletAccess(user, vendorId);
        targetVendorIds = [vendorId];
      } else {
        for (const record of staffRecords) {
          if (record.scope === PermissionScope.ALL_OUTLETS_MASTER && record.brandId) {
            const brandOutlets = await this.prisma.vendor.findMany({
              where: { brandId: record.brandId },
              select: { id: true },
            });
            targetVendorIds.push(...brandOutlets.map((o) => o.id));
          } else if (record.scope === PermissionScope.PARTICULAR_OUTLET && record.vendorId) {
            targetVendorIds.push(record.vendorId);
          }
        }
      }
    }

    const whereClause: any = {
      status: {
        in: [
          OrderStatus.PLACED,
          OrderStatus.RIDER_ASSIGNED,
          OrderStatus.ACCEPTED,
          OrderStatus.PREPARING,
          OrderStatus.READY_FOR_PICKUP,
        ],
      },
    };

    if (targetVendorIds.length > 0) {
      whereClause.vendorId = { in: targetVendorIds };
    }

    return this.prisma.order.findMany({
      where: whereClause,
      orderBy: { placedAt: 'desc' },
      include: {
        orderItems: true,
        vendor: {
          select: {
            id: true,
            name: true,
            defaultPrepTimeMinutes: true,
          },
        },
        customer: {
          select: {
            id: true,
            fullName: true,
            phone: true,
          },
        },
        rider: {
          include: {
            user: {
              select: {
                fullName: true,
                phone: true,
              },
            },
          },
        },
      },
    });
  }

  /**
   * 2. Accept Incoming Order
   * If prepTimeMinutes is omitted, defaults to vendor.defaultPrepTimeMinutes
   */
  async acceptOrder(user: User, orderId: string, dto: AcceptOrderDto) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { vendor: true },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    await this.validateStaffOutletAccess(user, order.vendorId);

    if (
      order.status !== OrderStatus.PLACED &&
      order.status !== OrderStatus.RIDER_ASSIGNED
    ) {
      throw new BadRequestException(
        `Cannot accept order in status "${order.status}". Order must be PLACED or RIDER_ASSIGNED.`,
      );
    }

    const prepTimeMinutes = dto.prepTimeMinutes ?? order.vendor.defaultPrepTimeMinutes;

    return this.prisma.order.update({
      where: { id: orderId },
      data: {
        status: OrderStatus.PREPARING,
        prepTimeMinutes,
        acceptedAt: new Date(),
      },
      include: {
        orderItems: true,
        vendor: true,
      },
    });
  }

  /**
   * 3. Mark Order Ready for Pickup
   */
  async markOrderReady(user: User, orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    await this.validateStaffOutletAccess(user, order.vendorId);

    if (
      order.status !== OrderStatus.PREPARING &&
      order.status !== OrderStatus.ACCEPTED
    ) {
      throw new BadRequestException(
        `Cannot mark order as ready from status "${order.status}". Must be PREPARING or ACCEPTED.`,
      );
    }

    return this.prisma.order.update({
      where: { id: orderId },
      data: {
        status: OrderStatus.READY_FOR_PICKUP,
      },
    });
  }

  /**
   * 4. Confirm Handover to Rider at Counter
   */
  async handoverOrder(user: User, orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    await this.validateStaffOutletAccess(user, order.vendorId);

    if (order.status !== OrderStatus.READY_FOR_PICKUP) {
      throw new BadRequestException(
        `Cannot handover order from status "${order.status}". Must be READY_FOR_PICKUP.`,
      );
    }

    return this.prisma.order.update({
      where: { id: orderId },
      data: {
        status: OrderStatus.DISPATCHED,
        pickedUpAt: new Date(),
      },
    });
  }

  /**
   * 5. Toggle Product Stock Availability
   */
  async toggleProductStock(user: User, productId: string, isInStock: boolean) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
    });

    if (!product) {
      throw new NotFoundException('Product not found');
    }

    await this.validateStaffOutletAccess(user, product.vendorId);

    return this.prisma.product.update({
      where: { id: productId },
      data: { isInStock },
    });
  }

  /**
   * 6. Toggle Product Variant Stock Availability
   */
  async toggleVariantStock(user: User, variantId: string, isInStock: boolean) {
    const variant = await this.prisma.productVariant.findUnique({
      where: { id: variantId },
      include: { product: true },
    });

    if (!variant) {
      throw new NotFoundException('Product variant not found');
    }

    await this.validateStaffOutletAccess(user, variant.product.vendorId);

    return this.prisma.productVariant.update({
      where: { id: variantId },
      data: { isInStock },
    });
  }
}
