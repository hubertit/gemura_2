import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, IsUUID, IsDateString, IsEnum } from 'class-validator';
import { IsNotFutureDate } from '../../../common/validators/not-future-date.validator';

export enum BreedingMethodEnum {
  natural = 'natural',
  artificial_insemination = 'artificial_insemination',
}

export enum BreedingOutcomeEnum {
  pregnant = 'pregnant',
  not_pregnant = 'not_pregnant',
  unknown = 'unknown',
}

export class CreateAnimalBreedingDto {
  @ApiProperty({ description: 'Date of breeding (YYYY-MM-DD), must not be in the future', example: '2026-02-15' })
  @IsNotEmpty()
  @IsDateString()
  @IsNotFutureDate({ message: 'Breeding date must not be in the future' })
  breeding_date: string;

  @ApiPropertyOptional({ description: 'Heat date (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  heat_date?: string;

  @ApiProperty({ description: 'Method', enum: BreedingMethodEnum })
  @IsNotEmpty()
  @IsEnum(BreedingMethodEnum)
  method: BreedingMethodEnum;

  @ApiPropertyOptional({ description: 'Bull animal ID if natural and bull is registered' })
  @IsOptional()
  @IsUUID()
  bull_animal_id?: string;

  @ApiPropertyOptional({ description: 'Bull name (free text if no animal record)' })
  @IsOptional()
  @IsString()
  bull_name?: string;

  @ApiPropertyOptional({ description: 'Semen code for AI' })
  @IsOptional()
  @IsString()
  semen_code?: string;

  @ApiPropertyOptional({ description: 'Expected calving date (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  expected_calving_date?: string;

  @ApiPropertyOptional({ description: 'Outcome after pregnancy check or calving', enum: BreedingOutcomeEnum, default: 'unknown' })
  @IsOptional()
  @IsEnum(BreedingOutcomeEnum)
  outcome?: BreedingOutcomeEnum;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;
}
