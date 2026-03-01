import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsOptional, IsString, IsUUID, Min } from 'class-validator';

export class CreateMilkProductionDto {
  @ApiPropertyOptional({ description: 'Farm ID (optional; use for farm-level production)' })
  @IsOptional()
  @IsUUID()
  farm_id?: string;

  @ApiPropertyOptional({ description: 'Animal ID (optional; use for animal-level production)' })
  @IsOptional()
  @IsUUID()
  animal_id?: string;

  @ApiProperty({ description: 'Date of production (YYYY-MM-DD)', example: '2026-03-01' })
  @IsNotEmpty()
  @IsString()
  production_date: string;

  @ApiProperty({ description: 'Quantity in litres', example: 12.5 })
  @IsNumber()
  @Min(0)
  quantity_litres: number;

  @ApiPropertyOptional({ description: 'Milking session (e.g. morning, evening)', example: 'morning' })
  @IsOptional()
  @IsString()
  session?: string;

  @ApiPropertyOptional({ description: 'Notes (e.g. quality)' })
  @IsOptional()
  @IsString()
  notes?: string;
}
