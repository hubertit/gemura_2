import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsEmail, IsOptional, IsEnum, IsObject, MinLength } from 'class-validator';
import { UserStatus, UserAccountType, UserAccountRole } from '@prisma/client';

export class UpdateUserDto {
  @ApiPropertyOptional({ example: 'John Doe Updated' })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional({ example: 'john.updated@example.com' })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({ example: '250788123456' })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional({ example: 'NewSecurePassword123!' })
  @IsString()
  @MinLength(6)
  @IsOptional()
  password?: string;

  @ApiPropertyOptional({ enum: UserAccountType })
  @IsEnum(UserAccountType)
  @IsOptional()
  account_type?: UserAccountType;

  @ApiPropertyOptional({ enum: UserStatus })
  @IsEnum(UserStatus)
  @IsOptional()
  status?: UserStatus;

  @ApiPropertyOptional({ enum: UserAccountRole })
  @IsEnum(UserAccountRole)
  @IsOptional()
  role?: UserAccountRole;

  @ApiPropertyOptional({ example: { manage_users: true, view_sales: true } })
  @IsObject()
  @IsOptional()
  permissions?: Record<string, boolean>;
}
