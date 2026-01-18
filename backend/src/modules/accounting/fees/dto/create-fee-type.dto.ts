import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class CreateFeeTypeDto {
  @ApiProperty({ description: 'Fee code', example: 'COLL_FEE' })
  @IsNotEmpty()
  @IsString()
  code: string;

  @ApiProperty({ description: 'Fee name', example: 'Collection Fee' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ description: 'Description', required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ description: 'Fee category', example: 'collection_fee' })
  @IsNotEmpty()
  @IsString()
  fee_category: string;

  @ApiProperty({ description: 'Calculation type', example: 'percentage' })
  @IsNotEmpty()
  @IsString()
  calculation_type: string;
}

