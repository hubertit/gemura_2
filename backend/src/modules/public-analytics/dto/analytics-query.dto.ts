import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsDateString, IsEnum, IsUUID, IsArray, IsInt, Min, Max } from 'class-validator';
import { Transform, Type } from 'class-transformer';

export enum GroupByPeriod {
  DAY = 'day',
  WEEK = 'week',
  MONTH = 'month',
  QUARTER = 'quarter',
  YEAR = 'year',
}

export enum ExportFormat {
  JSON = 'json',
  CSV = 'csv',
}

export class AnalyticsQueryDto {
  @ApiPropertyOptional({
    description: 'Start date for analytics period (ISO 8601 format)',
    example: '2024-01-01',
  })
  @IsOptional()
  @IsDateString()
  start_date?: string;

  @ApiPropertyOptional({
    description: 'End date for analytics period (ISO 8601 format)',
    example: '2024-12-31',
  })
  @IsOptional()
  @IsDateString()
  end_date?: string;

  @ApiPropertyOptional({
    description: 'Group results by time period',
    enum: GroupByPeriod,
    example: GroupByPeriod.MONTH,
  })
  @IsOptional()
  @IsEnum(GroupByPeriod)
  group_by?: GroupByPeriod;

  @ApiPropertyOptional({
    description: 'Specific account ID to query (only for platform-wide API keys)',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsOptional()
  @IsUUID()
  account_id?: string;

  @ApiPropertyOptional({
    description: 'Multiple account IDs to query (only for platform-wide API keys)',
    type: [String],
    example: ['550e8400-e29b-41d4-a716-446655440000'],
  })
  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      return value.split(',').map((id) => id.trim());
    }
    return value;
  })
  account_ids?: string[];

  @ApiPropertyOptional({
    description: 'Page number for pagination',
    example: 1,
    default: 1,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({
    description: 'Number of items per page',
    example: 100,
    default: 100,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(1000)
  limit?: number = 100;

  @ApiPropertyOptional({
    description: 'Export format',
    enum: ExportFormat,
    default: ExportFormat.JSON,
  })
  @IsOptional()
  @IsEnum(ExportFormat)
  format?: ExportFormat = ExportFormat.JSON;
}

export class AnalyticsResponseMeta {
  @ApiProperty({ description: 'Account ID (null for platform-wide)' })
  account_id: string | null;

  @ApiProperty({ description: 'Account name', required: false })
  account_name?: string;

  @ApiProperty({ description: 'Start date of the analytics period' })
  start_date: string;

  @ApiProperty({ description: 'End date of the analytics period' })
  end_date: string;

  @ApiProperty({ description: 'Timestamp when the report was generated' })
  generated_at: string;

  @ApiProperty({ description: 'API version', example: 'v1' })
  api_version: string;

  @ApiProperty({ description: 'Current page number', required: false })
  page?: number;

  @ApiProperty({ description: 'Items per page', required: false })
  limit?: number;

  @ApiProperty({ description: 'Total number of items', required: false })
  total?: number;
}

export class AnalyticsResponse<T> {
  @ApiProperty({ description: 'HTTP status code', example: 200 })
  code: number;

  @ApiProperty({ description: 'Response status', example: 'success' })
  status: 'success' | 'error';

  @ApiProperty({ description: 'Response message' })
  message: string;

  @ApiProperty({ description: 'Analytics data' })
  data: T;

  @ApiProperty({ description: 'Response metadata', type: AnalyticsResponseMeta })
  meta: AnalyticsResponseMeta;
}
