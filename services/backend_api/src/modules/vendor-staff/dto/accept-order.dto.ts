import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

export class AcceptOrderDto {
  @ApiPropertyOptional({
    description: 'Preparation time in minutes. If omitted, uses outlet default prep time.',
    example: 25,
  })
  @IsOptional()
  @IsInt()
  @Min(5)
  @Max(180)
  prepTimeMinutes?: number;
}
