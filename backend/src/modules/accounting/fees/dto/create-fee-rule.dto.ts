import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsUUID, IsNumber, IsDateString } from 'class-validator';

export class CreateFeeRuleDto {
  @ApiProperty({ description: 'Supplier account ID', required: false })
  @IsOptional()
  @IsUUID()
  supplier_account_id?: string;

  @ApiProperty({ description: 'Fee type ID', example: 'fee-type-uuid' })
  @IsNotEmpty()
  @IsUUID()
  fee_type_id: string;

  @ApiProperty({ description: 'Fixed amount', required: false })
  @IsOptional()
  @IsNumber()
  fixed_amount?: number;

  @ApiProperty({ description: 'Percentage', required: false })
  @IsOptional()
  @IsNumber()
  percentage?: number;

  @ApiProperty({ description: 'Min amount', required: false })
  @IsOptional()
  @IsNumber()
  min_amount?: number;

  @ApiProperty({ description: 'Max amount', required: false })
  @IsOptional()
  @IsNumber()
  max_amount?: number;

  @ApiProperty({ description: 'Effective from date', example: '2025-01-01' })
  @IsNotEmpty()
  @IsDateString()
  effective_from: string;

  @ApiProperty({ description: 'Effective to date', required: false })
  @IsOptional()
  @IsDateString()
  effective_to?: string;
}

