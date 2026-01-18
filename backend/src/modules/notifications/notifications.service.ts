import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateNotificationDto } from './dto/create-notification.dto';
import { UpdateNotificationDto } from './dto/update-notification.dto';

@Injectable()
export class NotificationsService {
  constructor(private prisma: PrismaService) {}

  async createNotification(user: User, createDto: CreateNotificationDto) {
    const { title, message, type = 'info' } = createDto;

    const notification = await this.prisma.notification.create({
      data: {
        user_id: user.id,
        title,
        message,
        type: type as any,
        status: 'unread',
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Notification created successfully.',
      data: {
        id: notification.id,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        status: notification.status,
        created_at: notification.created_at,
      },
    };
  }

  async getNotifications(user: User) {
    const notifications = await this.prisma.notification.findMany({
      where: {
        user_id: user.id,
      },
      orderBy: {
        created_at: 'desc',
      },
      take: 100,
    });

    return {
      code: 200,
      status: 'success',
      message: 'Notifications fetched successfully.',
      data: notifications.map((n) => ({
        id: n.id,
        title: n.title,
        message: n.message,
        type: n.type,
        status: n.status,
        read_at: n.read_at,
        created_at: n.created_at,
      })),
    };
  }

  async updateNotification(user: User, notificationId: string, updateDto: UpdateNotificationDto) {
    const notification = await this.prisma.notification.findFirst({
      where: {
        id: notificationId,
        user_id: user.id,
      },
    });

    if (!notification) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Notification not found.',
      });
    }

    const updateData: any = {};
    if (updateDto.status) {
      updateData.status = updateDto.status as any;
      if (updateDto.status === 'read' && !notification.read_at) {
        updateData.read_at = new Date();
      }
    }

    const updated = await this.prisma.notification.update({
      where: { id: notificationId },
      data: updateData,
    });

    return {
      code: 200,
      status: 'success',
      message: 'Notification updated successfully.',
      data: {
        id: updated.id,
        status: updated.status,
        read_at: updated.read_at,
      },
    };
  }

  async deleteNotification(user: User, notificationId: string) {
    const notification = await this.prisma.notification.findFirst({
      where: {
        id: notificationId,
        user_id: user.id,
      },
    });

    if (!notification) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Notification not found.',
      });
    }

    await this.prisma.notification.delete({
      where: { id: notificationId },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Notification deleted successfully.',
    };
  }
}

