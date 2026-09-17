import { Body, Controller, Get, HttpCode, HttpStatus, Patch, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '@prisma/client';
import { OrderFlowService } from './order-flow.service';
import { UpdateOrderFlowDto } from './dto/update-order-flow.dto';

@ApiTags('Admin Dispatch Governance')
@Controller('admin/settings/order-flow')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SUPER_ADMIN)
@ApiBearerAuth()
export class OrderFlowController {
  constructor(private readonly orderFlowService: OrderFlowService) {}

  @Get()
  @ApiOperation({ summary: 'Get active order flow dispatch configuration (RIDER_FIRST vs VENDOR_FIRST)' })
  @ApiResponse({ status: 200, description: 'Active dispatch settings' })
  async getOrderFlowConfig() {
    const config = await this.orderFlowService.getOrderFlowConfig();
    return {
      message: 'Order flow configuration retrieved',
      data: config,
    };
  }

  @Patch()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Dynamically toggle between RIDER_FIRST and VENDOR_FIRST dispatch modes' })
  @ApiResponse({ status: 200, description: 'Dispatch mode updated successfully' })
  async setOrderFlowConfig(@Body() dto: UpdateOrderFlowDto) {
    const updated = await this.orderFlowService.setOrderFlowConfig(dto);
    return {
      message: `Order flow sequence updated to ${dto.mode}`,
      data: updated,
    };
  }
}
