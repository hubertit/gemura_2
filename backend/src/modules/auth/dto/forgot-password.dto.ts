import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsEmail, IsOptional, ValidateIf } from 'class-validator';

export class ForgotPasswordDto {
  @ApiProperty({
    description: 'Phone number (required if email not provided)',
    example: '250788123456',
    required: false,
  })
  @ValidateIf((o) => !o.email)
  @IsString()
  phone?: string;

  @ApiProperty({
    description: 'Email address (required if phone not provided)',
    example: 'user@example.com',
    required: false,
  })
  @ValidateIf((o) => !o.phone)
  @IsEmail()
  email?: string;
}

