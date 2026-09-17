import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { BannerService } from './banner.service';

@ApiTags('Promotional Banners')
@Controller('banners')
export class BannerController {
  constructor(private readonly bannerService: BannerService) {}

  @Get('active')
  @ApiOperation({ summary: 'Get active promotional banners for the Customer Home screen' })
  @ApiResponse({ status: 200, description: 'List of active promotional banners' })
  async getActiveBanners() {
    const banners = await this.bannerService.getActiveBanners();
    return {
      message: `Retrieved ${banners.length} active promotional banners`,
      data: banners,
    };
  }
}
