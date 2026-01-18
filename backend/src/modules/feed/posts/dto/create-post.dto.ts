import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, IsUrl } from 'class-validator';

export class CreatePostDto {
  @ApiProperty({ description: 'Post content', required: false })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiProperty({ description: 'Media URL (image/video)', required: false })
  @IsOptional()
  @IsUrl()
  media_url?: string;

  @ApiProperty({ description: 'Hashtags (comma-separated or JSON)', required: false })
  @IsOptional()
  @IsString()
  hashtags?: string;

  @ApiProperty({ description: 'Location', required: false })
  @IsOptional()
  @IsString()
  location?: string;
}

