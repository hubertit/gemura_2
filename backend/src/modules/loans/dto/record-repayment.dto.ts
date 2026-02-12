import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class RecordRepaymentDto {
  @ApiProperty({
    description: 'Repayment amount',
    example: 25000,
    minimum: 0.01,
  })
  @IsNotEmpty()
  @Type(() => Number)
  @IsNumber()
  @Min(0.01)
  amount: number;

  @ApiProperty({
    description: 'Repayment date (YYYY-MM-DD)',
    example: '2025-02-12',
    required: false,
  })
  @IsOptional()
  @IsString()
  repayment_date?: string;

  @ApiProperty({
    description: 'Notes',
    required: false,
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
