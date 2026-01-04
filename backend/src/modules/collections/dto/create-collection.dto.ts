import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsNumber, IsOptional } from 'class-validator';

export class CreateCollectionDto {
  @ApiProperty({ description: 'Supplier account code', example: 'A_ABC123' })
  @IsNotEmpty()
  @IsString()
  supplier_account_code: string;

  @ApiProperty({ description: 'Quantity in liters', example: 120.5 })
  @IsNotEmpty()
  @IsNumber()
  quantity: number;

  @ApiProperty({ description: 'Collection status', example: 'pending' })
  @IsNotEmpty()
  @IsString()
  status: string;

  @ApiProperty({ description: 'Collection date/time', example: '2025-01-04 10:00:00' })
  @IsNotEmpty()
  @IsString()
  collection_at: string;

  @ApiProperty({ description: 'Notes (optional)', required: false })
  @IsOptional()
  @IsString()
  notes?: string;
}

