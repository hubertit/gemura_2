import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsInt, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @ApiProperty({
    description: 'User ID',
    example: 1,
  })
  @IsInt()
  @IsNotEmpty()
  user_id: number;

  @ApiProperty({
    description: '6-digit reset code received via SMS/email',
    example: '123456',
  })
  @IsString()
  @IsNotEmpty()
  reset_code: string;

  @ApiProperty({
    description: 'New password (minimum 6 characters)',
    example: 'NewSecurePassword123!',
    minLength: 6,
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  new_password: string;
}

