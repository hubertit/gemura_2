import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class CancelSaleDto {
  @ApiProperty({ description: 'Sale ID' })
  @IsNotEmpty()
  @IsString()
  sale_id: string;
}

