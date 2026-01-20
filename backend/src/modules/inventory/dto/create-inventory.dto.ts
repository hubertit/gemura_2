import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsNumber, IsOptional, IsArray, IsBoolean, Min } from 'class-validator';

export class CreateInventoryDto {
  @ApiProperty({ description: 'Product name', example: 'Fresh Milk 1L' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ description: 'Product description', example: 'Fresh whole milk', required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ description: 'Product price', example: 500.0, minimum: 0 })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  price: number;

  @ApiProperty({ description: 'Initial stock quantity', example: 100, minimum: 0, required: false })
  @IsOptional()
  @IsNumber()
  @Min(0)
  stock_quantity?: number;

  @ApiProperty({ description: 'Minimum stock level for alerts', example: 10, minimum: 0, required: false })
  @IsOptional()
  @IsNumber()
  @Min(0)
  min_stock_level?: number;

  @ApiProperty({ description: 'Category IDs', example: ['category-uuid'], required: false })
  @IsOptional()
  @IsArray()
  category_ids?: string[];

  @ApiProperty({ description: 'Whether to list in marketplace immediately', example: false, required: false })
  @IsOptional()
  @IsBoolean()
  is_listed_in_marketplace?: boolean;
}
