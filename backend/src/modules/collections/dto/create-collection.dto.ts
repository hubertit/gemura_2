import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsNumber, IsOptional } from 'class-validator';

export class CreateCollectionDto {
  @ApiProperty({
    description: 'Supplier account code (from supplier creation)',
    example: 'A_ABC123',
    required: true,
  })
  @IsNotEmpty({ message: 'Supplier account code is required' })
  @IsString({ message: 'Supplier account code must be a string' })
  supplier_account_code: string;

  @ApiProperty({
    description: 'Quantity of milk collected in liters',
    example: 120.5,
    minimum: 0.01,
    required: true,
  })
  @IsNotEmpty({ message: 'Quantity is required' })
  @IsNumber({}, { message: 'Quantity must be a number' })
  quantity: number;

  @ApiProperty({
    description: 'Collection status',
    example: 'pending',
    enum: ['pending', 'completed', 'cancelled'],
    required: true,
  })
  @IsNotEmpty({ message: 'Status is required' })
  @IsString({ message: 'Status must be a string' })
  status: string;

  @ApiProperty({
    description: 'Collection date and time in format: YYYY-MM-DD HH:mm:ss',
    example: '2025-01-04 10:00:00',
    required: true,
  })
  @IsNotEmpty({ message: 'Collection date/time is required' })
  @IsString({ message: 'Collection date/time must be a string' })
  collection_at: string;

  @ApiProperty({
    description: 'Additional notes about the collection (optional)',
    example: 'Morning collection, good quality milk',
    required: false,
  })
  @IsOptional()
  @IsString({ message: 'Notes must be a string' })
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

