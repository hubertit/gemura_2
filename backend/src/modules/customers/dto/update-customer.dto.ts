import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNumber, IsOptional, IsEmail, Min } from 'class-validator';

export class UpdateCustomerDto {
  @ApiProperty({
    description: 'Customer account code',
    example: 'A_XYZ789',
  })
  @IsString()
  customer_account_code: string;

  @ApiProperty({
    description: 'Customer name',
    example: 'John Doe',
    required: false,
  })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiProperty({
    description: 'Phone number',
    example: '250788123456',
    required: false,
  })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiProperty({
    description: 'Email address',
    example: 'customer@example.com',
    required: false,
  })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiProperty({
    description: 'National ID',
    example: '1199887766554433',
    required: false,
  })
  @IsString()
  @IsOptional()
  nid?: string;

  @ApiProperty({
    description: 'Address',
    example: 'Kigali, Rwanda',
    required: false,
  })
  @IsString()
  @IsOptional()
  address?: string;

  @ApiProperty({
    description: 'Price per liter',
    example: 400.0,
    minimum: 0,
    required: false,
  })
  @IsNumber()
  @IsOptional()
  @Min(0)
  price_per_liter?: number;

  @ApiProperty({
    description: 'Relationship status',
    enum: ['active', 'inactive'],
    example: 'active',
    required: false,
  })
  @IsString()
  @IsOptional()
  relationship_status?: 'active' | 'inactive';
}

