import { Module } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { PaymentsController } from './payments.controller';
import { BkashGatewayAdapter } from './gateways/bkash.gateway';
import { SslCommerzGatewayAdapter } from './gateways/sslcommerz.gateway';
import { SandboxGatewayAdapter } from './gateways/sandbox.gateway';
import { OrderFlowModule } from '../order-flow/order-flow.module';

@Module({
  imports: [OrderFlowModule],
  controllers: [PaymentsController],
  providers: [
    PaymentsService,
    BkashGatewayAdapter,
    SslCommerzGatewayAdapter,
    SandboxGatewayAdapter,
  ],
  exports: [PaymentsService],
})
export class PaymentsModule {}
