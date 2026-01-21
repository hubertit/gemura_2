import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, IsNumber } from 'class-validator';

export class UpdateSaleDto {
  @ApiProperty({ description: 'Sale ID' })
  @IsNotEmpty()
  @IsString()
  sale_id: string;

  @ApiProperty({ required: false, description: 'Customer account ID (UUID) - preferred method' })
  @IsOptional()
  @IsString()
  customer_account_id?: string;

  @ApiProperty({ required: false, description: 'Customer account code (fallback if customer_account_id not provided)' })
  @IsOptional()
  @IsString()
  customer_account_code?: string;

  @ApiProperty({ required: false, description: 'Quantity in liters' })
  @IsOptional()
  @IsNumber()
  quantity?: number;

  @ApiProperty({ required: false, description: 'Sale status' })
  @IsOptional()
  @IsString()
  status?: string;

  @ApiProperty({ required: false, description: 'Sale date/time' })
  @IsOptional()
  @IsString()
  sale_at?: string;

  @ApiProperty({ required: false, description: 'Notes' })
  @IsOptional()
  @IsString()
  notes?: string;
}

