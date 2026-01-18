import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNumber, IsOptional, IsEnum, IsDateString, Min } from 'class-validator';
import { MilkSaleStatus } from '@prisma/client';

export class UpdateCollectionDto {
  @ApiProperty({
    description: 'Collection ID',
    example: 'collection-uuid',
  })
  @IsString()
  collection_id: string;

  @ApiProperty({
    description: 'Quantity of milk in liters',
    example: 120.5,
    minimum: 0,
    required: false,
  })
  @IsNumber()
  @IsOptional()
  @Min(0)
  quantity?: number;

  @ApiProperty({
    description: 'Collection status',
    enum: ['pending', 'accepted', 'rejected', 'cancelled'],
    example: 'accepted',
    required: false,
  })
  @IsEnum(['pending', 'accepted', 'rejected', 'cancelled'])
  @IsOptional()
  status?: MilkSaleStatus;

  @ApiProperty({
    description: 'Collection date and time',
    example: '2025-01-04T10:00:00Z',
    required: false,
  })
  @IsDateString()
  @IsOptional()
  collection_at?: string;

  @ApiProperty({
    description: 'Additional notes',
    example: 'Updated after verification',
    required: false,
  })
  @IsString()
  @IsOptional()
  notes?: string;
}

