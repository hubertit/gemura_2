import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsUUID } from 'class-validator';
import { InteractionType } from '@prisma/client';

export class CreateInteractionDto {
  @ApiProperty({ description: 'Post ID (optional if story_id provided)' })
  @IsOptional()
  @IsUUID()
  post_id?: string;

  @ApiProperty({ description: 'Story ID (optional if post_id provided)' })
  @IsOptional()
  @IsUUID()
  story_id?: string;

  @ApiProperty({ description: 'Interaction type', enum: InteractionType })
  @IsEnum(InteractionType)
  interaction_type: InteractionType;
}

