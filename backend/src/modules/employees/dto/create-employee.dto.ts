import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsEnum, IsUUID } from 'class-validator';

export class CreateEmployeeDto {
  @ApiProperty({
    description: 'User ID to add as employee',
    example: 'user-uuid',
  })
  @IsNotEmpty({ message: 'User ID is required' })
  @IsUUID('4', { message: 'User ID must be a valid UUID' })
  user_id: string;

  @ApiProperty({
    description: 'Account ID to add employee to',
    example: 'account-uuid',
    required: false,
  })
  @IsOptional()
  @IsUUID('4', { message: 'Account ID must be a valid UUID' })
  account_id?: string;

  @ApiProperty({
    description: 'Employee role',
    enum: ['owner', 'admin', 'manager', 'accountant', 'collector', 'viewer', 'agent'],
    example: 'manager',
  })
  @IsNotEmpty({ message: 'Role is required' })
  @IsEnum(['owner', 'admin', 'manager', 'accountant', 'collector', 'viewer', 'agent'], { message: 'Invalid role' })
  role: string;

  @ApiProperty({
    description: 'Permission codes array',
    example: ['view_sales', 'create_sales'],
    required: false,
  })
  @IsOptional()
  permissions?: string[];
}

