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

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env', '../../.env'],
    }),
    PrismaModule,
    RedisModule,
    AuthModule,
    VendorModule,
    PromotionsModule,
    OrderModule,
    VendorStaffModule,
    RiderModule,
    RealtimeModule,
  ],
})
export class AppModule {}
