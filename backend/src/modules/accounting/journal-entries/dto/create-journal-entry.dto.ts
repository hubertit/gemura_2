import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsArray, IsOptional, IsUUID, IsNumber, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class JournalEntryItemDto {
  @ApiProperty({ description: 'Account ID', example: 'account-uuid' })
  @IsNotEmpty()
  @IsUUID()
  account_id: string;

  @ApiProperty({ description: 'Debit amount', example: 1000.0, required: false })
  @IsOptional()
  @IsNumber()
  debit_amount?: number;

  @ApiProperty({ description: 'Credit amount', example: 1000.0, required: false })
  @IsOptional()
  @IsNumber()
  credit_amount?: number;

  @ApiProperty({ description: 'Description', required: false })
  @IsOptional()
  @IsString()
  description?: string;
}

export class CreateJournalEntryDto {
  @ApiProperty({ description: 'Transaction date', example: '2025-01-04' })
  @IsNotEmpty()
  @IsString()
  transaction_date: string;

  @ApiProperty({ description: 'Reference number', example: 'JE-2025-001', required: false })
  @IsOptional()
  @IsString()
  reference_number?: string;

  @ApiProperty({ description: 'Description', required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ description: 'Journal entry items', type: [JournalEntryItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => JournalEntryItemDto)
  entries: JournalEntryItemDto[];
}

