import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, IsEnum, IsArray, IsBoolean, MinLength, MaxLength } from 'class-validator';
import { WalletType } from '@prisma/client';

export class CreateWalletDto {
  @ApiProperty({
    description: 'Wallet name',
    example: 'Main Savings Wallet',
    minLength: 3,
    maxLength: 100,
  })
  @IsString()
  @MinLength(3)
  @MaxLength(100)
  name: string;

  @ApiProperty({
    description: 'Wallet type',
    enum: WalletType,
    example: 'regular',
  })
  @IsEnum(WalletType)
  type: WalletType;

  @ApiProperty({
    description: 'Whether this is a joint wallet',
    example: false,
    required: false,
  })
  @IsOptional()
  @IsBoolean()
  is_joint?: boolean;

  @ApiProperty({
    description: 'Wallet description',
    example: 'Primary wallet for daily transactions',
    required: false,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiProperty({
    description: 'List of joint wallet owner user IDs (required if is_joint is true)',
    example: ['user-uuid-1', 'user-uuid-2'],
    required: false,
    type: [String],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  joint_owners?: string[];

  @ApiProperty({
    description: 'Currency code',
    example: 'RWF',
    default: 'RWF',
    required: false,
  })
  @IsOptional()
  @IsString()
  currency?: string;
}
