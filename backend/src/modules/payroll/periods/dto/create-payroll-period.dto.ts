import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsDateString } from 'class-validator';

export class CreatePayrollPeriodDto {
  @ApiProperty({ description: 'Period name', example: 'January 2025' })
  @IsNotEmpty()
  @IsString()
  period_name: string;

  @ApiProperty({ description: 'Start date', example: '2025-01-01' })
  @IsNotEmpty()
  @IsDateString()
  start_date: string;

  @ApiProperty({ description: 'End date', example: '2025-01-31' })
  @IsNotEmpty()
  @IsDateString()
  end_date: string;
}

