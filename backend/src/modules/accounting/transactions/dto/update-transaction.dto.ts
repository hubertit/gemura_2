import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, IsNumber, IsDateString, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateTransactionDto {
  @ApiProperty({ description: 'Amount', example: 1000.0, required: false })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @Min(0.01)
  amount?: number;

  @ApiProperty({ description: 'Description', example: 'Updated description', required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ description: 'Transaction date', example: '2025-01-18', required: false })
  @IsOptional()
  @IsDateString()
  transaction_date?: string;
}
