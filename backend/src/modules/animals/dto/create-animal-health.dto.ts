import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsString,
  IsOptional,
  IsNumber,
  IsDateString,
  IsEnum,
  Min,
} from 'class-validator';
import { IsNotFutureDate } from '../../../common/validators/not-future-date.validator';

export enum HealthEventTypeEnum {
  vaccination = 'vaccination',
  treatment = 'treatment',
  deworming = 'deworming',
  examination = 'examination',
  surgery = 'surgery',
  injury = 'injury',
  illness = 'illness',
  other = 'other',
}

export class CreateAnimalHealthDto {
  @ApiProperty({ description: 'Event type', enum: HealthEventTypeEnum })
  @IsNotEmpty()
  @IsEnum(HealthEventTypeEnum)
  event_type: HealthEventTypeEnum;

  @ApiProperty({ description: 'Event date (ISO date), must not be in the future', example: '2025-02-20' })
  @IsNotEmpty()
  @IsDateString()
  @IsNotFutureDate({ message: 'Event date must not be in the future' })
  event_date: string;

  @ApiProperty({ description: 'Description of the event' })
  @IsNotEmpty()
  @IsString()
  description: string;

  @ApiPropertyOptional({ description: 'Diagnosis' })
  @IsOptional()
  @IsString()
  diagnosis?: string;

  @ApiPropertyOptional({ description: 'Treatment given' })
  @IsOptional()
  @IsString()
  treatment?: string;

  @ApiPropertyOptional({ description: 'Medicine name' })
  @IsOptional()
  @IsString()
  medicine_name?: string;

  @ApiPropertyOptional({ description: 'Dosage' })
  @IsOptional()
  @IsString()
  dosage?: string;

  @ApiPropertyOptional({ description: 'Who administered' })
  @IsOptional()
  @IsString()
  administered_by?: string;

  @ApiPropertyOptional({ description: 'Next due date (e.g. for vaccinations)' })
  @IsOptional()
  @IsDateString()
  next_due_date?: string;

  @ApiPropertyOptional({ description: 'Cost' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  cost?: number;

  @ApiPropertyOptional({ description: 'Notes' })
  @IsOptional()
  @IsString()
  notes?: string;
}
