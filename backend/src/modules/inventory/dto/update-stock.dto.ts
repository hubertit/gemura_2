import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsNotEmpty, Min, IsOptional, IsString } from 'class-validator';

export class UpdateStockDto {
  @ApiProperty({ description: 'New stock quantity', example: 150, minimum: 0 })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  stock_quantity: number;

  @ApiProperty({ description: 'Optional reason or notes for the stock change', example: 'New shipment received', required: false })
  @IsOptional()
  @IsString()
  notes?: string;
}
