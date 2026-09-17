import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import * as jwt from 'jsonwebtoken';
import { PrismaService } from '../../common/prisma/prisma.service';
import { PermissionScope, UserRole } from '@prisma/client';

@WebSocketGateway({
  namespace: '/events',
  cors: { origin: '*' },
})
export class TrackingGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(TrackingGateway.name);

  constructor(private readonly prisma: PrismaService) {}

  afterInit() {
    this.logger.log('📡 TrackingGateway initialized on namespace /events');
  }

  /**
   * Handshake JWT Authentication & Automatic Room Subscription
   */
  async handleConnection(client: Socket) {
    try {
      const auth = client.handshake.auth;
      const headers = client.handshake.headers;
      let token = auth?.token;

      if (!token && headers.authorization) {
        const parts = headers.authorization.split(' ');
        if (parts.length === 2 && parts[0] === 'Bearer') {
          token = parts[1];
        }
      }

      if (!token) {
        this.logger.warn(`Client ${client.id} connection rejected: missing token`);
        client.emit('error', { message: 'Authentication token required' });
        client.disconnect(true);
        return;
      }

      const secret = process.env.JWT_SECRET || 'deliveryos-jwt-secret-key-32chars-minimum-dev';
      const decoded = jwt.verify(token, secret) as { sub: string; role: string };

      const user = await this.prisma.user.findUnique({
        where: { id: decoded.sub },
        include: {
          vendorStaff: true,
          rider: true,
        },
      });

      if (!user || user.status !== 'ACTIVE') {
        this.logger.warn(`Client ${client.id} rejected: inactive or non-existent user`);
        client.emit('error', { message: 'User inactive or not found' });
        client.disconnect(true);
        return;
      }

      client.data.user = user;

      // -----------------------------------------------------------------------
      // Auto-Join Scoped Rooms per TID-04
      // -----------------------------------------------------------------------
      if (user.role === UserRole.CUSTOMER) {
        const customerRoom = `user_${user.id}`;
        await client.join(customerRoom);
        this.logger.log(`Customer ${user.phone} joined room ${customerRoom}`);
      } else if (user.role === UserRole.VENDOR_ADMIN) {
        for (const staff of user.vendorStaff) {
          if (staff.scope === PermissionScope.PARTICULAR_OUTLET && staff.vendorId) {
            const vendorRoom = `vendor_${staff.vendorId}`;
            await client.join(vendorRoom);
            this.logger.log(`Vendor Staff ${user.phone} joined outlet room ${vendorRoom}`);
          } else if (staff.scope === PermissionScope.ALL_OUTLETS_MASTER && staff.brandId) {
            const brandRoom = `brand_${staff.brandId}`;
            await client.join(brandRoom);
            // Join all branch outlets under this brand
            const brandOutlets = await this.prisma.vendor.findMany({
              where: { brandId: staff.brandId },
              select: { id: true },
            });
            for (const outlet of brandOutlets) {
              await client.join(`vendor_${outlet.id}`);
            }
            this.logger.log(
              `Master Staff ${user.phone} joined brand room ${brandRoom} and ${brandOutlets.length} outlet rooms`,
            );
          }
        }
      } else if (user.role === UserRole.RIDER) {
        const riderId = user.rider?.id || user.id;
        const riderRoom = `rider_${riderId}`;
        await client.join(riderRoom);
        await client.join('riders_pool');
        this.logger.log(`Rider ${user.phone} joined ${riderRoom} and riders_pool`);
      } else if (user.role === UserRole.SUPER_ADMIN) {
        await client.join('admin_hq');
        await client.join('admin_fleet');
        this.logger.log(`Super Admin ${user.phone} joined admin_hq and admin_fleet`);
      }

      client.emit('connected', {
        message: 'Successfully connected and authenticated to DeliveryOS Realtime Gateway',
        userId: user.id,
        role: user.role,
      });
    } catch (err: any) {
      this.logger.warn(`Client ${client.id} authentication failed: ${err.message}`);
      client.emit('error', { message: 'Invalid or expired authentication token' });
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket) {
    const user = client.data?.user;
    this.logger.log(`Client disconnected: ${client.id} (User: ${user?.phone || 'Anonymous'})`);
  }

  // ---------------------------------------------------------------------------
  // Dynamic Order Room Subscriptions
  // ---------------------------------------------------------------------------
  @SubscribeMessage('order:join')
  async handleJoinOrder(client: Socket, payload: { orderId: string }) {
    if (!payload?.orderId) return;
    const room = `order_${payload.orderId}`;
    await client.join(room);
    this.logger.log(`Client ${client.id} joined dynamic order room: ${room}`);
    return { event: 'order:joined', room };
  }

  @SubscribeMessage('order:leave')
  async handleLeaveOrder(client: Socket, payload: { orderId: string }) {
    if (!payload?.orderId) return;
    const room = `order_${payload.orderId}`;
    await client.leave(room);
    this.logger.log(`Client ${client.id} left order room: ${room}`);
    return { event: 'order:left', room };
  }

  @SubscribeMessage('rider:location:update')
  async handleRiderLocationUpdate(
    client: Socket,
    payload: {
      latitude: number;
      longitude: number;
      bearing?: number;
      speed?: number;
      activeOrderId?: string;
    },
  ) {
    const user = client.data?.user;
    if (!user || user.role !== UserRole.RIDER) return;

    if (payload.activeOrderId) {
      this.notifyRiderLocationMoved(payload.activeOrderId, {
        latitude: payload.latitude,
        longitude: payload.longitude,
        bearing: payload.bearing ?? 0,
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Broadcast APIs
  // ---------------------------------------------------------------------------

  /**
   * Event: order:new (Server -> Vendor Console & Admin)
   * Triggers audio alarm on vendor KDS screen
   */
  notifyNewOrder(vendorId: string, orderData: any) {
    const payload = {
      event: 'order:new',
      data: orderData,
    };
    this.server.to(`vendor_${vendorId}`).to('admin_hq').emit('order:new', payload);
    this.logger.log(`Emitted [order:new] for order ${orderData.orderNumber} to room vendor_${vendorId}`);
  }

  /**
   * Event: order:status:changed (Server -> Customer App, Order Room & Admin)
   */
  notifyOrderStatusChanged(
    orderId: string,
    customerId: string,
    previousStatus: string,
    newStatus: string,
    metadata?: Record<string, any>,
  ) {
    const payload = {
      event: 'order:status:changed',
      data: {
        orderId,
        previousStatus,
        newStatus,
        timestamp: new Date().toISOString(),
        ...metadata,
      },
    };
    this.server
      .to(`order_${orderId}`)
      .to(`user_${customerId}`)
      .to('admin_hq')
      .emit('order:status:changed', payload);

    this.logger.log(
      `Emitted [order:status:changed] for order ${orderId}: ${previousStatus} -> ${newStatus}`,
    );
  }

  /**
   * Event: order:rider:moved (Server -> Customer Tracking Screen)
   */
  notifyRiderLocationMoved(
    orderId: string,
    locationData: {
      latitude: number;
      longitude: number;
      bearing: number;
      estimatedMinutesRemaining?: number;
    },
  ) {
    const payload = {
      event: 'order:rider:moved',
      data: {
        orderId,
        riderLocation: {
          latitude: locationData.latitude,
          longitude: locationData.longitude,
          bearing: locationData.bearing,
        },
        estimatedMinutesRemaining: locationData.estimatedMinutesRemaining,
      },
    };
    this.server.to(`order_${orderId}`).emit('order:rider:moved', payload);
  }

  /**
   * Event: dispatch:broadcast (Server -> Online Riders Pool)
   */
  broadcastDispatch(dispatchData: any) {
    const payload = {
      event: 'dispatch:broadcast',
      data: dispatchData,
    };
    this.server.to('riders_pool').emit('dispatch:broadcast', payload);
    this.logger.log(`Emitted [dispatch:broadcast] to riders_pool for order ${dispatchData.orderNumber}`);
  }
}
