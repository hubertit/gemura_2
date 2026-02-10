import { ApiProperty } from '@nestjs/swagger';
import { IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { CreateInventoryDto } from './create-inventory.dto';

export class BulkCreateInventoryDto {
  @ApiProperty({
    description: 'Array of inventory items to create',
    type: [CreateInventoryDto],
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateInventoryDto)
  rows: CreateInventoryDto[];
}
