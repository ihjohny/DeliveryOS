import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User, UserRole } from '@prisma/client';
import { RiderService } from './rider.service';
import { ToggleDutyDto } from './dto/toggle-duty.dto';
import { DeliverOrderDto } from './dto/deliver-order.dto';

@ApiTags('Rider Operations')
@Controller('rider')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.RIDER)
@ApiBearerAuth()
export class RiderController {
  constructor(private readonly riderService: RiderService) {}

  @Get('profile')
  @ApiOperation({ summary: 'Get current rider duty status, wallet, and profile' })
  @ApiResponse({ status: 200, description: 'Rider profile data' })
  async getProfile(@CurrentUser() user: User) {
    const rider = await this.riderService.getRiderProfile(user.id);
    return {
      message: 'Rider profile retrieved',
      data: rider,
    };
  }

  @Patch('duty')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Toggle rider online/offline duty status' })
  @ApiResponse({ status: 200, description: 'Duty status updated' })
  async toggleDuty(
    @CurrentUser() user: User,
    @Body() dto: ToggleDutyDto,
  ) {
    const rider = await this.riderService.toggleDuty(user.id, dto.isOnline);
    return {
      message: `Rider is now ${rider.isOnline ? 'ONLINE' : 'OFFLINE'}`,
      data: rider,
    };
  }

  @Post('orders/:id/claim')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Atomically claim broadcasted order protected by Redis distributed lock' })
  @ApiResponse({ status: 200, description: 'Order successfully claimed by rider' })
  @ApiResponse({ status: 409, description: 'Conflict if order already claimed or lock held' })
  async claimOrder(
    @CurrentUser() user: User,
    @Param('id') orderId: string,
  ) {
    const order = await this.riderService.claimOrder(user.id, orderId);
    return {
      message: 'Order claimed successfully',
      data: order,
    };
  }

  @Patch('orders/:id/pickup')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Confirm order pickup from store counter' })
  @ApiResponse({ status: 200, description: 'Order marked as DISPATCHED' })
  async pickupOrder(
    @CurrentUser() user: User,
    @Param('id') orderId: string,
  ) {
    const order = await this.riderService.pickupOrder(user.id, orderId);
    return {
      message: 'Order picked up and dispatched for delivery',
      data: order,
    };
  }

  @Patch('orders/:id/deliver')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Confirm delivery to customer and record COD cash collected' })
  @ApiResponse({ status: 200, description: 'Order delivered and trip ledger created' })
  async deliverOrder(
    @CurrentUser() user: User,
    @Param('id') orderId: string,
    @Body() dto: DeliverOrderDto,
  ) {
    const result = await this.riderService.deliverOrder(user.id, orderId, dto);
    return {
      message: 'Order delivered successfully',
      data: result,
    };
  }
}
