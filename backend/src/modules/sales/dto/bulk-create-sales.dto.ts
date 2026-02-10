import { ApiProperty } from '@nestjs/swagger';
import { IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { CreateSaleDto } from './create-sale.dto';

export class BulkCreateSalesDto {
  @ApiProperty({
    description: 'Array of sales to create',
    type: [CreateSaleDto],
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateSaleDto)
  rows: CreateSaleDto[];
}
