import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, IsUrl } from 'class-validator';

export class CreateStoryDto {
  @ApiProperty({ description: 'Media URL (image/video)', required: true })
  @IsUrl()
  media_url: string;

  @ApiProperty({ description: 'Story content', required: false })
  @IsOptional()
  @IsString()
  content?: string;
}

