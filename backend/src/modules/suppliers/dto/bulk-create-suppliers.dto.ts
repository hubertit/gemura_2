import { ApiProperty } from '@nestjs/swagger';
import { IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { CreateSupplierDto } from './create-supplier.dto';

export class BulkCreateSuppliersDto {
  @ApiProperty({
    description: 'Array of suppliers to create or update',
    type: [CreateSupplierDto],
    example: [
      { name: 'Supplier One', phone: '250788111111', price_per_liter: 390 },
      { name: 'Supplier Two', phone: '250788222222', price_per_liter: 400, email: 'two@example.com' },
    ],
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateSupplierDto)
  rows: CreateSupplierDto[];
}
