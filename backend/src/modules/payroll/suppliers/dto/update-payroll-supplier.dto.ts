import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsBoolean, Min, Max } from 'class-validator';

export class UpdatePayrollSupplierDto {
  @ApiProperty({ description: 'Payment terms in days', required: false, minimum: 1, maximum: 90 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(90)
  payment_terms_days?: number;

  @ApiProperty({ description: 'Is active', required: false })
  @IsOptional()
  @IsBoolean()
  is_active?: boolean;
}

