import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty } from 'class-validator';

export class GetWalletDetailsDto {
  @ApiProperty({
    description: 'Wallet code to retrieve details for',
    example: 'W_ABC123',
  })
  @IsString()
  @IsNotEmpty()
  wallet_code: string;
}
