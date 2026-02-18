import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsBoolean, IsUUID } from 'class-validator';
import { Type } from 'class-transformer';

export class GetChargesDto {
  @ApiProperty({
    description: 'Account ID (UUID). Uses default account if omitted.',
    example: '550e8400-e29b-41d4-a716-446655440000',
    required: false,
  })
  @IsOptional()
  @IsUUID()
  account_id?: string;

  @ApiProperty({
    description: 'If true, return only active charges.',
    default: false,
    required: false,
  })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  active_only?: boolean;
}
