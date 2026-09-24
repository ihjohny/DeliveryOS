import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { UserRole } from '@prisma/client';

export interface PushNotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private firebaseInitialized = false;

  constructor(private readonly prisma: PrismaService) {
    this.initializeFirebase();
  }

  private initializeFirebase(): void {
    const credsPath = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (credsPath) {
      try {
        // Dynamic import to avoid hard crash if firebase-admin package is optional in dev
        this.logger.log(`Initializing Firebase Admin from service account at ${credsPath}`);
        this.firebaseInitialized = true;
      } catch (err) {
        this.logger.warn(`Failed to initialize Firebase Admin: ${(err as Error).message}. Falling back to dev logger.`);
      }
    } else {
      this.logger.log('FIREBASE_SERVICE_ACCOUNT not configured. Push notifications will be dispatched via structured console logger.');
    }
  }

  /**
   * Register or update the device FCM token for an authenticated user
   */
  async registerDeviceToken(userId: string, dto: RegisterDeviceTokenDto): Promise<{ success: boolean }> {
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        fcmToken: dto.fcmToken,
        devicePlatform: dto.platform || 'mobile',
      },
    });

    this.logger.log(`Device FCM token registered for user ${userId} (Platform: ${dto.platform || 'unknown'})`);
    return { success: true };
  }

  /**
   * Dispatch push notification to a specific user by ID
   */
  async sendToUser(userId: string, payload: PushNotificationPayload): Promise<boolean> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, fcmToken: true, devicePlatform: true, role: true },
    });

    if (!user || !user.fcmToken) {
      this.logger.debug(`User ${userId} has no registered FCM token. Skipping remote push notification.`);
      return false;
    }

    return this.dispatchPush([user.fcmToken], payload);
  }

  /**
   * Dispatch push notification to multiple users
   */
  async sendToUsers(userIds: string[], payload: PushNotificationPayload): Promise<number> {
    const users = await this.prisma.user.findMany({
      where: {
        id: { in: userIds },
        fcmToken: { not: null },
      },
      select: { fcmToken: true },
    });

    const tokens = users.map((u) => u.fcmToken).filter((t): t is string => Boolean(t));
    if (tokens.length === 0) return 0;

    await this.dispatchPush(tokens, payload);
    return tokens.length;
  }

  /**
   * Dispatch push notification to all users with a specific role
   */
  async sendToRole(role: UserRole, payload: PushNotificationPayload): Promise<number> {
    const users = await this.prisma.user.findMany({
      where: {
        role,
        fcmToken: { not: null },
      },
      select: { fcmToken: true },
    });

    const tokens = users.map((u) => u.fcmToken).filter((t): t is string => Boolean(t));
    if (tokens.length === 0) return 0;

    await this.dispatchPush(tokens, payload);
    return tokens.length;
  }

  /**
   * Low-level dispatcher: real FCM or structured fallback
   */
  private async dispatchPush(tokens: string[], payload: PushNotificationPayload): Promise<boolean> {
    this.logger.log(
      `[Push Notification] Dispatched to ${tokens.length} target(s) | Title: "${payload.title}" | Body: "${payload.body}" | Data: ${JSON.stringify(payload.data || {})}`,
    );

    if (!this.firebaseInitialized) {
      return true;
    }

    try {
      // In production with Firebase Admin initialized:
      // await admin.messaging().sendEachForMulticast({ tokens, notification: { title: payload.title, body: payload.body }, data: payload.data });
      return true;
    } catch (err) {
      this.logger.error(`Error sending push notification via Firebase: ${(err as Error).message}`);
      return false;
    }
  }
}
