import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { QuickRepliesService } from './quick-replies.service';
import {
  CreateQuickReplyDto,
  UpdateQuickReplyDto,
} from './dto/create-quick-reply.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import * as Prisma from '@prisma/client';

@Controller('quick-replies')
@UseGuards(JwtAuthGuard)
export class QuickRepliesController {
  constructor(private readonly quickRepliesService: QuickRepliesService) {}

  @Post()
  create(@CurrentUser() user: Prisma.User, @Body() dto: CreateQuickReplyDto) {
    return this.quickRepliesService.create(user.id, dto);
  }

  @Get()
  findAll(@CurrentUser() user: Prisma.User) {
    return this.quickRepliesService.findAll(user.id);
  }

  @Get(':id')
  findOne(@CurrentUser() user: Prisma.User, @Param('id') id: string) {
    return this.quickRepliesService.findOne(user.id, id);
  }

  @Put(':id')
  update(
    @CurrentUser() user: Prisma.User,
    @Param('id') id: string,
    @Body() dto: UpdateQuickReplyDto,
  ) {
    return this.quickRepliesService.update(user.id, id, dto);
  }

  @Put(':id/usage')
  recordUsage(@CurrentUser() user: Prisma.User, @Param('id') id: string) {
    return this.quickRepliesService.recordUsage(user.id, id);
  }

  @Delete(':id')
  remove(@CurrentUser() user: Prisma.User, @Param('id') id: string) {
    return this.quickRepliesService.remove(user.id, id);
  }

  @Post('initialize')
  initializeDefaults(@CurrentUser() user: Prisma.User) {
    return this.quickRepliesService.initializeDefaults(user.id);
  }

  @Post('reset')
  resetToDefaults(@CurrentUser() user: Prisma.User) {
    return this.quickRepliesService.resetToDefaults(user.id);
  }
}
