export interface ISmsService {
  sendOtp(phone: string, otp: string): Promise<boolean>;
}

export const SMS_SERVICE = 'SMS_SERVICE';
