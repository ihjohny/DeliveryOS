import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './common/prisma/prisma.module';
import { RedisModule } from './common/redis/redis.module';
import { AuthModule } from './modules/auth/auth.module';
import { VendorModule } from './modules/vendors/vendor.module';
import { PromotionsModule } from './modules/promotions/promotions.module';
import { OrderModule } from './modules/orders/order.module';
import { VendorStaffModule } from './modules/vendor-staff/vendor-staff.module';
import { RiderModule } from './modules/riders/rider.module';
import { RealtimeModule } from './modules/realtime/realtime.module';
import { OrderFlowModule } from './modules/order-flow/order-flow.module';
import { AdminModule } from './modules/admin/admin.module';
import { HealthModule } from './modules/health/health.module';
import { GeoModule } from './modules/geo/geo.module';
import { NotificationsModule } from './modules/notifications/notifications.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env', '../../.env'],
    }),
    PrismaModule,
    RedisModule,
    HealthModule,
    AuthModule,
    VendorModule,
    PromotionsModule,
    OrderModule,
    VendorStaffModule,
    RiderModule,
    RealtimeModule,
    OrderFlowModule,
    AdminModule,
    GeoModule,
    NotificationsModule,
  ],
})
export class AppModule {}
