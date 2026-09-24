import { Module } from '@nestjs/common';
import { VendorStaffController } from './vendor-staff.controller';
import { VendorStaffService } from './vendor-staff.service';
import { OrderModule } from '../orders/order.module';

@Module({
  imports: [OrderModule],
  controllers: [VendorStaffController],
  providers: [VendorStaffService],
  exports: [VendorStaffService],
})
export class VendorStaffModule {}
