import { Module } from '@nestjs/common';
import { CartController, VendorController } from './vendor.controller';
import { VendorService } from './vendor.service';

@Module({
  controllers: [VendorController, CartController],
  providers: [VendorService],
  exports: [VendorService],
})
export class VendorModule {}
