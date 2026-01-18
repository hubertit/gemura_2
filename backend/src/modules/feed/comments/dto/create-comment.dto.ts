import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsUUID } from 'class-validator';

export class CreateCommentDto {
  @ApiProperty({ description: 'Post ID' })
  @IsUUID()
  post_id: string;

  @ApiProperty({ description: 'Comment content' })
  @IsString()
  content: string;
}

