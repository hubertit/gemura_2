import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsEnum, IsNumber, IsDateString, Min } from 'class-validator';
import { AnimalGenderEnum, AnimalSourceEnum, AnimalStatusEnum } from './create-animal.dto';

export class UpdateAnimalDto {
  @ApiPropertyOptional({ description: 'Tag number' })
  @IsOptional()
  @IsString()
  tag_number?: string;

  @ApiPropertyOptional({ description: 'Name' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ description: 'Breed' })
  @IsOptional()
  @IsString()
  breed?: string;

  @ApiPropertyOptional({ enum: AnimalGenderEnum })
  @IsOptional()
  @IsEnum(AnimalGenderEnum)
  gender?: AnimalGenderEnum;

  @ApiPropertyOptional({ description: 'Date of birth (ISO date)' })
  @IsOptional()
  @IsDateString()
  date_of_birth?: string;

  @ApiPropertyOptional({ enum: AnimalSourceEnum })
  @IsOptional()
  @IsEnum(AnimalSourceEnum)
  source?: AnimalSourceEnum;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  purchase_date?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  purchase_price?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  mother_id?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  father_id?: string;

  @ApiPropertyOptional({ enum: AnimalStatusEnum })
  @IsOptional()
  @IsEnum(AnimalStatusEnum)
  status?: AnimalStatusEnum;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  photo_url?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ description: 'Farm ID where the animal is kept (UUID)' })
  @IsOptional()
  @IsString()
  farm_id?: string;
}
