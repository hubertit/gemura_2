import { ApiProperty } from '@nestjs/swagger';
import { IsUUID, IsNotEmpty, IsOptional, IsInt, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';

export class GetRepliesDto {
  @ApiProperty({
    description: 'Parent comment ID',
    example: 'comment-uuid',
  })
  @IsUUID()
  @IsNotEmpty()
  comment_id: string;

  @ApiProperty({
    description: 'Maximum number of replies to return',
    example: 20,
    default: 20,
    required: false,
    minimum: 1,
    maximum: 100,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;

  @ApiProperty({
    description: 'Number of replies to skip',
    example: 0,
    default: 0,
    required: false,
    minimum: 0,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  offset?: number;
}
