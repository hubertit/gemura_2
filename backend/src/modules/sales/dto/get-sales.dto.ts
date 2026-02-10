import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString, IsNumber } from 'class-validator';

export class SalesFiltersDto {
  @ApiProperty({ required: false, description: 'Customer account code' })
  @IsOptional()
  @IsString()
  customer_account_code?: string;

  @ApiProperty({ required: false, description: 'Sale status' })
  @IsOptional()
  @IsString()
  status?: string;

  @ApiProperty({ required: false, description: 'Date from (YYYY-MM-DD)' })
  @IsOptional()
  @IsString()
  date_from?: string;

  @ApiProperty({ required: false, description: 'Date to (YYYY-MM-DD)' })
  @IsOptional()
  @IsString()
  date_to?: string;

  @ApiProperty({ required: false, description: 'Minimum quantity' })
  @IsOptional()
  @IsNumber()
  quantity_min?: number;

  @ApiProperty({ required: false, description: 'Maximum quantity' })
  @IsOptional()
  @IsNumber()
  quantity_max?: number;

  @ApiProperty({ required: false, description: 'Minimum price' })
  @IsOptional()
  @IsNumber()
  price_min?: number;

  @ApiProperty({ required: false, description: 'Maximum price' })
  @IsOptional()
  @IsNumber()
  price_max?: number;
}

export class GetSalesDto {
  @ApiProperty({ type: SalesFiltersDto, required: false })
  @IsOptional()
  filters?: SalesFiltersDto;

  @ApiProperty({ required: false, description: 'Scope list to this account (must have access). Defaults to user default account.' })
  @IsOptional()
  @IsString()
  account_id?: string;
}

