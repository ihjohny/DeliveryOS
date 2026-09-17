import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User, UserRole } from '@prisma/client';
import { VendorStaffService } from './vendor-staff.service';
import { AcceptOrderDto } from './dto/accept-order.dto';
import { ToggleStockDto } from './dto/toggle-stock.dto';

@ApiTags('Vendor Kitchen Operations')
@Controller('vendor')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.VENDOR_ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth()
export class VendorStaffController {
  constructor(private readonly vendorStaffService: VendorStaffService) {}

  @Get('me')
  @ApiOperation({ summary: 'Get current vendor staff profile and assigned outlet info' })
  @ApiResponse({ status: 200, description: 'Vendor staff profile' })
  async getProfile(@CurrentUser() user: User) {
    const profile = await this.vendorStaffService.getStaffProfile(user);
    return {
      message: 'Vendor staff profile retrieved',
      data: profile,
    };
  }

  @Get('outlets')
  @ApiOperation({ summary: 'Get accessible outlets based on staff scope (Particular vs Brand Owner)' })
  @ApiResponse({ status: 200, description: 'List of accessible vendor outlets' })
  async getOutlets(@CurrentUser() user: User) {
    const outlets = await this.vendorStaffService.getAccessibleOutlets(user);
    return {
      message: `Retrieved ${outlets.length} accessible outlets`,
      data: outlets,
    };
  }

  @Get('settings')
  @ApiOperation({ summary: 'Get outlet settings, preparation time, and operating schedule' })
  @ApiResponse({ status: 200, description: 'Outlet settings and schedule' })
  async getSettings(
    @CurrentUser() user: User,
    @Query('vendorId') vendorId?: string,
  ) {
    const settings = await this.vendorStaffService.getOutletSettings(user, vendorId);
    return {
      message: 'Outlet settings retrieved successfully',
      data: settings,
    };
  }

  @Patch('settings')
  @ApiOperation({ summary: 'Update outlet settings, default prep time, or emergency rush pause' })
  @ApiResponse({ status: 200, description: 'Outlet settings updated' })
  async updateSettings(
    @CurrentUser() user: User,
    @Query('vendorId') queryVendorId: string,
    @Body()
    dto: {
      vendorId?: string;
      defaultPrepTimeMinutes?: number;
      isBusy?: boolean;
      busyReason?: string;
      isActive?: boolean;
    },
  ) {
    const targetVendorId = queryVendorId || dto.vendorId;
    const updated = await this.vendorStaffService.updateOutletSettings(user, targetVendorId, dto);
    return {
      message: 'Outlet settings updated successfully',
      data: updated,
    };
  }

  @Put('operating-hours')
  @ApiOperation({ summary: 'Update weekly operating hours schedule' })
  @ApiResponse({ status: 200, description: 'Weekly operating schedule updated' })
  async updateOperatingHours(
    @CurrentUser() user: User,
    @Query('vendorId') queryVendorId: string,
    @Body()
    dto: {
      vendorId?: string;
      hours?: Array<{
        dayOfWeek: number;
        openTime: string;
        closeTime: string;
        isClosed: boolean;
      }>;
      operatingHours?: Array<{
        dayOfWeek: number;
        openTime: string;
        closeTime: string;
        isClosed: boolean;
      }>;
    },
  ) {
    const targetVendorId = queryVendorId || dto.vendorId;
    const hours = dto.hours || dto.operatingHours || [];
    const schedule = await this.vendorStaffService.updateOperatingHours(user, targetVendorId, hours);
    return {
      message: 'Operating hours schedule updated successfully',
      data: schedule,
    };
  }

  @Get('sales')
  @ApiOperation({ summary: 'Get daily sales ledger and platform commission breakdown' })
  @ApiResponse({ status: 200, description: 'Sales metrics and commission ledger records' })
  async getSales(
    @CurrentUser() user: User,
    @Query('vendorId') vendorId?: string,
  ) {
    const sales = await this.vendorStaffService.getSalesLedger(user, vendorId);
    return {
      message: 'Sales ledger retrieved successfully',
      data: sales,
    };
  }

  @Get('orders/live')
  @ApiOperation({ summary: 'Get live orders queue for vendor kitchen console' })
  @ApiResponse({ status: 200, description: 'Live kitchen orders list' })
  async getLiveOrders(
    @CurrentUser() user: User,
    @Query('vendorId') vendorId?: string,
  ) {
    const orders = await this.vendorStaffService.getLiveOrders(user, vendorId);
    return {
      message: `Retrieved ${orders.length} live orders`,
      data: orders,
    };
  }

  @Patch('orders/:id/accept')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Accept incoming order with custom or default prep time' })
  @ApiResponse({ status: 200, description: 'Order accepted and transitioned to PREPARING' })
  @ApiResponse({ status: 403, description: 'Forbidden if not authorized for this outlet' })
  async acceptOrder(
    @CurrentUser() user: User,
    @Param('id') orderId: string,
    @Body() dto: AcceptOrderDto,
  ) {
    const order = await this.vendorStaffService.acceptOrder(user, orderId, dto);
    return {
      message: `Order accepted with ${order.prepTimeMinutes} mins prep time`,
      data: order,
    };
  }

  @Patch('orders/:id/ready')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark order as packaged and ready for rider pickup' })
  @ApiResponse({ status: 200, description: 'Order transitioned to READY_FOR_PICKUP' })
  async markReady(
    @CurrentUser() user: User,
    @Param('id') orderId: string,
  ) {
    const order = await this.vendorStaffService.markOrderReady(user, orderId);
    return {
      message: 'Order marked ready for pickup',
      data: order,
    };
  }

  @Patch('orders/:id/handover')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Confirm food handover to rider at counter' })
  @ApiResponse({ status: 200, description: 'Order transitioned to DISPATCHED' })
  async handover(
    @CurrentUser() user: User,
    @Param('id') orderId: string,
  ) {
    const order = await this.vendorStaffService.handoverOrder(user, orderId);
    return {
      message: 'Order handed over to rider (DISPATCHED)',
      data: order,
    };
  }

  @Patch('products/:id/stock')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Instant toggle for product stock availability' })
  @ApiResponse({ status: 200, description: 'Product stock status updated' })
  async toggleProductStock(
    @CurrentUser() user: User,
    @Param('id') productId: string,
    @Body() dto: ToggleStockDto,
  ) {
    const product = await this.vendorStaffService.toggleProductStock(
      user,
      productId,
      dto.isInStock,
    );
    return {
      message: `Product "${product.name}" stock updated to ${dto.isInStock ? 'IN STOCK' : 'OUT OF STOCK'}`,
      data: product,
    };
  }

  @Patch('products/variants/:id/stock')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Instant toggle for product variant stock availability' })
  @ApiResponse({ status: 200, description: 'Variant stock status updated' })
  async toggleVariantStock(
    @CurrentUser() user: User,
    @Param('id') variantId: string,
    @Body() dto: ToggleStockDto,
  ) {
    const variant = await this.vendorStaffService.toggleVariantStock(
      user,
      variantId,
      dto.isInStock,
    );
    return {
      message: `Variant "${variant.name}" stock updated to ${dto.isInStock ? 'IN STOCK' : 'OUT OF STOCK'}`,
      data: variant,
    };
  }
}
