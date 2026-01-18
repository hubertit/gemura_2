import { ApiProperty } from '@nestjs/swagger';
import { IsUUID, IsNotEmpty } from 'class-validator';

export class FollowUserDto {
  @ApiProperty({
    description: 'User ID to follow',
    example: 'user-uuid-to-follow',
  })
  @IsUUID()
  @IsNotEmpty()
  user_id: string;
}
