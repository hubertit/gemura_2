import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, IsUUID, IsDateString, IsNumber, Min, Max } from 'class-validator';

export class CreatePayrollRunDto {
  @ApiProperty({ description: 'Period ID (optional - for flexible payroll)', required: false })
  @IsOptional()
  @IsUUID()
  period_id?: string;

  @ApiProperty({ description: 'Run date', example: '2025-01-31', required: false })
  @IsOptional()
  @IsDateString()
  run_date?: string;

  @ApiProperty({ description: 'Period start date (for milk sales)', example: '2025-01-01', required: false })
  @IsOptional()
  @IsDateString()
  period_start?: string;

  @ApiProperty({ description: 'Period end date (for milk sales)', example: '2025-01-31', required: false })
  @IsOptional()
  @IsDateString()
  period_end?: string;

  @ApiProperty({ description: 'Payment terms in days (default 15, but flexible)', example: 15, required: false, minimum: 1, maximum: 90 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(90)
  payment_terms_days?: number;
}
