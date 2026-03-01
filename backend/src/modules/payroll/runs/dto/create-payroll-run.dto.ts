import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, IsUUID, IsDateString, IsNumber, Min, Max } from 'class-validator';
import { IsNotFutureDate } from '../../../../common/validators/not-future-date.validator';

export class CreatePayrollRunDto {
  @ApiProperty({ description: 'Period ID (optional - for flexible payroll)', required: false })
  @IsOptional()
  @IsUUID()
  period_id?: string;

  @ApiProperty({ description: 'Run date (must not be in the future)', example: '2025-01-31', required: false })
  @IsOptional()
  @IsDateString()
  @IsNotFutureDate({ message: 'Run date must not be in the future' })
  run_date?: string;

  @ApiProperty({ description: 'Period start date (must not be in the future)', example: '2025-01-01', required: false })
  @IsOptional()
  @IsDateString()
  @IsNotFutureDate({ message: 'Period start must not be in the future' })
  period_start?: string;

  @ApiProperty({ description: 'Period end date (must not be in the future)', example: '2025-01-31', required: false })
  @IsOptional()
  @IsDateString()
  @IsNotFutureDate({ message: 'Period end must not be in the future' })
  period_end?: string;

  @ApiProperty({ description: 'Payment terms in days (default 15, but flexible)', example: 15, required: false, minimum: 1, maximum: 90 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(90)
  payment_terms_days?: number;
}
