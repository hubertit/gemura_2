import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsNumber, IsOptional, IsIn, IsUUID, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateLoanDto {
  @ApiProperty({
    description: 'Lender account ID (optional; uses default account if not provided)',
    example: '550e8400-e29b-41d4-a716-446655440000',
    required: false,
  })
  @IsOptional()
  @IsUUID()
  account_id?: string;

  @ApiProperty({
    description: 'Borrower type: supplier, customer, or other',
    example: 'supplier',
    enum: ['supplier', 'customer', 'other'],
  })
  @IsNotEmpty()
  @IsString()
  @IsIn(['supplier', 'customer', 'other'])
  borrower_type: string;

  @ApiProperty({
    description: 'Borrower account ID (required for supplier/customer)',
    example: '550e8400-e29b-41d4-a716-446655440000',
    required: false,
  })
  @IsOptional()
  @IsUUID()
  borrower_account_id?: string;

  @ApiProperty({
    description: 'Borrower name (for "other" or display)',
    example: 'John Doe',
    required: false,
  })
  @IsOptional()
  @IsString()
  borrower_name?: string;

  @ApiProperty({
    description: 'Borrower phone (for "other" – used to find or create their account)',
    example: '250788123456',
    required: false,
  })
  @IsOptional()
  @IsString()
  borrower_phone?: string;

  @ApiProperty({
    description: 'Loan principal amount',
    example: 100000,
    minimum: 0.01,
  })
  @IsNotEmpty()
  @Type(() => Number)
  @IsNumber()
  @Min(0.01)
  principal: number;

  @ApiProperty({
    description: 'Currency code',
    example: 'RWF',
    default: 'RWF',
  })
  @IsOptional()
  @IsString()
  currency?: string;

  @ApiProperty({
    description: 'Disbursement date (YYYY-MM-DD)',
    example: '2025-02-12',
  })
  @IsNotEmpty()
  @IsString()
  disbursement_date: string;

  @ApiProperty({
    description: 'Due date (YYYY-MM-DD)',
    example: '2025-03-12',
    required: false,
  })
  @IsOptional()
  @IsString()
  due_date?: string;

  @ApiProperty({
    description: 'Notes',
    required: false,
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
