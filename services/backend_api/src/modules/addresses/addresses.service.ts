import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { CreateAddressDto } from './dto/create-address.dto';
import { UpdateAddressDto } from './dto/update-address.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class AddressesService {
  private readonly logger = new Logger(AddressesService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * 1. Add New Customer Address
   */
  async createAddress(userId: string, dto: CreateAddressDto) {
    return this.prisma.$transaction(async (tx) => {
      // If marking as default, reset other addresses for this user
      if (dto.isDefault) {
        await tx.customerAddress.updateMany({
          where: { userId },
          data: { isDefault: false },
        });
      } else {
        // If this is user's first address, automatically make it default
        const existingCount = await tx.customerAddress.count({ where: { userId } });
        if (existingCount === 0) {
          dto.isDefault = true;
        }
      }

      const address = await tx.customerAddress.create({
        data: {
          userId,
          label: dto.label,
          addressLine: dto.addressLine,
          buildingFloor: dto.buildingFloor,
          deliveryNote: dto.deliveryNote,
          latitude: dto.latitude,
          longitude: dto.longitude,
          isDefault: dto.isDefault ?? false,
        },
      });

      this.logger.log(`Created Address ${address.id} ("${address.label}") for User ${userId}`);
      return address;
    });
  }

  /**
   * 2. List All Saved Addresses for Authenticated Customer
   */
  async getUserAddresses(userId: string) {
    return this.prisma.customerAddress.findMany({
      where: { userId },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    });
  }

  /**
   * 3. Update Existing Customer Address
   */
  async updateAddress(userId: string, addressId: string, dto: UpdateAddressDto) {
    const existing = await this.prisma.customerAddress.findUnique({
      where: { id: addressId },
    });

    if (!existing) {
      throw new NotFoundException(`Address with ID "${addressId}" not found`);
    }

    if (existing.userId !== userId) {
      throw new ForbiddenException('You do not have permission to modify this address');
    }

    return this.prisma.$transaction(async (tx) => {
      if (dto.isDefault) {
        await tx.customerAddress.updateMany({
          where: { userId },
          data: { isDefault: false },
        });
      }

      return tx.customerAddress.update({
        where: { id: addressId },
        data: {
          ...(dto.label !== undefined && { label: dto.label }),
          ...(dto.addressLine !== undefined && { addressLine: dto.addressLine }),
          ...(dto.buildingFloor !== undefined && { buildingFloor: dto.buildingFloor }),
          ...(dto.deliveryNote !== undefined && { deliveryNote: dto.deliveryNote }),
          ...(dto.latitude !== undefined && { latitude: dto.latitude }),
          ...(dto.longitude !== undefined && { longitude: dto.longitude }),
          ...(dto.isDefault !== undefined && { isDefault: dto.isDefault }),
        },
      });
    });
  }

  /**
   * 4. Delete Saved Customer Address
   */
  async deleteAddress(userId: string, addressId: string) {
    const existing = await this.prisma.customerAddress.findUnique({
      where: { id: addressId },
    });

    if (!existing) {
      throw new NotFoundException(`Address with ID "${addressId}" not found`);
    }

    if (existing.userId !== userId) {
      throw new ForbiddenException('You do not have permission to delete this address');
    }

    await this.prisma.customerAddress.delete({
      where: { id: addressId },
    });

    // If deleted address was default, promote the most recent remaining address
    if (existing.isDefault) {
      const nextAddress = await this.prisma.customerAddress.findFirst({
        where: { userId },
        orderBy: { createdAt: 'desc' },
      });
      if (nextAddress) {
        await this.prisma.customerAddress.update({
          where: { id: nextAddress.id },
          data: { isDefault: true },
        });
      }
    }

    return { success: true, message: 'Address deleted successfully' };
  }

  /**
   * 5. Set Default Customer Address
   */
  async setDefaultAddress(userId: string, addressId: string) {
    const existing = await this.prisma.customerAddress.findUnique({
      where: { id: addressId },
    });

    if (!existing) {
      throw new NotFoundException(`Address with ID "${addressId}" not found`);
    }

    if (existing.userId !== userId) {
      throw new ForbiddenException('You do not have permission to modify this address');
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.customerAddress.updateMany({
        where: { userId },
        data: { isDefault: false },
      });

      return tx.customerAddress.update({
        where: { id: addressId },
        data: { isDefault: true },
      });
    });
  }

  /**
   * 6. Retrieve Customer Profile
   */
  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        _count: {
          select: { orders: true, addresses: true },
        },
        addresses: {
          orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
        },
      },
    });

    if (!user) {
      throw new NotFoundException(`User with ID "${userId}" not found`);
    }

    return {
      id: user.id,
      phone: user.phone,
      fullName: user.fullName || '',
      email: user.email || '',
      role: user.role,
      totalOrders: user._count.orders,
      totalAddresses: user._count.addresses,
      addresses: user.addresses,
      createdAt: user.createdAt,
    };
  }

  /**
   * 7. Update Customer Profile Name and Email
   */
  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException(`User with ID "${userId}" not found`);
    }

    if (dto.email && dto.email !== user.email) {
      const emailExists = await this.prisma.user.findFirst({ where: { email: dto.email } });
      if (emailExists) {
        throw new BadRequestException('Email address is already in use by another account');
      }
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(dto.fullName !== undefined && { fullName: dto.fullName }),
        ...(dto.email !== undefined && { email: dto.email }),
      },
      select: {
        id: true,
        phone: true,
        fullName: true,
        email: true,
        role: true,
        updatedAt: true,
      },
    });

    this.logger.log(`Updated profile for User ${userId}`);
    return updated;
  }
}
