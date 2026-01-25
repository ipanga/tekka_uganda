import {
  Controller,
  Get,
  Put,
  Delete,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { PriceAlertsService } from './price-alerts.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import * as Prisma from '@prisma/client';

@ApiTags('price-alerts')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('price-alerts')
export class PriceAlertsController {
  constructor(private readonly priceAlertsService: PriceAlertsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all price alerts for current user' })
  @ApiQuery({ name: 'limit', required: false })
  @ApiResponse({ status: 200, description: 'List of price alerts' })
  findAll(@CurrentUser() user: Prisma.User, @Query('limit') limit?: number) {
    return this.priceAlertsService.findAll(user.id, limit);
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Get unread price alerts count' })
  @ApiResponse({ status: 200, description: 'Unread count' })
  async getUnreadCount(@CurrentUser() user: Prisma.User) {
    const count = await this.priceAlertsService.getUnreadCount(user.id);
    return { unreadCount: count };
  }

  @Put(':id/read')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark a price alert as read' })
  @ApiResponse({ status: 200, description: 'Alert marked as read' })
  markAsRead(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.priceAlertsService.markAsRead(id, user.id);
  }

  @Put('read-all')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark all price alerts as read' })
  @ApiResponse({ status: 200, description: 'All alerts marked as read' })
  markAllAsRead(@CurrentUser() user: Prisma.User) {
    return this.priceAlertsService.markAllAsRead(user.id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a price alert' })
  @ApiResponse({ status: 204, description: 'Alert deleted' })
  delete(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.priceAlertsService.delete(id, user.id);
  }

  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete all price alerts' })
  @ApiResponse({ status: 204, description: 'All alerts deleted' })
  deleteAll(@CurrentUser() user: Prisma.User) {
    return this.priceAlertsService.deleteAll(user.id);
  }
}
