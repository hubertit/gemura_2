import { Controller, Post, Get, Put, Delete, Body, UseGuards, Param, HttpCode } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiBadRequestResponse, ApiUnauthorizedResponse, ApiNotFoundResponse, ApiParam } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateNotificationDto } from './dto/create-notification.dto';
import { UpdateNotificationDto } from './dto/update-notification.dto';

@ApiTags('Notifications')
@Controller('notifications')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Post()
  @ApiOperation({
    summary: 'Create notification',
    description: 'Create a new notification for the authenticated user.',
  })
  @ApiBody({
    type: CreateNotificationDto,
    description: 'Notification data',
    examples: {
      info: {
        summary: 'Info notification',
        value: {
          title: 'New Sale Recorded',
          message: 'A new sale of 120.5 liters has been recorded.',
          type: 'info',
        },
      },
      success: {
        summary: 'Success notification',
        value: {
          title: 'Payment Successful',
          message: 'Your payment of 50,000 RWF has been processed.',
          type: 'success',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Notification created successfully',
  })
  @ApiBadRequestResponse({ description: 'Invalid request' })
  @ApiUnauthorizedResponse({ description: 'Unauthorized' })
  async createNotification(@CurrentUser() user: User, @Body() createDto: CreateNotificationDto) {
    return this.notificationsService.createNotification(user, createDto);
  }

  @Post('get')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Get notifications',
    description: 'Retrieve all notifications for the authenticated user.',
  })
  @ApiResponse({
    status: 200,
    description: 'Notifications fetched successfully',
  })
  @ApiUnauthorizedResponse({ description: 'Unauthorized' })
  async getNotifications(@CurrentUser() user: User) {
    return this.notificationsService.getNotifications(user);
  }

  @Put(':id')
  @ApiOperation({
    summary: 'Update notification',
    description: 'Update notification status (mark as read/unread).',
  })
  @ApiParam({ name: 'id', description: 'Notification ID' })
  @ApiBody({ type: UpdateNotificationDto })
  @ApiResponse({
    status: 200,
    description: 'Notification updated successfully',
  })
  @ApiNotFoundResponse({ description: 'Notification not found' })
  @ApiUnauthorizedResponse({ description: 'Unauthorized' })
  async updateNotification(@CurrentUser() user: User, @Param('id') id: string, @Body() updateDto: UpdateNotificationDto) {
    return this.notificationsService.updateNotification(user, id, updateDto);
  }

  @Delete(':id')
  @ApiOperation({
    summary: 'Delete notification',
    description: 'Delete a notification.',
  })
  @ApiParam({ name: 'id', description: 'Notification ID' })
  @ApiResponse({
    status: 200,
    description: 'Notification deleted successfully',
  })
  @ApiNotFoundResponse({ description: 'Notification not found' })
  @ApiUnauthorizedResponse({ description: 'Unauthorized' })
  async deleteNotification(@CurrentUser() user: User, @Param('id') id: string) {
    return this.notificationsService.deleteNotification(user, id);
  }
}

