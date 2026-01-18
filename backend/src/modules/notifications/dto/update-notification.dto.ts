import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, IsEnum } from 'class-validator';

export enum NotificationStatus {
  UNREAD = 'unread',
  READ = 'read',
}

export class UpdateNotificationDto {
  @ApiProperty({
    description: 'Notification status',
    enum: NotificationStatus,
    example: 'read',
    required: false,
  })
  @IsOptional()
  @IsEnum(NotificationStatus, { message: 'Status must be read or unread' })
  status?: NotificationStatus;
}

