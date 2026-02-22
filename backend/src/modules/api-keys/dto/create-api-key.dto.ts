import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsDateString, IsArray, IsUUID, IsBoolean, IsInt, Min, Max } from 'class-validator';

export class CreateApiKeyDto {
  @ApiProperty({
    description: 'API key name for identification',
    example: 'Looker Studio Integration',
  })
  @IsString()
  name: string;

  @ApiPropertyOptional({
    description: 'Detailed description of the API key purpose',
    example: 'API key for Gahengeri MCC analytics dashboard in Looker Studio',
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    description: 'Account ID to scope this API key to. If not provided, uses your default account.',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsOptional()
  @IsUUID()
  account_id?: string;

  @ApiPropertyOptional({
    description: 'Create a platform-wide API key (admin only). If true, the key can access all accounts.',
    example: false,
    default: false,
  })
  @IsOptional()
  @IsBoolean()
  platform_wide?: boolean;

  @ApiPropertyOptional({
    description: 'Permission scopes for this API key',
    example: ['analytics:collections:read', 'analytics:sales:read', 'export:read'],
    type: [String],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  scopes?: string[];

  @ApiPropertyOptional({
    description: 'Rate limit (requests per hour)',
    example: 1000,
    default: 1000,
  })
  @IsOptional()
  @IsInt()
  @Min(100)
  @Max(100000)
  rate_limit?: number;

  @ApiPropertyOptional({
    description: 'Expiration date (ISO string). Defaults to 1 year from creation.',
    example: '2025-12-31T23:59:59Z',
  })
  @IsOptional()
  @IsDateString()
  expires_at?: string;
}

export class UpdateApiKeyDto {
  @ApiPropertyOptional({
    description: 'API key name',
    example: 'Updated API Key Name',
  })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({
    description: 'API key description',
    example: 'Updated description',
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    description: 'Permission scopes',
    type: [String],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  scopes?: string[];

  @ApiPropertyOptional({
    description: 'Whether the API key is active',
    example: true,
  })
  @IsOptional()
  @IsBoolean()
  is_active?: boolean;
}

