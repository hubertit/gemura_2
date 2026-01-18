import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, IsNumber } from 'class-validator';

export class UpdatePayrollRunDto {
  @ApiProperty({ description: 'Status', enum: ['draft', 'processing', 'completed', 'failed'], required: false })
  @IsOptional()
  @IsString()
  status?: string;

  @ApiProperty({ description: 'Total amount', required: false })
  @IsOptional()
  @IsNumber()
  total_amount?: number;
}

