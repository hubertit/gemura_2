import { ApiProperty } from '@nestjs/swagger';
import { IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { CreateCollectionDto } from './create-collection.dto';

export class BulkCreateCollectionsDto {
  @ApiProperty({
    description: 'Array of collections to create',
    type: [CreateCollectionDto],
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateCollectionDto)
  rows: CreateCollectionDto[];
}
