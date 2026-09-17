import {
  BadRequestException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { CouponService } from '../promotions/coupons/coupon.service';
import { DeliveryFeeService } from '../promotions/pricing/delivery-fee.service';
import { CheckoutDto, DeliveryMethod } from './dto/checkout.dto';
import { ValidateReorderDto } from './dto/validate-reorder.dto';
import { OrderStatus, PaymentStatus, SettlementStatus, UserRole } from '@prisma/client';

import { TrackingGateway } from '../realtime/tracking.gateway';
import { OrderFlowService } from '../order-flow/order-flow.service';
import { RedisService } from '../../common/redis/redis.service';

@Injectable()
export class OrderService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly couponService: CouponService,
    private readonly deliveryFeeService: DeliveryFeeService,
    private readonly trackingGateway: TrackingGateway,
    private readonly orderFlowService: OrderFlowService,
    private readonly redis: RedisService,
  ) {}

  /**
   * 1. Atomic Order Checkout with Geofence & Single-Vendor Guard
   */
  async checkout(customerId: string, dto: CheckoutDto) {
    // 1. Fetch customer
    const customer = await this.prisma.user.findUnique({
      where: { id: customerId },
    });
    if (!customer || customer.status !== 'ACTIVE') {
      throw new ForbiddenException('Customer account is not active');
    }

    // 2. Fetch vendor outlet
    const vendor = await this.prisma.vendor.findUnique({
      where: { id: dto.vendorId },
    });
    if (!vendor || !vendor.isActive) {
      throw new NotFoundException('Vendor outlet not found or currently closed');
    }

    // 3. Validate Delivery Address & Spatial Geofence Guard
    let distanceKm = 0;
    let addressSnapshot: any = {
      type: 'TAKEAWAY',
      vendorAddress: vendor.addressText,
    };

    if (dto.deliveryMethod === DeliveryMethod.HOME_DELIVERY) {
      if (!dto.deliveryAddressId) {
        throw new BadRequestException('deliveryAddressId is required for Home Delivery');
      }

      const address = await this.prisma.customerAddress.findUnique({
        where: { id: dto.deliveryAddressId },
      });

      if (!address || address.userId !== customerId) {
        throw new NotFoundException('Delivery address not found or does not belong to customer');
      }

      // Check Spatial Coverage via PostGIS
      const coverageQuery: any[] = await this.prisma.$queryRaw`
        SELECT 
          ROUND((ST_Distance(
            CAST(ST_SetSRID(ST_MakePoint(${vendor.longitude}, ${vendor.latitude}), 4326) AS geography),
            CAST(ST_SetSRID(ST_MakePoint(${address.longitude}, ${address.latitude}), 4326) AS geography)
          ) / 1000)::numeric, 2) AS "distanceKm",
          ST_DWithin(
            CAST(ST_SetSRID(ST_MakePoint(${vendor.longitude}, ${vendor.latitude}), 4326) AS geography),
            CAST(ST_SetSRID(ST_MakePoint(${address.longitude}, ${address.latitude}), 4326) AS geography),
            ${Number(vendor.deliveryRadiusKm)} * 1000
          ) AS "isWithinCoverage"
      `;

      const isWithinCoverage = coverageQuery[0]?.isWithinCoverage === true;
      distanceKm = Number(coverageQuery[0]?.distanceKm || 0);

      if (!isWithinCoverage) {
        throw new HttpException(
          {
            success: false,
            statusCode: HttpStatus.UNPROCESSABLE_ENTITY,
            error: 'ADDRESS_OUT_OF_COVERAGE',
            message: `Selected address is outside ${vendor.name}'s delivery coverage radius of ${vendor.deliveryRadiusKm} km. Distance is ${distanceKm} km.`,
          },
          HttpStatus.UNPROCESSABLE_ENTITY,
        );
      }

      addressSnapshot = {
        type: 'HOME_DELIVERY',
        addressId: address.id,
        label: address.label,
        addressLine: address.addressLine,
        buildingFloor: address.buildingFloor,
        deliveryNote: address.deliveryNote,
        latitude: address.latitude,
        longitude: address.longitude,
      };
    }

    // 4. Validate Products & Single-Vendor Guard
    const productIds = dto.items.map((i) => i.productId);
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } },
      include: {
        variants: true,
        addonGroups: {
          include: { addons: true },
        },
      },
    });

    if (products.length !== productIds.length) {
      throw new BadRequestException('One or more products in the cart were not found');
    }

    // Single-Vendor Check
    for (const product of products) {
      if (product.vendorId !== dto.vendorId) {
        throw new BadRequestException('All items in the cart must belong to the same vendor outlet.');
      }
      if (!product.isInStock) {
        throw new BadRequestException(`Product "${product.name}" is currently sold out.`);
      }
    }

    // Calculate Items and Freeze Snapshots
    let grossSubtotal = 0;
    const itemsToCreate: any[] = [];

    for (const itemDto of dto.items) {
      const product = products.find((p) => p.id === itemDto.productId)!;
      let unitPrice = Number(product.basePrice);

      let variantSnapshot: any = null;
      if (itemDto.variantId) {
        const variant = product.variants.find((v) => v.id === itemDto.variantId);
        if (!variant) {
          throw new BadRequestException(`Variant not found for product "${product.name}"`);
        }
        if (!variant.isInStock) {
          throw new BadRequestException(`Variant "${variant.name}" for "${product.name}" is currently sold out`);
        }
        unitPrice += Number(variant.priceModifier);
        variantSnapshot = {
          id: variant.id,
          name: variant.name,
          priceModifier: Number(variant.priceModifier),
        };
      }

      const addonsSnapshot: any[] = [];
      if (itemDto.addonIds && itemDto.addonIds.length > 0) {
        const allAddons = product.addonGroups.flatMap((g) => g.addons);
        for (const addonId of itemDto.addonIds) {
          const addon = allAddons.find((a) => a.id === addonId);
          if (!addon) {
            throw new BadRequestException(`Addon not found for product "${product.name}"`);
          }
          if (!addon.isInStock) {
            throw new BadRequestException(`Addon "${addon.name}" is currently sold out`);
          }
          unitPrice += Number(addon.price);
          addonsSnapshot.push({
            id: addon.id,
            name: addon.name,
            price: Number(addon.price),
          });
        }
      }

      const itemTotal = unitPrice * itemDto.quantity;
      grossSubtotal += itemTotal;

      itemsToCreate.push({
        productId: product.id,
        productNameSnapshot: product.name,
        unitPrice,
        quantity: itemDto.quantity,
        totalPrice: itemTotal,
        variantSnapshot,
        addonsSnapshot: addonsSnapshot.length > 0 ? addonsSnapshot : null,
      });
    }

    grossSubtotal = Math.round(grossSubtotal * 100) / 100;

    // 5. Calculate Delivery Fee
    let deliveryFee = 0.0;
    if (dto.deliveryMethod === DeliveryMethod.HOME_DELIVERY) {
      const feeCalc = await this.deliveryFeeService.calculateFee(distanceKm);
      deliveryFee = feeCalc.deliveryFee;
    }

    // 6. Validate & Apply Coupon
    let couponDiscount = 0.0;
    let appliedCouponId: string | null = null;

    if (dto.couponCode) {
      const couponValidation = await this.couponService.validateCoupon({
        code: dto.couponCode,
        cartSubtotal: grossSubtotal,
        vendorId: vendor.id,
      });
      couponDiscount = couponValidation.discountAmount;
      appliedCouponId = couponValidation.couponId;
    }

    // 7. Calculate Financial Balance & Platform Commission
    const netSubtotal = Math.max(0, Math.round((grossSubtotal - couponDiscount) * 100) / 100);
    const taxAmount = 0.0;
    const totalAmount = Math.round((netSubtotal + deliveryFee + taxAmount) * 100) / 100;

    const commissionRate = Number(vendor.commissionRate);
    const commissionAmount = Math.round((netSubtotal * (commissionRate / 100)) * 100) / 100;
    const netVendorPayable = Math.round((netSubtotal - commissionAmount) * 100) / 100;

    // 8. Generate Order Number: ORD-YYYYMMDD-XXXX
    const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const randSuffix = Math.floor(1000 + Math.random() * 9000).toString();
    const orderNumber = `ORD-${dateStr}-${randSuffix}`;

    // 9. Execute Atomic ACID Transaction
    const order = await this.prisma.$transaction(async (tx) => {
      // Create Order
      const newOrder = await tx.order.create({
        data: {
          orderNumber,
          customerId,
          vendorId: vendor.id,
          couponId: appliedCouponId,
          status: OrderStatus.PLACED,
          subtotal: grossSubtotal,
          couponDiscount,
          deliveryFee,
          taxAmount,
          totalAmount,
          paymentMethod: dto.paymentMethod || 'CASH_ON_DELIVERY',
          paymentStatus: PaymentStatus.PENDING,
          deliveryAddressSnapshot: addressSnapshot,
          customerPhoneSnapshot: customer.phone,
          prepTimeMinutes: vendor.defaultPrepTimeMinutes,
          customerNotes: dto.customerNotes,
        },
      });

      // Create Order Items
      for (const item of itemsToCreate) {
        await tx.orderItem.create({
          data: {
            orderId: newOrder.id,
            productId: item.productId,
            productNameSnapshot: item.productNameSnapshot,
            unitPrice: item.unitPrice,
            quantity: item.quantity,
            totalPrice: item.totalPrice,
            variantSnapshot: item.variantSnapshot,
            addonsSnapshot: item.addonsSnapshot,
          },
        });
      }

      // Create Commission Ledger
      await tx.commissionLedger.create({
        data: {
          orderId: newOrder.id,
          vendorId: vendor.id,
          grossAmount: netSubtotal,
          commissionRate,
          commissionAmount,
          netVendorPayable,
          settlementStatus: SettlementStatus.PENDING,
        },
      });

      // Increment Coupon Usage if applied
      if (appliedCouponId) {
        await tx.coupon.update({
          where: { id: appliedCouponId },
          data: { currentUses: { increment: 1 } },
        });
      }

      return newOrder;
    });

    // Trigger Dispatch FSM based on active mode (RIDER_FIRST vs VENDOR_FIRST)
    await this.orderFlowService.handleOrderPlaced(order.id);

    return {
      orderId: order.id,
      orderNumber: order.orderNumber,
      subtotal: Number(order.subtotal),
      couponDiscount: Number(order.couponDiscount),
      deliveryFee: Number(order.deliveryFee),
      totalAmount: Number(order.totalAmount),
      status: order.status,
      paymentMethod: order.paymentMethod,
      commissionAmount,
      netVendorPayable,
    };
  }

  /**
   * 2. Validate Re-Order from History
   */
  async validateReorder(customerId: string, dto: ValidateReorderDto) {
    const previousOrder = await this.prisma.order.findUnique({
      where: { id: dto.previousOrderId },
      include: {
        vendor: true,
        orderItems: true,
      },
    });

    if (!previousOrder) {
      throw new NotFoundException('Previous order record not found');
    }

    const vendor = previousOrder.vendor;
    const isStoreOperational = vendor.isActive && !vendor.isBusy;

    const validItems: any[] = [];
    const unavailableItems: any[] = [];

    for (const item of previousOrder.orderItems) {
      const product = await this.prisma.product.findUnique({
        where: { id: item.productId },
        include: { variants: true, addonGroups: { include: { addons: true } } },
      });

      if (!product || !product.isInStock) {
        unavailableItems.push({
          productId: item.productId,
          name: item.productNameSnapshot,
          reason: 'Item is currently sold out',
        });
        continue;
      }

      // Check variant if applicable
      let variantOk = true;
      const variantSnap = item.variantSnapshot as any;
      if (variantSnap?.id) {
        const variant = product.variants.find((v) => v.id === variantSnap.id);
        if (!variant || !variant.isInStock) {
          variantOk = false;
        }
      }

      if (!variantOk) {
        unavailableItems.push({
          productId: item.productId,
          name: item.productNameSnapshot,
          reason: 'Selected variant is currently sold out',
        });
        continue;
      }

      validItems.push({
        productId: product.id,
        name: product.name,
        currentBasePrice: Number(product.basePrice),
        quantity: item.quantity,
        variantId: variantSnap?.id || null,
        isAvailable: true,
      });
    }

    const hasStockChanges = unavailableItems.length > 0;

    return {
      isStoreOperational,
      hasStockChanges,
      vendorId: vendor.id,
      vendorName: vendor.name,
      validItems,
      unavailableItems,
    };
  }

  /**
   * 3. Get Order Details by ID
   */
  async getOrderById(orderId: string, userId: string, role: UserRole) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        vendor: {
          select: {
            id: true,
            name: true,
            contactPhone: true,
            logoUrl: true,
            addressText: true,
            latitude: true,
            longitude: true,
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
        orderItems: true,
        commission: true,
      },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    // Permission check: Customers can only view their own orders
    if (role === UserRole.CUSTOMER && order.customerId !== userId) {
      throw new ForbiddenException('You do not have permission to view this order');
    }

    return order;
  }

  /**
   * 4. Customer Order History
   */
  async getCustomerOrderHistory(customerId: string) {
    return this.prisma.order.findMany({
      where: { customerId },
      orderBy: { placedAt: 'desc' },
      include: {
        vendor: {
          select: {
            id: true,
            name: true,
            logoUrl: true,
          },
        },
        orderItems: true,
      },
    });
  }

  /**
   * 5. Live Tracking Fallback Polling Endpoint
   * Returns store coordinates, destination, latest rider telemetry, and route snapshot.
   */
  async getLiveTracking(orderId: string, userId: string, role: UserRole) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        vendor: true,
        rider: {
          include: {
            user: { select: { fullName: true, phone: true } },
          },
        },
      },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    if (role === UserRole.CUSTOMER && order.customerId !== userId) {
      throw new ForbiddenException('You do not have permission to view live tracking for this order');
    }

    const destSnap = order.deliveryAddressSnapshot as any;
    const storeLocation = {
      id: order.vendor.id,
      name: order.vendor.name,
      address: order.vendor.addressText,
      latitude: order.vendor.latitude,
      longitude: order.vendor.longitude,
    };

    const destinationLocation = {
      label: destSnap?.label || 'Home',
      addressLine: destSnap?.addressLine || '',
      latitude: destSnap?.latitude,
      longitude: destSnap?.longitude,
    };

    // Retrieve latest rider telemetry: 1st from Redis live order, 2nd from Redis telemetry, 3rd from DB
    let riderLocation: any = null;
    let estimatedMinutesRemaining = 10;

    const liveLocRaw = await this.redis.get(`order:live_location:${orderId}`);
    if (liveLocRaw) {
      try {
        const live = JSON.parse(liveLocRaw);
        riderLocation = {
          riderId: live.riderId,
          fullName: live.fullName || order.rider?.user?.fullName,
          phone: live.phone || order.rider?.user?.phone,
          latitude: live.latitude,
          longitude: live.longitude,
          bearing: live.bearing ?? 0,
          speed: live.speed ?? 0,
          updatedAt: live.updatedAt,
        };
        estimatedMinutesRemaining = live.estimatedMinutesRemaining ?? 10;
      } catch {}
    }

    if (!riderLocation && order.rider) {
      const telemetryRaw = await this.redis.get(`rider:telemetry:${order.rider.id}`);
      if (telemetryRaw) {
        try {
          const telem = JSON.parse(telemetryRaw);
          riderLocation = {
            riderId: order.rider.id,
            fullName: order.rider.user.fullName,
            phone: order.rider.user.phone,
            latitude: telem.latitude,
            longitude: telem.longitude,
            bearing: telem.bearing ?? 0,
            speed: telem.speed ?? 0,
            updatedAt: telem.updatedAt,
          };
        } catch {}
      }

      if (!riderLocation && order.rider.latitude && order.rider.longitude) {
        riderLocation = {
          riderId: order.rider.id,
          fullName: order.rider.user.fullName,
          phone: order.rider.user.phone,
          latitude: order.rider.latitude,
          longitude: order.rider.longitude,
          bearing: 0,
          speed: 0,
          updatedAt: order.rider.updatedAt.toISOString(),
        };
      }
    }

    const routeSnapshot = {
      origin: {
        latitude: storeLocation.latitude,
        longitude: storeLocation.longitude,
      },
      rider: riderLocation
        ? { latitude: riderLocation.latitude, longitude: riderLocation.longitude }
        : null,
      destination: {
        latitude: destinationLocation.latitude,
        longitude: destinationLocation.longitude,
      },
    };

    return {
      orderId: order.id,
      orderNumber: order.orderNumber,
      status: order.status,
      storeLocation,
      destinationLocation,
      riderLocation,
      estimatedMinutesRemaining,
      routeSnapshot,
      placedAt: order.placedAt,
      acceptedAt: order.acceptedAt,
      pickedUpAt: order.pickedUpAt,
      deliveredAt: order.deliveredAt,
    };
  }
}
