import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, MinLength, MaxLength } from 'class-validator';

export class UseReferralCodeDto {
  @ApiProperty({
    description: 'Referral code to use',
    example: 'ABC12345',
    minLength: 4,
    maxLength: 20,
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(4)
  @MaxLength(20)
  referral_code: string;
}
