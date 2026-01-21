import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNumber, IsOptional, IsEnum, IsDateString, Min } from 'class-validator';
import { MilkSaleStatus } from '@prisma/client';

export class CreateSaleDto {
  @ApiProperty({
    description: 'Customer account ID (UUID) - preferred method',
    example: '123e4567-e89b-12d3-a456-426614174000',
    required: false,
  })
  @IsString()
  @IsOptional()
  customer_account_id?: string;

  @ApiProperty({
    description: 'Customer account code (fallback if customer_account_id not provided)',
    example: 'A_XYZ789',
    required: false,
  })
  @IsString()
  @IsOptional()
  customer_account_code?: string;

  @ApiProperty({
    description: 'Quantity of milk in liters',
    example: 120.5,
    minimum: 0,
  })
  @IsNumber()
  @Min(0)
  quantity: number;

  @ApiProperty({
    description: 'Unit price per liter',
    example: 390.0,
    minimum: 0,
    required: false,
  })
  @IsNumber()
  @IsOptional()
  @Min(0)
  unit_price?: number;

  @ApiProperty({
    description: 'Sale status',
    enum: ['pending', 'accepted', 'rejected', 'cancelled'],
    example: 'accepted',
    required: false,
    default: 'accepted',
  })
  @IsEnum(['pending', 'accepted', 'rejected', 'cancelled'])
  @IsOptional()
  status?: MilkSaleStatus;

  @ApiProperty({
    description: 'Sale date and time',
    example: '2025-01-04T10:00:00Z',
    required: false,
  })
  @IsDateString()
  @IsOptional()
  sale_at?: string;

  @ApiProperty({
    description: 'Additional notes',
    example: 'Morning delivery',
    required: false,
  })
  @IsString()
  @IsOptional()
  notes?: string;

  @ApiProperty({
    description: 'Payment status - whether payment has been made',
    example: 'paid',
    enum: ['paid', 'unpaid'],
    required: false,
    default: 'unpaid',
  })
  @IsOptional()
  @IsString({ message: 'Payment status must be a string' })
  payment_status?: string;
}

