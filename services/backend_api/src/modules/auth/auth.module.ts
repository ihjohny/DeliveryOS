import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { MockSmsService } from './sms/mock-sms.service';
import { SMS_SERVICE } from './sms/sms.interface';

@Module({
  controllers: [AuthController],
  providers: [
    AuthService,
    {
      provide: SMS_SERVICE,
      useClass: MockSmsService,
    },
  ],
  exports: [AuthService],
})
export class AuthModule {}
