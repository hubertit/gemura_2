import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, IsEnum } from 'class-validator';

export class UpdateEmployeeDto {
  @ApiProperty({
    description: 'New role for employee',
    enum: ['owner', 'admin', 'manager', 'collector', 'viewer'],
    example: 'admin',
    required: false,
  })
  @IsOptional()
  @IsEnum(['owner', 'admin', 'manager', 'collector', 'viewer'], { message: 'Invalid role' })
  role?: string;

  @ApiProperty({
    description: 'New permissions JSON object',
    example: { can_edit: true, can_view: true, can_manage: true },
    required: false,
  })
  @IsOptional()
  permissions?: any;

  @ApiProperty({
    description: 'Employee status',
    enum: ['active', 'inactive'],
    example: 'active',
    required: false,
  })
  @IsOptional()
  @IsEnum(['active', 'inactive'], { message: 'Status must be active or inactive' })
  status?: string;
}

