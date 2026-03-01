import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsOptional, IsString, IsDateString, Min } from 'class-validator';
import { IsNotFutureDate } from '../../../common/validators/not-future-date.validator';

export class CreateAnimalWeightDto {
  @ApiProperty({ description: 'Weight in kg', example: 420.5 })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  weight_kg: number;

  @ApiProperty({ description: 'When weight was recorded (ISO date/time), must not be in the future', example: '2025-02-20T10:00:00Z' })
  @IsNotEmpty()
  @IsDateString()
  @IsNotFutureDate({ message: 'Recorded date/time must not be in the future' })
  recorded_at: string;

  @ApiPropertyOptional({ description: 'Notes' })
  @IsOptional()
  @IsString()
  notes?: string;
}
