import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { ReportsService } from './reports.service';
import { CreateReportDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import * as Prisma from '@prisma/client';

@ApiTags('reports')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a report' })
  @ApiResponse({ status: 201, description: 'Report created' })
  @ApiResponse({ status: 400, description: 'Invalid request' })
  @ApiResponse({ status: 409, description: 'Already reported' })
  create(@CurrentUser() user: Prisma.User, @Body() dto: CreateReportDto) {
    return this.reportsService.create(user.id, dto);
  }

  @Get('check')
  @ApiOperation({ summary: 'Check if user has reported another user' })
  @ApiQuery({ name: 'reportedUserId', required: true })
  @ApiResponse({ status: 200, description: 'Returns hasReported boolean' })
  async checkReported(
    @CurrentUser() user: Prisma.User,
    @Query('reportedUserId') reportedUserId: string,
  ) {
    const hasReported = await this.reportsService.hasReported(
      user.id,
      reportedUserId,
    );
    return { hasReported };
  }

  @Get('my-reports')
  @ApiOperation({ summary: 'Get reports submitted by current user' })
  @ApiResponse({ status: 200, description: 'List of reports' })
  findMyReports(@CurrentUser() user: Prisma.User) {
    return this.reportsService.findByReporter(user.id);
  }
}
