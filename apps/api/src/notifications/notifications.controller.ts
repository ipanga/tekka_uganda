import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  Body,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { SendNotificationDto, SendBulkNotificationDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import * as Prisma from '@prisma/client';

@ApiTags('notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  @ApiOperation({ summary: 'Get notifications for current user' })
  @ApiQuery({ name: 'limit', required: false })
  @ApiQuery({ name: 'cursor', required: false })
  @ApiResponse({ status: 200, description: 'List of notifications' })
  findAll(
    @CurrentUser() user: Prisma.User,
    @Query('limit') limit?: number,
    @Query('cursor') cursor?: string,
  ) {
    return this.notificationsService.findAllForUser(user.id, limit, cursor);
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Get unread notification count' })
  @ApiResponse({ status: 200, description: 'Unread count' })
  async getUnreadCount(@CurrentUser() user: Prisma.User) {
    const count = await this.notificationsService.getUnreadCount(user.id);
    return { count };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a specific notification' })
  @ApiResponse({ status: 200, description: 'Notification details' })
  findOne(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.notificationsService.findOne(id, user.id);
  }

  @Post(':id/read')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark notification as read' })
  @ApiResponse({ status: 200, description: 'Notification marked as read' })
  markAsRead(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.notificationsService.markAsRead(id, user.id);
  }

  @Post('read-all')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark all notifications as read' })
  @ApiResponse({ status: 200, description: 'All notifications marked as read' })
  markAllAsRead(@CurrentUser() user: Prisma.User) {
    return this.notificationsService.markAllAsRead(user.id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a notification' })
  @ApiResponse({ status: 204, description: 'Notification deleted' })
  delete(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.notificationsService.delete(id, user.id);
  }

  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete all notifications' })
  @ApiResponse({ status: 204, description: 'All notifications deleted' })
  deleteAll(@CurrentUser() user: Prisma.User) {
    return this.notificationsService.deleteAll(user.id);
  }

  // Admin endpoints
  @Post('admin/send')
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'Admin: Send notification to a user' })
  @ApiResponse({ status: 201, description: 'Notification sent' })
  adminSend(@Body() dto: SendNotificationDto) {
    return this.notificationsService.send(dto);
  }

  @Post('admin/send-bulk')
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'Admin: Send notification to multiple users' })
  @ApiResponse({ status: 201, description: 'Notifications sent' })
  adminSendBulk(@Body() dto: SendBulkNotificationDto) {
    return this.notificationsService.sendBulk(dto);
  }
}
