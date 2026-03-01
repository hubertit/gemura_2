import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsString,
  IsNumber,
  IsOptional,
  IsEnum,
  IsDateString,
  Min,
} from 'class-validator';

export enum AnimalGenderEnum {
  male = 'male',
  female = 'female',
}

export enum AnimalSourceEnum {
  born_on_farm = 'born_on_farm',
  purchased = 'purchased',
  donated = 'donated',
  other = 'other',
}

export enum AnimalStatusEnum {
  active = 'active',
  lactating = 'lactating',
  dry = 'dry',
  pregnant = 'pregnant',
  sick = 'sick',
  sold = 'sold',
  dead = 'dead',
  culled = 'culled',
}

export class CreateAnimalDto {
  @ApiProperty({ description: 'Unique tag number (e.g. ear tag)', example: 'TAG-001' })
  @IsNotEmpty()
  @IsString()
  tag_number: string;

  @ApiPropertyOptional({ description: 'Optional name', example: 'Bella' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiProperty({ description: 'Breed', example: 'Holstein' })
  @IsNotEmpty()
  @IsString()
  breed: string;

  @ApiProperty({ description: 'Gender', enum: AnimalGenderEnum })
  @IsNotEmpty()
  @IsEnum(AnimalGenderEnum)
  gender: AnimalGenderEnum;

  @ApiProperty({ description: 'Date of birth (ISO date)', example: '2022-03-15' })
  @IsNotEmpty()
  @IsDateString()
  date_of_birth: string;

  @ApiProperty({ description: 'Source', enum: AnimalSourceEnum })
  @IsNotEmpty()
  @IsEnum(AnimalSourceEnum)
  source: AnimalSourceEnum;

  @ApiPropertyOptional({ description: 'Purchase date if source is purchased' })
  @IsOptional()
  @IsDateString()
  purchase_date?: string;

  @ApiPropertyOptional({ description: 'Purchase price if purchased' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  purchase_price?: number;

  @ApiPropertyOptional({ description: 'Mother animal ID (UUID)' })
  @IsOptional()
  @IsString()
  mother_id?: string;

  @ApiPropertyOptional({ description: 'Father animal ID (UUID)' })
  @IsOptional()
  @IsString()
  father_id?: string;

  @ApiPropertyOptional({ description: 'Status', enum: AnimalStatusEnum, default: 'active' })
  @IsOptional()
  @IsEnum(AnimalStatusEnum)
  status?: AnimalStatusEnum;

  @ApiPropertyOptional({ description: 'Photo URL' })
  @IsOptional()
  @IsString()
  photo_url?: string;

  @ApiPropertyOptional({ description: 'Notes' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ description: 'Farm ID where the animal is kept (UUID). If omitted, backend can default to a primary farm later.' })
  @IsOptional()
  @IsString()
  farm_id?: string;
}
