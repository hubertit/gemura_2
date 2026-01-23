import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class RecordPaymentDto {
  @ApiProperty({
    description: 'Payment amount',
    example: 50000,
    minimum: 0.01,
  })
  @IsNumber()
  @Min(0.01, { message: 'Payment amount must be greater than 0' })
  amount: number;

  @ApiProperty({
    description: 'Payment date (YYYY-MM-DD). If not provided, uses current date.',
    example: '2025-01-23',
    required: false,
  })
  @IsString()
  @IsOptional()
  payment_date?: string;

  @ApiProperty({
    description: 'Payment notes',
    example: 'Partial payment via mobile money',
    required: false,
  })
  @IsString()
  @IsOptional()
  notes?: string;
}
