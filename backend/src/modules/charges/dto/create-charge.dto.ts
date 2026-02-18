import { ApiProperty } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsString,
  IsNumber,
  IsOptional,
  IsIn,
  IsBoolean,
  IsArray,
  IsUUID,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateChargeDto {
  @ApiProperty({
    description: 'Account ID (optional). Uses default account if omitted.',
    required: false,
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsOptional()
  @IsUUID()
  account_id?: string;

  @ApiProperty({ description: 'Charge name', example: 'Transport fee' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ description: 'Optional description', required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({
    description: 'Charge kind: one_time or recurring',
    enum: ['one_time', 'recurring'],
  })
  @IsNotEmpty()
  @IsString()
  @IsIn(['one_time', 'recurring'])
  kind: string;

  @ApiProperty({
    description: 'Amount type: fixed or percentage',
    enum: ['fixed', 'percentage'],
  })
  @IsNotEmpty()
  @IsString()
  @IsIn(['fixed', 'percentage'])
  amount_type: string;

  @ApiProperty({
    description: 'Fixed amount (RWF) or percentage (e.g. 5 for 5%)',
    example: 500,
    minimum: 0,
  })
  @IsNotEmpty()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(999_999_999.99)
  amount: number;

  @ApiProperty({
    description: 'For recurring: monthly or per_payroll',
    enum: ['monthly', 'per_payroll'],
    required: false,
  })
  @IsOptional()
  @IsString()
  @IsIn(['monthly', 'per_payroll'])
  recurrence?: string;

  @ApiProperty({
    description: 'Apply to all suppliers (true) or only selected (false)',
    default: true,
  })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  apply_to_all_suppliers?: boolean;

  @ApiProperty({
    description: 'When apply_to_all_suppliers is false: list of supplier account IDs',
    type: [String],
    required: false,
  })
  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  supplier_account_ids?: string[];

  @ApiProperty({
    description: 'Effective from date (YYYY-MM-DD). Optional.',
    required: false,
  })
  @IsOptional()
  @IsString()
  effective_from?: string;

  @ApiProperty({
    description: 'Effective to date (YYYY-MM-DD). Optional.',
    required: false,
  })
  @IsOptional()
  @IsString()
  effective_to?: string;

  @ApiProperty({ description: 'Active flag', default: true })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  is_active?: boolean;
}
