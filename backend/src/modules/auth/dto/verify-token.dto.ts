import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty } from 'class-validator';

export class VerifyTokenDto {
  @ApiProperty({
    description: 'Authentication token to verify',
    example: 'token_1234567890_abcdef',
  })
  @IsString()
  @IsNotEmpty()
  token: string;
}

