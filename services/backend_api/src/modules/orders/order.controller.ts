import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '@prisma/client';
import { OrderService } from './order.service';
import { CheckoutDto } from './dto/checkout.dto';
import { ValidateReorderDto } from './dto/validate-reorder.dto';

@ApiTags('Orders & Ledger')
@Controller('orders')
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

  @Post('checkout')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Place an order with atomic ACID guarantees and geofence verification' })
  @ApiResponse({ status: 201, description: 'Order successfully placed with ledger created' })
  @ApiResponse({ status: 400, description: 'Single-vendor violation or invalid items' })
  @ApiResponse({ status: 422, description: 'Address outside vendor coverage' })
  async checkout(@CurrentUser() user: User, @Body() dto: CheckoutDto) {
    const result = await this.orderService.checkout(user.id, dto);
    return {
      message: 'Order placed successfully',
      data: result,
    };
  }

  @Post('validate-reorder')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Validate stock and pricing to re-order previous items' })
  @ApiResponse({ status: 200, description: 'Re-order validation result' })
  async validateReorder(@CurrentUser() user: User, @Body() dto: ValidateReorderDto) {
    const result = await this.orderService.validateReorder(user.id, dto);
    return {
      message: 'Re-order validation completed',
      data: result,
    };
  }

  @Get('history')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get order history for authenticated customer' })
  @ApiResponse({ status: 200, description: 'List of previous orders' })
  async getOrderHistory(@CurrentUser() user: User) {
    const orders = await this.orderService.getCustomerOrderHistory(user.id);
    return {
      message: 'Order history retrieved successfully',
      data: orders,
    };
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get detailed order tracking and items by order ID' })
  @ApiResponse({ status: 200, description: 'Order details' })
  @ApiResponse({ status: 403, description: 'Forbidden if not order owner or staff' })
  @ApiResponse({ status: 404, description: 'Order not found' })
  async getOrderById(@Param('id') id: string, @CurrentUser() user: User) {
    const order = await this.orderService.getOrderById(id, user.id, user.role);
    return {
      message: 'Order details retrieved successfully',
      data: order,
    };
  }
}
