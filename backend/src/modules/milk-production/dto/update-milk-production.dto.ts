import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString, IsUUID, Min } from 'class-validator';

export class UpdateMilkProductionDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  farm_id?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  animal_id?: string;

  @ApiPropertyOptional({ description: 'Date of production (YYYY-MM-DD)' })
  @IsOptional()
  @IsString()
  production_date?: string;

  @ApiPropertyOptional({ description: 'Quantity in litres' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  quantity_litres?: number;

  @ApiPropertyOptional({ description: 'Milking session (e.g. morning, evening)' })
  @IsOptional()
  @IsString()
  session?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;
}
