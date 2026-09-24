import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateProfileDto {
  @ApiPropertyOptional({ example: 'Tanvir Ahmed', description: 'Customer full legal or preferred name' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  fullName?: string;

  @ApiPropertyOptional({ example: 'tanvir@deliveryos.local', description: 'Customer contact email address' })
  @IsOptional()
  @IsEmail()
  email?: string;
}
