import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsNumber, IsOptional } from 'class-validator';

export class CreateSupplierDto {
  @ApiProperty({ description: 'Supplier name', example: 'John Doe' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ description: 'Supplier phone number', example: '250788123456' })
  @IsNotEmpty()
  @IsString()
  phone: string;

  @ApiProperty({ description: 'Price per liter', example: 390.0 })
  @IsNotEmpty()
  @IsNumber()
  price_per_liter: number;

  @ApiProperty({ description: 'Supplier email (optional)', required: false })
  @IsOptional()
  @IsString()
  email?: string;

  @ApiProperty({ description: 'National ID (optional)', required: false })
  @IsOptional()
  @IsString()
  nid?: string;

  @ApiProperty({ description: 'Address (optional)', required: false })
  @IsOptional()
  @IsString()
  address?: string;
}

