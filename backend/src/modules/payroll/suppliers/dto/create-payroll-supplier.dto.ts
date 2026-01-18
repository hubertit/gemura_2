import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsUUID, IsNumber, Min, Max } from 'class-validator';

export class CreatePayrollSupplierDto {
  @ApiProperty({ description: 'Supplier account ID', example: 'supplier-account-uuid' })
  @IsNotEmpty()
  @IsUUID()
  supplier_account_id: string;

  @ApiProperty({ description: 'Payment terms in days (default 15)', example: 15, required: false, minimum: 1, maximum: 90 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(90)
  payment_terms_days?: number;
}

