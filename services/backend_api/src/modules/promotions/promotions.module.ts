import { Global, Module } from '@nestjs/common';
import { BannerController } from './banners/banner.controller';
import { BannerService } from './banners/banner.service';
import { CouponController } from './coupons/coupon.controller';
import { CouponService } from './coupons/coupon.service';
import { DeliveryFeeService } from './pricing/delivery-fee.service';

@Global()
@Module({
  controllers: [BannerController, CouponController],
  providers: [BannerService, CouponService, DeliveryFeeService],
  exports: [BannerService, CouponService, DeliveryFeeService],
})
export class PromotionsModule {}
