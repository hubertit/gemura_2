import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsNumber, IsEnum, IsOptional, IsUUID, IsDateString, Min } from 'class-validator';
import { Type } from 'class-transformer';

export enum TransactionType {
  REVENUE = 'revenue',
  EXPENSE = 'expense',
}

export class CreateTransactionDto {
  @ApiProperty({ 
    description: 'Transaction type', 
    enum: TransactionType,
    example: TransactionType.REVENUE 
  })
  @IsNotEmpty()
  @IsEnum(TransactionType)
  type: TransactionType;

  @ApiProperty({ description: 'Amount', example: 1000.0 })
  @IsNotEmpty()
  @IsNumber()
  @Type(() => Number)
  @Min(0.01)
  amount: number;

  @ApiProperty({ description: 'Description', example: 'Milk sales revenue' })
  @IsNotEmpty()
  @IsString()
  description: string;

  @ApiProperty({ description: 'Transaction date', example: '2025-01-18' })
  @IsNotEmpty()
  @IsDateString()
  transaction_date: string;

  @ApiProperty({ description: 'Chart of account ID for revenue/expense category', required: false })
  @IsOptional()
  @IsUUID()
  account_id?: string; // Optional: specific revenue/expense account from chart of accounts
}
