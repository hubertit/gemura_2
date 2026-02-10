import { ApiProperty } from '@nestjs/swagger';
import { IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { CreateCustomerDto } from './create-customer.dto';

export class BulkCreateCustomersDto {
  @ApiProperty({
    description: 'Array of customers to create or update',
    type: [CreateCustomerDto],
    example: [
      { name: 'Customer One', phone: '250788111111', price_per_liter: 400 },
      { name: 'Customer Two', phone: '250788222222', email: 'two@example.com' },
    ],
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateCustomerDto)
  rows: CreateCustomerDto[];
}
