import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, IsDateString, IsObject } from 'class-validator';

export class CreateApiKeyDto {
  @ApiProperty({ description: 'API key name/description' })
  @IsString()
  name: string;

  @ApiProperty({ description: 'Permissions (JSON object)', required: false })
  @IsOptional()
  @IsObject()
  permissions?: Record<string, any>;

  @ApiProperty({ description: 'Expiration date (ISO string)', required: false })
  @IsOptional()
  @IsDateString()
  expires_at?: string;
}

