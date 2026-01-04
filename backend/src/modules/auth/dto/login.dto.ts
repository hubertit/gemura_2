import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class LoginDto {
  @ApiProperty({
    description: 'User identifier - can be email address or phone number',
    example: 'user@example.com',
    examples: {
      email: {
        value: 'user@example.com',
        description: 'Login with email address',
      },
      phone: {
        value: '250788123456',
        description: 'Login with phone number (Rwandan format)',
      },
    },
    required: true,
  })
  @IsNotEmpty({ message: 'Identifier is required' })
  @IsString({ message: 'Identifier must be a string' })
  identifier: string;

  @ApiProperty({
    description: 'User password',
    example: 'SecurePassword123!',
    minLength: 6,
    required: true,
  })
  @IsNotEmpty({ message: 'Password is required' })
  @IsString({ message: 'Password must be a string' })
  @MinLength(6, { message: 'Password must be at least 6 characters' })
  password: string;
}

