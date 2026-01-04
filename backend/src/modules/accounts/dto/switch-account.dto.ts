import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class SwitchAccountDto {
  @ApiProperty({
    description: 'Account ID to switch to',
    example: 'uuid-here',
  })
  @IsNotEmpty()
  @IsString()
  account_id: string;
}

