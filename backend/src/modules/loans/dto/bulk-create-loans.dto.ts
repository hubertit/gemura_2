import { ApiProperty } from '@nestjs/swagger';
import { IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { CreateLoanDto } from './create-loan.dto';

export class BulkCreateLoansDto {
  @ApiProperty({
    description: 'Array of loans to create',
    type: [CreateLoanDto],
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateLoanDto)
  rows: CreateLoanDto[];
}
