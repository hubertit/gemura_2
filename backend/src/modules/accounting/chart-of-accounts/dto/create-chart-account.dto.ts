import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsUUID } from 'class-validator';

export class CreateChartAccountDto {
  @ApiProperty({ description: 'Account code', example: '1000' })
  @IsNotEmpty()
  @IsString()
  code: string;

  @ApiProperty({ description: 'Account name', example: 'Cash' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ description: 'Account type', example: 'Asset' })
  @IsNotEmpty()
  @IsString()
  account_type: string;

  @ApiProperty({ description: 'Parent account ID', required: false })
  @IsOptional()
  @IsUUID()
  parent_id?: string;
}

