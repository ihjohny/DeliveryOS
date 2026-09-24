import { Injectable, Logger } from '@nestjs/common';
import { RedisService } from '../../common/redis/redis.service';

export interface ReverseGeocodeResult {
  displayName: string;
  addressLine: string;
  city?: string;
  postcode?: string;
  country?: string;
}

@Injectable()
export class GeoService {
  private readonly logger = new Logger(GeoService.name);

  constructor(private readonly redis: RedisService) {}

  async reverseGeocode(lat: number, lng: number): Promise<ReverseGeocodeResult> {
    // Round to 4 decimal places (~11m precision) for cache optimization
    const rLat = lat.toFixed(4);
    const rLng = lng.toFixed(4);
    const cacheKey = `geo:reverse:${rLat}:${rLng}`;

    const cached = await this.redis.get(cacheKey);
    if (cached) {
      try {
        return JSON.parse(cached);
      } catch {
        // Continue to fresh fetch on parse error
      }
    }

    try {
      const url = `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${lat}&lon=${lng}`;
      const response = await fetch(url, {
        headers: {
          'User-Agent': 'DeliveryOS/1.0 (engineering@deliveryos.internal)',
          'Accept-Language': 'en',
        },
      });

      if (response.ok) {
        const data = await response.json();
        const address = data.address || {};
        const road = address.road || address.pedestrian || address.suburb || address.neighbourhood || '';
        const houseNumber = address.house_number ? `${address.house_number}, ` : '';
        const area = address.suburb || address.neighbourhood || address.residential || '';
        const city = address.city || address.town || address.county || 'Dhaka';

        const addressLine = road
          ? `${houseNumber}${road}, ${area}`.replace(/^, |, $/g, '').trim()
          : data.display_name?.split(',').slice(0, 2).join(',') || 'Current Location';

        const result: ReverseGeocodeResult = {
          displayName: data.display_name || addressLine,
          addressLine: addressLine || 'Selected Location',
          city,
          postcode: address.postcode,
          country: address.country,
        };

        // Cache in Redis for 24 hours (86400s)
        await this.redis.set(cacheKey, JSON.stringify(result), 86400);
        return result;
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      this.logger.warn(`Reverse geocode failed for ${lat},${lng}: ${msg}`);
    }

    // Graceful fallback to formatted coordinates if external lookup fails
    return {
      displayName: `Location (${lat.toFixed(4)}, ${lng.toFixed(4)})`,
      addressLine: `GPS Location (${lat.toFixed(4)}, ${lng.toFixed(4)})`,
      city: 'Dhaka',
    };
  }
}
