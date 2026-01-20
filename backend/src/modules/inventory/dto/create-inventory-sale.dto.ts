import {
  IsEnum,
  IsString,
  IsNumber,
  IsOptional,
  IsDateString,
  Min,
  Max,
  ValidateIf,
  IsNotEmpty,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum InventorySaleBuyerType {
  SUPPLIER = 'supplier',
  CUSTOMER = 'customer',
  OTHER = 'other',
}

export enum InventorySalePaymentStatus {
  PAID = 'paid',
  PARTIAL = 'partial',
  UNPAID = 'unpaid',
}

export class CreateInventorySaleDto {
  @ApiProperty({
    description: 'Type of buyer',
    enum: InventorySaleBuyerType,
    example: InventorySaleBuyerType.SUPPLIER,
  })
  @IsEnum(InventorySaleBuyerType)
  buyer_type: InventorySaleBuyerType;

  @ApiPropertyOptional({
    description: 'Buyer account ID (required for supplier, optional for customer/other)',
    example: '123e4567-e89b-12d3-a456-426614174000',
  })
  @IsOptional()
  @IsString({ message: 'buyer_account_id must be a string' })
  buyer_account_id?: string;

  @ApiPropertyOptional({
    description: 'Buyer name (optional, for new clients)',
    example: 'John Doe',
  })
  @IsOptional()
  @IsString()
  buyer_name?: string;

  @ApiPropertyOptional({
    description: 'Buyer phone number (optional, for new clients)',
    example: '250788606765',
  })
  @IsOptional()
  @IsString()
  buyer_phone?: string;

  @ApiProperty({
    description: 'Quantity of items sold',
    example: 5,
    minimum: 0.01,
  })
  @IsNumber()
  @Min(0.01, { message: 'Quantity must be greater than 0' })
  quantity: number;

  @ApiProperty({
    description: 'Unit price per item',
    example: 1000.0,
    minimum: 0,
  })
  @IsNumber()
  @Min(0, { message: 'Unit price must be greater than or equal to 0' })
  unit_price: number;

  @ApiProperty({
    description: 'Amount paid (must equal total_amount for customer/other, can be less for supplier)',
    example: 5000.0,
    minimum: 0,
  })
  @IsNumber()
  @Min(0, { message: 'Amount paid must be greater than or equal to 0' })
  amount_paid: number;

  @ApiPropertyOptional({
    description: 'Sale date (ISO 8601 format). Defaults to current date if not provided.',
    example: '2025-01-20T10:00:00Z',
  })
  @IsOptional()
  @IsDateString()
  sale_date?: string;

  @ApiPropertyOptional({
    description: 'Additional notes about the sale',
    example: 'Sold to supplier on credit',
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
