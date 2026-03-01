import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, IsUUID, IsDateString, IsEnum, IsNumber, Min } from 'class-validator';
import { IsNotFutureDate } from '../../../common/validators/not-future-date.validator';

export enum CalvingOutcomeEnum {
  live = 'live',
  stillborn = 'stillborn',
  aborted = 'aborted',
}

export class CreateAnimalCalvingDto {
  @ApiProperty({ description: 'Date of calving (YYYY-MM-DD), must not be in the future', example: '2026-03-01' })
  @IsNotEmpty()
  @IsDateString()
  @IsNotFutureDate({ message: 'Calving date must not be in the future' })
  calving_date: string;

  @ApiPropertyOptional({ description: 'Calf animal ID if calf already registered' })
  @IsOptional()
  @IsUUID()
  calf_id?: string;

  @ApiProperty({ description: 'Outcome', enum: CalvingOutcomeEnum })
  @IsNotEmpty()
  @IsEnum(CalvingOutcomeEnum)
  outcome: CalvingOutcomeEnum;

  @ApiPropertyOptional({ description: 'Calf gender', enum: ['male', 'female'] })
  @IsOptional()
  @IsEnum(['male', 'female'])
  gender?: 'male' | 'female';

  @ApiPropertyOptional({ description: 'Birth weight (kg)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  weight_kg?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;
}
