import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNumber, IsOptional, IsArray, Min } from 'class-validator';

export class UpdateProductDto {
  @ApiProperty({ description: 'Product name', required: false })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiProperty({ description: 'Product description', required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ description: 'Product price', minimum: 0, required: false })
  @IsOptional()
  @IsNumber()
  @Min(0)
  price?: number;

  @ApiProperty({ description: 'Stock quantity', minimum: 0, required: false })
  @IsOptional()
  @IsNumber()
  @Min(0)
  stock_quantity?: number;

  @ApiProperty({ description: 'Product status', enum: ['active', 'inactive'], required: false })
  @IsOptional()
  @IsString()
  status?: string;

  @ApiProperty({ description: 'Category IDs', required: false })
  @IsOptional()
  @IsArray()
  category_ids?: string[];
}

