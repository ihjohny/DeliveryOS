import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { AddressesService } from './addresses.service';
import { CreateAddressDto } from './dto/create-address.dto';
import { UpdateAddressDto } from './dto/update-address.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

@ApiTags('Customer Addresses & Profile')
@Controller('customers')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class AddressesController {
  constructor(private readonly addressesService: AddressesService) {}

  @Post('addresses')
  @ApiOperation({ summary: 'Save new customer delivery address' })
  async createAddress(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateAddressDto,
  ) {
    return this.addressesService.createAddress(userId, dto);
  }

  @Get('addresses')
  @ApiOperation({ summary: 'List all saved delivery addresses for current customer' })
  async getUserAddresses(@CurrentUser('id') userId: string) {
    return this.addressesService.getUserAddresses(userId);
  }

  @Put('addresses/:id')
  @ApiOperation({ summary: 'Update saved customer delivery address' })
  async updateAddress(
    @CurrentUser('id') userId: string,
    @Param('id') addressId: string,
    @Body() dto: UpdateAddressDto,
  ) {
    return this.addressesService.updateAddress(userId, addressId, dto);
  }

  @Delete('addresses/:id')
  @ApiOperation({ summary: 'Delete saved customer delivery address' })
  async deleteAddress(
    @CurrentUser('id') userId: string,
    @Param('id') addressId: string,
  ) {
    return this.addressesService.deleteAddress(userId, addressId);
  }

  @Patch('addresses/:id/default')
  @ApiOperation({ summary: 'Set target address as customer default delivery address' })
  async setDefaultAddress(
    @CurrentUser('id') userId: string,
    @Param('id') addressId: string,
  ) {
    return this.addressesService.setDefaultAddress(userId, addressId);
  }

  @Get('profile')
  @ApiOperation({ summary: 'Get current customer profile with saved addresses and order metrics' })
  async getProfile(@CurrentUser('id') userId: string) {
    return this.addressesService.getProfile(userId);
  }

  @Patch('profile')
  @ApiOperation({ summary: 'Update customer profile full name and email' })
  async updateProfile(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateProfileDto,
  ) {
    return this.addressesService.updateProfile(userId, dto);
  }
}
