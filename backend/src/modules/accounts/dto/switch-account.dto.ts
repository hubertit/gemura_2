import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsUUID } from 'class-validator';

export class SwitchAccountDto {
  @ApiProperty({
    description: 'UUID of the account to set as default',
    example: '550e8400-e29b-41d4-a716-446655440000',
    format: 'uuid',
    required: true,
  })
  @IsNotEmpty({ message: 'Account ID is required' })
  @IsString({ message: 'Account ID must be a string (UUID)' })
  @IsUUID('4', { message: 'Account ID must be a valid UUID' })
  account_id: string;
}

