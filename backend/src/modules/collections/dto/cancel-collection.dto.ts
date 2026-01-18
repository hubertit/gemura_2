import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty } from 'class-validator';

export class CancelCollectionDto {
  @ApiProperty({
    description: 'Collection ID to cancel',
    example: 'collection-uuid',
  })
  @IsString()
  @IsNotEmpty()
  collection_id: string;
}

