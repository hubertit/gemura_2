import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsEnum } from 'class-validator';

export enum NotificationType {
  INFO = 'info',
  SUCCESS = 'success',
  WARNING = 'warning',
  ERROR = 'error',
}

export class CreateNotificationDto {
  @ApiProperty({
    description: 'Notification title',
    example: 'New Sale Recorded',
  })
  @IsNotEmpty({ message: 'Title is required' })
  @IsString({ message: 'Title must be a string' })
  title: string;

  @ApiProperty({
    description: 'Notification message',
    example: 'A new sale of 120.5 liters has been recorded.',
  })
  @IsNotEmpty({ message: 'Message is required' })
  @IsString({ message: 'Message must be a string' })
  message: string;

  @ApiProperty({
    description: 'Notification type',
    enum: NotificationType,
    example: 'info',
    required: false,
  })
  @IsOptional()
  @IsEnum(NotificationType, { message: 'Type must be info, success, warning, or error' })
  type?: NotificationType;
}

