import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, IsDateString } from 'class-validator';

export class UpdateInvoiceDto {
  @ApiProperty({ description: 'Invoice status', enum: ['draft', 'sent', 'paid', 'overdue', 'cancelled'], required: false })
  @IsOptional()
  @IsString()
  status?: string;

  @ApiProperty({ description: 'Due date', required: false })
  @IsOptional()
  @IsDateString()
  due_date?: string;
}

