import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsUUID, IsNumber, IsArray, IsDateString, ValidateNested, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class InvoiceItemDto {
  @ApiProperty({ description: 'Item description', example: 'Milk Collection - 100L' })
  @IsNotEmpty()
  @IsString()
  description: string;

  @ApiProperty({ description: 'Quantity', example: 100.0, required: false })
  @IsOptional()
  @IsNumber()
  quantity?: number;

  @ApiProperty({ description: 'Unit price', example: 390.0 })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  unit_price: number;

  @ApiProperty({ description: 'Total amount', example: 39000.0 })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  total_amount: number;
}

export class CreateInvoiceDto {
  @ApiProperty({ description: 'Invoice number', example: 'INV-2025-001' })
  @IsNotEmpty()
  @IsString()
  invoice_number: string;

  @ApiProperty({ description: 'Supplier account ID', required: false })
  @IsOptional()
  @IsUUID()
  supplier_account_id?: string;

  @ApiProperty({ description: 'Issue date', example: '2025-01-04' })
  @IsNotEmpty()
  @IsDateString()
  issue_date: string;

  @ApiProperty({ description: 'Due date', example: '2025-01-14', required: false })
  @IsOptional()
  @IsDateString()
  due_date?: string;

  @ApiProperty({ description: 'Tax amount', example: 0, required: false })
  @IsOptional()
  @IsNumber()
  tax_amount?: number;

  @ApiProperty({ description: 'Invoice items', type: [InvoiceItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => InvoiceItemDto)
  items: InvoiceItemDto[];
}

