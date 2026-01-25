import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Query,
  Body,
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
import { MeetupsService } from './meetups.service';
import { CreateMeetupDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import * as Prisma from '@prisma/client';

@ApiTags('meetups')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('meetups')
export class MeetupsController {
  constructor(private readonly meetupsService: MeetupsService) {}

  // Safe locations endpoints
  @Get('locations')
  @ApiOperation({ summary: 'Get safe meetup locations' })
  @ApiQuery({ name: 'city', required: false, description: 'Filter by city' })
  @ApiResponse({ status: 200, description: 'List of safe locations' })
  getSafeLocations(@Query('city') city?: string) {
    return this.meetupsService.getSafeLocations(city);
  }

  @Get('locations/:id')
  @ApiOperation({ summary: 'Get a specific safe location' })
  @ApiResponse({ status: 200, description: 'Location details' })
  @ApiResponse({ status: 404, description: 'Location not found' })
  getSafeLocation(@Param('id') id: string) {
    return this.meetupsService.getSafeLocation(id);
  }

  // Meetup endpoints
  @Post()
  @ApiOperation({ summary: 'Schedule a meetup' })
  @ApiResponse({ status: 201, description: 'Meetup created' })
  create(@CurrentUser() user: Prisma.User, @Body() dto: CreateMeetupDto) {
    return this.meetupsService.create(user.id, dto);
  }

  @Get('upcoming')
  @ApiOperation({ summary: 'Get upcoming meetups for current user' })
  @ApiResponse({ status: 200, description: 'List of upcoming meetups' })
  getUpcoming(@CurrentUser() user: Prisma.User) {
    return this.meetupsService.findUpcoming(user.id);
  }

  @Get('chat/:chatId')
  @ApiOperation({ summary: 'Get meetups for a chat' })
  @ApiResponse({ status: 200, description: 'List of meetups' })
  getForChat(
    @Param('chatId') chatId: string,
    @CurrentUser() user: Prisma.User,
  ) {
    return this.meetupsService.findForChat(chatId, user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a specific meetup' })
  @ApiResponse({ status: 200, description: 'Meetup details' })
  @ApiResponse({ status: 404, description: 'Meetup not found' })
  findOne(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.meetupsService.findOne(id, user.id);
  }

  @Put(':id/accept')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Accept a proposed meetup' })
  @ApiResponse({ status: 200, description: 'Meetup accepted' })
  accept(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.meetupsService.accept(id, user.id);
  }

  @Put(':id/decline')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Decline a proposed meetup' })
  @ApiResponse({ status: 200, description: 'Meetup declined' })
  decline(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.meetupsService.decline(id, user.id);
  }

  @Put(':id/cancel')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cancel a meetup' })
  @ApiResponse({ status: 200, description: 'Meetup cancelled' })
  cancel(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.meetupsService.cancel(id, user.id);
  }

  @Put(':id/complete')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark meetup as completed' })
  @ApiResponse({ status: 200, description: 'Meetup completed' })
  complete(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.meetupsService.complete(id, user.id);
  }

  @Put(':id/no-show')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark meetup as no-show' })
  @ApiResponse({ status: 200, description: 'Meetup marked as no-show' })
  noShow(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.meetupsService.noShow(id, user.id);
  }
}
