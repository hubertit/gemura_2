import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsNumber, IsOptional } from 'class-validator';

export class CreateSupplierDto {
  @ApiProperty({
    description: 'Full name of the supplier',
    example: 'John Doe',
    required: true,
  })
  @IsNotEmpty({ message: 'Supplier name is required' })
  @IsString({ message: 'Supplier name must be a string' })
  name: string;

  @ApiProperty({
    description: 'Supplier phone number in Rwandan format (250XXXXXXXXX)',
    example: '250788123456',
    pattern: '^250[0-9]{9}$',
    required: true,
  })
  @IsNotEmpty({ message: 'Phone number is required' })
  @IsString({ message: 'Phone number must be a string' })
  phone: string;

  @ApiProperty({
    description: 'Price per liter of milk in RWF',
    example: 390.0,
    minimum: 0,
    required: true,
  })
  @IsNotEmpty({ message: 'Price per liter is required' })
  @IsNumber({}, { message: 'Price per liter must be a number' })
  price_per_liter: number;

  @ApiProperty({
    description: 'Supplier email address (optional)',
    example: 'supplier@example.com',
    required: false,
  })
  @IsOptional()
  @IsString({ message: 'Email must be a string' })
  email?: string;

  @ApiProperty({
    description: 'National ID number (optional)',
    example: '1199887766554433',
    required: false,
  })
  @IsOptional()
  @IsString({ message: 'National ID must be a string' })
  nid?: string;

  @ApiProperty({
    description: 'Physical address (optional)',
    example: 'Kigali, Rwanda',
    required: false,
  })
  @IsOptional()
  @IsString({ message: 'Address must be a string' })
  address?: string;
}

