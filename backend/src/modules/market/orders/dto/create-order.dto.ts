import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsNotEmpty, IsString, IsOptional, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class OrderItemDto {
  @ApiProperty({ description: 'Product ID', example: 'product-uuid' })
  @IsNotEmpty()
  @IsString()
  product_id: string;

  @ApiProperty({ description: 'Quantity', example: 2, minimum: 1 })
  @IsNotEmpty()
  quantity: number;

  @ApiProperty({ description: 'Price per unit', example: 500.0, required: false })
  @IsOptional()
  price?: number;
}

export class CreateOrderDto {
  @ApiProperty({ description: 'Customer ID (optional)', required: false })
  @IsOptional()
  @IsString()
  customer_id?: string;

  @ApiProperty({ description: 'Seller ID (optional)', required: false })
  @IsOptional()
  @IsString()
  seller_id?: string;

  @ApiProperty({ description: 'Shipping address', required: false })
  @IsOptional()
  @IsString()
  shipping_address?: string;

  @ApiProperty({ description: 'Order items', type: [OrderItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[];
}

