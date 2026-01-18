import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsUUID, IsNumber, IsDateString } from 'class-validator';

export class CreateDeductionDto {
  @ApiProperty({ description: 'Supplier account ID', required: false })
  @IsOptional()
  @IsUUID()
  supplier_account_id?: string;

  @ApiProperty({ description: 'Fee type ID', example: 'fee-type-uuid' })
  @IsNotEmpty()
  @IsUUID()
  fee_type_id: string;

  @ApiProperty({ description: 'Milk sale ID', required: false })
  @IsOptional()
  @IsUUID()
  milk_sale_id?: string;

  @ApiProperty({ description: 'Deduction amount', example: 100.0 })
  @IsNotEmpty()
  @IsNumber()
  amount: number;

  @ApiProperty({ description: 'Description', required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ description: 'Applied at date', example: '2025-01-04', required: false })
  @IsOptional()
  @IsDateString()
  applied_at?: string;
}

