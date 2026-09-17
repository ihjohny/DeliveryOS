import { Global, Module } from '@nestjs/common';
import { TrackingGateway } from './tracking.gateway';

@Global()
@Module({
  providers: [TrackingGateway],
  exports: [TrackingGateway],
})
export class RealtimeModule {}
