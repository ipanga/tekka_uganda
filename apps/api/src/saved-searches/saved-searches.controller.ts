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
} from '@nestjs/common';
import { SavedSearchesService } from './saved-searches.service';
import {
  CreateSavedSearchDto,
  UpdateSavedSearchDto,
} from './dto/create-saved-search.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import * as Prisma from '@prisma/client';

@Controller('saved-searches')
@UseGuards(JwtAuthGuard)
export class SavedSearchesController {
  constructor(private readonly savedSearchesService: SavedSearchesService) {}

  @Post()
  create(@CurrentUser() user: Prisma.User, @Body() dto: CreateSavedSearchDto) {
    return this.savedSearchesService.create(user.id, dto);
  }

  @Get()
  findAll(@CurrentUser() user: Prisma.User) {
    return this.savedSearchesService.findAll(user.id);
  }

  @Get('check')
  async isSearchSaved(
    @CurrentUser() user: Prisma.User,
    @Query('query') query: string,
  ) {
    const isSaved = await this.savedSearchesService.isSearchSaved(
      user.id,
      query,
    );
    return { isSaved };
  }

  @Get('with-matches/count')
  async getSearchesWithMatchesCount(@CurrentUser() user: Prisma.User) {
    const count = await this.savedSearchesService.getSearchesWithMatches(
      user.id,
    );
    return { count };
  }

  @Get(':id')
  findOne(@CurrentUser() user: Prisma.User, @Param('id') id: string) {
    return this.savedSearchesService.findOne(user.id, id);
  }

  @Put(':id')
  update(
    @CurrentUser() user: Prisma.User,
    @Param('id') id: string,
    @Body() dto: UpdateSavedSearchDto,
  ) {
    return this.savedSearchesService.update(user.id, id, dto);
  }

  @Put(':id/notifications')
  toggleNotifications(
    @CurrentUser() user: Prisma.User,
    @Param('id') id: string,
    @Body('enabled') enabled: boolean,
  ) {
    return this.savedSearchesService.toggleNotifications(user.id, id, enabled);
  }

  @Put(':id/clear-matches')
  clearNewMatches(@CurrentUser() user: Prisma.User, @Param('id') id: string) {
    return this.savedSearchesService.clearNewMatches(user.id, id);
  }

  @Delete(':id')
  remove(@CurrentUser() user: Prisma.User, @Param('id') id: string) {
    return this.savedSearchesService.remove(user.id, id);
  }

  @Delete()
  removeAll(@CurrentUser() user: Prisma.User) {
    return this.savedSearchesService.removeAll(user.id);
  }
}
