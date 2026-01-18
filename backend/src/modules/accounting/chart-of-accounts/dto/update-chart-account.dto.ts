import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, IsBoolean } from 'class-validator';

export class UpdateChartAccountDto {
  @ApiProperty({ description: 'Account name', required: false })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiProperty({ description: 'Account type', required: false })
  @IsOptional()
  @IsString()
  account_type?: string;

  @ApiProperty({ description: 'Is active', required: false })
  @IsOptional()
  @IsBoolean()
  is_active?: boolean;
}

