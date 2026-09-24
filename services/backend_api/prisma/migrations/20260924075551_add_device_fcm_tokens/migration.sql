-- AlterTable
ALTER TABLE "users" ADD COLUMN     "device_platform" VARCHAR(20),
ADD COLUMN     "fcm_token" TEXT;
