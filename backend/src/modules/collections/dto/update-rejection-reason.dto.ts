import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, IsInt, IsBoolean, Min } from 'class-validator';

export class UpdateRejectionReasonDto {
  @ApiProperty({
    description: 'Name of the rejection reason',
    example: 'Added Water',
    required: false,
  })
  @IsOptional()
  @IsString({ message: 'Name must be a string' })
  name?: string;

  @ApiProperty({
    description: 'Description of the rejection reason',
    example: 'Water was added to the milk',
    required: false,
  })
  @IsOptional()
  @IsString({ message: 'Description must be a string' })
  description?: string;

  @ApiProperty({
    description: 'Whether the rejection reason is active',
    example: true,
    required: false,
  })
  @IsOptional()
  @IsBoolean({ message: 'is_active must be a boolean' })
  is_active?: boolean;

  @ApiProperty({
    description: 'Sort order for display (lower numbers appear first)',
    example: 1,
    minimum: 0,
    required: false,
  })
  @IsOptional()
  @IsInt({ message: 'Sort order must be an integer' })
  @Min(0, { message: 'Sort order must be 0 or greater' })
  sort_order?: number;
}
