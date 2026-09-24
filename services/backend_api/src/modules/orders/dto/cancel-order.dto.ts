import { IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class CancelOrderDto {
  @ApiPropertyOptional({
    example: 'Changed my mind before preparation started',
    description: 'Customer-provided cancellation reason',
    maxLength: 250,
  })
  @IsOptional()
  @IsString()
  @MaxLength(250)
  reason?: string;
}
