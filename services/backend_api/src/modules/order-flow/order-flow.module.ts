import { Global, Module } from '@nestjs/common';
import { OrderFlowService } from './order-flow.service';
import { OrderFlowController } from './order-flow.controller';

@Global()
@Module({
  controllers: [OrderFlowController],
  providers: [OrderFlowService],
  exports: [OrderFlowService],
})
export class OrderFlowModule {}
