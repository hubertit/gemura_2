import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsDateString } from 'class-validator';
import { IsNotFutureDate } from '../../../../common/validators/not-future-date.validator';

export class CreatePayrollPeriodDto {
  @ApiProperty({ description: 'Period name', example: 'January 2025' })
  @IsNotEmpty()
  @IsString()
  period_name: string;

  @ApiProperty({ description: 'Start date (must not be in the future)', example: '2025-01-01' })
  @IsNotEmpty()
  @IsDateString()
  @IsNotFutureDate({ message: 'Start date must not be in the future' })
  start_date: string;

  @ApiProperty({ description: 'End date (must not be in the future)', example: '2025-01-31' })
  @IsNotEmpty()
  @IsDateString()
  @IsNotFutureDate({ message: 'End date must not be in the future' })
  end_date: string;
}

