import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsUUID, IsNumber, IsDateString, Min } from 'class-validator';

export class CreateReceiptDto {
  @ApiProperty({ description: 'Receipt number', example: 'RCP-2025-001' })
  @IsNotEmpty()
  @IsString()
  receipt_number: string;

  @ApiProperty({ description: 'Supplier account ID', required: false })
  @IsOptional()
  @IsUUID()
  supplier_account_id?: string;

  @ApiProperty({ description: 'Customer account ID', required: false })
  @IsOptional()
  @IsUUID()
  customer_account_id?: string;

  @ApiProperty({ description: 'Payment date', example: '2025-01-04' })
  @IsNotEmpty()
  @IsDateString()
  payment_date: string;

  @ApiProperty({ description: 'Payment amount', example: 50000.0 })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  amount: number;

  @ApiProperty({ description: 'Payment method', example: 'cash', required: false })
  @IsOptional()
  @IsString()
  payment_method?: string;

  @ApiProperty({ description: 'Reference', required: false })
  @IsOptional()
  @IsString()
  reference?: string;
}

