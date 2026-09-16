import { Injectable, Logger } from '@nestjs/common';
import { ISmsService } from './sms.interface';

@Injectable()
export class MockSmsService implements ISmsService {
  private readonly logger = new Logger(MockSmsService.name);

  async sendOtp(phone: string, otp: string): Promise<boolean> {
    this.logger.log(`📱 [MOCK SMS] Outgoing OTP to ${phone}: ${otp}`);
    return true;
  }
}
