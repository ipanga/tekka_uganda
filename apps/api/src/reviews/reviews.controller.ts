import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
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
import { ReviewsService } from './reviews.service';
import { CreateReviewDto, UpdateReviewDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import * as Prisma from '@prisma/client';

@ApiTags('reviews')
@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Post()
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Create a review for a user' })
  @ApiResponse({ status: 201, description: 'Review created' })
  @ApiResponse({ status: 409, description: 'Already reviewed this user' })
  create(@CurrentUser() user: Prisma.User, @Body() dto: CreateReviewDto) {
    return this.reviewsService.create(user.id, dto);
  }

  @Get('user/:userId')
  @ApiOperation({ summary: 'Get reviews for a user' })
  @ApiQuery({
    name: 'type',
    required: false,
    enum: ['received', 'given'],
    description: 'Type of reviews',
  })
  @ApiQuery({ name: 'limit', required: false })
  @ApiQuery({ name: 'cursor', required: false })
  @ApiResponse({ status: 200, description: 'List of reviews' })
  findForUser(
    @Param('userId') userId: string,
    @Query('type') type?: 'received' | 'given',
    @Query('limit') limit?: number,
    @Query('cursor') cursor?: string,
  ) {
    return this.reviewsService.findForUser(userId, type, limit, cursor);
  }

  @Get('user/:userId/stats')
  @ApiOperation({ summary: 'Get review statistics for a user' })
  @ApiResponse({ status: 200, description: 'Review statistics' })
  getStats(@Param('userId') userId: string) {
    return this.reviewsService.getStats(userId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a specific review' })
  @ApiResponse({ status: 200, description: 'Review details' })
  @ApiResponse({ status: 404, description: 'Review not found' })
  findOne(@Param('id') id: string) {
    return this.reviewsService.findOne(id);
  }

  @Put(':id')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Update a review' })
  @ApiResponse({ status: 200, description: 'Review updated' })
  update(
    @Param('id') id: string,
    @CurrentUser() user: Prisma.User,
    @Body() dto: UpdateReviewDto,
  ) {
    return this.reviewsService.update(id, user.id, dto);
  }

  @Delete(':id')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a review' })
  @ApiResponse({ status: 204, description: 'Review deleted' })
  delete(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.reviewsService.delete(id, user.id);
  }

  @Post(':id/report')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Report a review' })
  @ApiResponse({ status: 200, description: 'Review reported' })
  report(
    @Param('id') id: string,
    @CurrentUser() user: Prisma.User,
    @Body('reason') reason: string,
  ) {
    return this.reviewsService.report(id, user.id, reason);
  }

  @Get('admin/list')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiOperation({ summary: 'Admin: Get all reviews' })
  @ApiQuery({ name: 'page', required: false })
  @ApiQuery({ name: 'limit', required: false })
  @ApiQuery({ name: 'search', required: false })
  @ApiResponse({ status: 200, description: 'List of reviews' })
  adminList(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('search') search?: string,
  ) {
    return this.reviewsService.adminList(page, limit, search);
  }

  @Delete('admin/:id')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, AdminGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Admin: Remove a review' })
  @ApiResponse({ status: 204, description: 'Review removed' })
  adminRemove(@Param('id') id: string) {
    return this.reviewsService.adminRemove(id);
  }
}
