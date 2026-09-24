import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsLatitude,
  IsLongitude,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class UpdateAddressDto {
  @ApiPropertyOptional({ example: 'Home', description: 'Address label' })
  @IsOptional()
  @IsString()
  @MaxLength(30)
  label?: string;

  @ApiPropertyOptional({ example: 'House 42, Road 11, Block D, Banani, Dhaka', description: 'Full address line' })
  @IsOptional()
  @IsString()
  addressLine?: string;

  @ApiPropertyOptional({ example: 'Flat 4B, 4th Floor', description: 'Building and floor details' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  buildingFloor?: string;

  @ApiPropertyOptional({ example: 'Leave with guard', description: 'Delivery rider instruction note' })
  @IsOptional()
  @IsString()
  deliveryNote?: string;

  @ApiPropertyOptional({ example: 23.7937, description: 'Latitude coordinate' })
  @IsOptional()
  @IsLatitude()
  latitude?: number;

  @ApiPropertyOptional({ example: 90.4043, description: 'Longitude coordinate' })
  @IsOptional()
  @IsLongitude()
  longitude?: number;

  @ApiPropertyOptional({ default: false, description: 'Mark as default delivery address' })
  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}
