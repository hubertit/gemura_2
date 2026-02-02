import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsNumber, IsOptional, IsArray, IsBoolean, Min, ValidateIf } from 'class-validator';

export class CreateInventoryDto {
  @ApiPropertyOptional({
    description: 'Predefined inventory item UUID. When provided, name/description are taken from the item. Either name or inventory_item_id is required.',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsOptional()
  @IsString()
  inventory_item_id?: string;

  @ApiPropertyOptional({
    description: 'Product name. Required when inventory_item_id is not provided; ignored when inventory_item_id is set.',
    example: 'Fresh Milk 1L',
  })
  @ValidateIf((o) => !o.inventory_item_id)
  @IsNotEmpty({ message: 'Either name or inventory_item_id is required.' })
  @IsString()
  name?: string;

  @ApiPropertyOptional({ description: 'Product description', example: 'Fresh whole milk' })
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
