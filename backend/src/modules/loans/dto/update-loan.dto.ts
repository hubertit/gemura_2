import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString, IsNumber, IsIn, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateLoanDto {
  @ApiProperty({
    description: 'Status: active or closed',
    enum: ['active', 'closed'],
    required: false,
  })
  @IsOptional()
  @IsString()
  @IsIn(['active', 'closed'])
  status?: string;

  @ApiProperty({
    description: 'Due date (YYYY-MM-DD)',
    required: false,
  })
  @IsOptional()
  @IsString()
  due_date?: string;

  @ApiProperty({
    description: 'Notes',
    required: false,
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
