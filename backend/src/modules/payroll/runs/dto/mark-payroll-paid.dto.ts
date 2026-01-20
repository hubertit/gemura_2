import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsDateString, IsUUID } from 'class-validator';

export class MarkPayrollPaidDto {
  @ApiProperty({
    description: 'Payment date (YYYY-MM-DD). If not provided, uses current date.',
    required: false,
    example: '2026-01-19',
  })
  @IsOptional()
  @IsDateString()
  payment_date?: string;

  @ApiProperty({
    description: 'Optional: Specific payslip ID to mark as paid. If not provided, marks entire run as paid.',
    required: false,
    example: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  })
  @IsOptional()
  @IsUUID()
  payslip_id?: string;
}
