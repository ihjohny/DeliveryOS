import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';

export interface DeliveryFeeConfig {
  mode: 'FIXED_FLAT' | 'DISTANCE_TIERED';
  flat_rate: number;
  base_fee: number;
  base_km: number;
  per_km_rate: number;
}

@Injectable()
export class DeliveryFeeService {
  private readonly logger = new Logger(DeliveryFeeService.name);

  private readonly defaultConfig: DeliveryFeeConfig = {
    mode: 'FIXED_FLAT',
    flat_rate: 50.0,
    base_fee: 30.0,
    base_km: 2.0,
    per_km_rate: 10.0,
  };

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Fetches the active delivery fee configuration from system_settings
   */
  async getConfig(): Promise<DeliveryFeeConfig> {
    try {
      const setting = await this.prisma.systemSetting.findUnique({
        where: { key: 'delivery_fee_config' },
      });
      if (setting && setting.value) {
        return setting.value as unknown as DeliveryFeeConfig;
      }
    } catch (err) {
      this.logger.warn(`Could not load delivery_fee_config from database, using defaults: ${err.message}`);
    }
    return this.defaultConfig;
  }

  /**
   * Calculates delivery fee based on active system setting and distance in km
   */
  async calculateFee(distanceKm: number): Promise<{
    deliveryFee: number;
    mode: 'FIXED_FLAT' | 'DISTANCE_TIERED';
    distanceKm: number;
  }> {
    const config = await this.getConfig();

    if (config.mode === 'FIXED_FLAT') {
      return {
        deliveryFee: Number(config.flat_rate),
        mode: 'FIXED_FLAT',
        distanceKm,
      };
    }

    // DISTANCE_TIERED mode
    const baseKm = Number(config.base_km) || 2.0;
    const baseFee = Number(config.base_fee) || 30.0;
    const perKmRate = Number(config.per_km_rate) || 10.0;

    let fee = baseFee;
    if (distanceKm > baseKm) {
      const extraKm = distanceKm - baseKm;
      fee += extraKm * perKmRate;
    }

    const roundedFee = Math.round(fee * 100) / 100;
    return {
      deliveryFee: roundedFee,
      mode: 'DISTANCE_TIERED',
      distanceKm,
    };
  }
}
