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
    enum: ['owner', 'admin', 'manager', 'collector', 'viewer'],
    example: 'manager',
  })
  @IsNotEmpty({ message: 'Role is required' })
  @IsEnum(['owner', 'admin', 'manager', 'collector', 'viewer'], { message: 'Invalid role' })
  role: string;

  @ApiProperty({
    description: 'Permissions JSON object',
    example: { can_edit: true, can_view: true, can_manage: false },
    required: false,
  })
  @IsOptional()
  permissions?: any;
}

