import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, IsDateString, IsNumber, IsArray, Min, Max } from 'class-validator';

export class GeneratePayrollDto {
  @ApiProperty({
    description: 'Account ID (MCC/branch) to generate payroll for. Must be the account currently selected in the UI. If omitted, uses user default.',
    example: '550e8400-e29b-41d4-a716-446655440000',
    required: false,
  })
  @IsOptional()
  @IsString()
  account_id?: string;

  @ApiProperty({ 
    description: 'Supplier account codes to include in payroll (optional - if not provided, all active suppliers are included)', 
    example: ['A_ABC123', 'A_XYZ789'],
    required: false,
    type: [String]
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  supplier_account_codes?: string[];

  @ApiProperty({ 
    description: 'Period start date (for milk sales)', 
    example: '2025-01-01', 
    required: true 
  })
  @IsDateString()
  period_start: string;

  @ApiProperty({ 
    description: 'Period end date (for milk sales)', 
    example: '2025-01-31', 
    required: true 
  })
  @IsDateString()
  period_end: string;

  @ApiProperty({ 
    description: 'Payment terms in days (default 15)', 
    example: 15, 
    required: false, 
    minimum: 1, 
    maximum: 90 
  })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(90)
  payment_terms_days?: number;

  @ApiProperty({
    description: 'Custom name for this payroll run (e.g. "Jan 1 – Jan 31, 2025"). Optional.',
    example: 'January 2025',
    required: false,
  })
  @IsOptional()
  @IsString()
  run_name?: string;
}
