import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNumber, IsOptional, IsEnum, IsDateString, Min } from 'class-validator';
import { MilkSaleStatus } from '@prisma/client';

export class CreateSaleDto {
  @ApiProperty({
    description: 'Customer account code',
    example: 'A_XYZ789',
  })
  @IsString()
  customer_account_code: string;

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
    example: 'pending',
    required: false,
    default: 'pending',
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

