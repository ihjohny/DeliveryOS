import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsLatitude,
  IsLongitude,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class CreateAddressDto {
  @ApiProperty({ example: 'Home', description: 'Address label' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(30)
  label!: string;

  @ApiProperty({ example: 'House 42, Road 11, Block D, Banani, Dhaka', description: 'Full address line' })
  @IsString()
  @IsNotEmpty()
  addressLine!: string;

  @ApiPropertyOptional({ example: 'Flat 4B, 4th Floor', description: 'Building and floor details' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  buildingFloor?: string;

  @ApiPropertyOptional({ example: 'Ring the doorbell twice', description: 'Delivery rider instruction note' })
  @IsOptional()
  @IsString()
  deliveryNote?: string;

  @ApiProperty({ example: 23.7937, description: 'Latitude coordinate' })
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ example: 90.4043, description: 'Longitude coordinate' })
  @IsLongitude()
  longitude!: number;

  @ApiPropertyOptional({ default: false, description: 'Mark as default delivery address' })
  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}
