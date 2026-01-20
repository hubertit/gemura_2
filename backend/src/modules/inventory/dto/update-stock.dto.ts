import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsNotEmpty, Min } from 'class-validator';

export class UpdateStockDto {
  @ApiProperty({ description: 'New stock quantity', example: 150, minimum: 0 })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  stock_quantity: number;
}
