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
import { ChatsService } from './chats.service';
import { CreateChatDto, SendMessageDto, UpdateMessageDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import * as Prisma from '@prisma/client';

@ApiTags('chats')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('chats')
export class ChatsController {
  constructor(private readonly chatsService: ChatsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all chats for current user' })
  @ApiResponse({ status: 200, description: 'List of chats' })
  findAll(@CurrentUser() user: Prisma.User) {
    return this.chatsService.findAllForUser(user.id);
  }

  @Post()
  @ApiOperation({ summary: 'Create or get existing chat' })
  @ApiResponse({ status: 201, description: 'Chat created or found' })
  create(@CurrentUser() user: Prisma.User, @Body() dto: CreateChatDto) {
    return this.chatsService.findOrCreate(user.id, dto);
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Get total unread message count' })
  @ApiResponse({ status: 200, description: 'Unread count' })
  getUnreadCount(@CurrentUser() user: Prisma.User) {
    return this.chatsService.getUnreadCount(user.id);
  }

  @Get('search')
  @ApiOperation({ summary: 'Search messages across all chats' })
  @ApiQuery({ name: 'q', description: 'Search query' })
  @ApiQuery({ name: 'limit', required: false, description: 'Result limit' })
  @ApiResponse({ status: 200, description: 'Search results' })
  searchMessages(
    @CurrentUser() user: Prisma.User,
    @Query('q') query: string,
    @Query('limit') limit?: number,
  ) {
    return this.chatsService.searchMessages(user.id, query, limit);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a specific chat' })
  @ApiResponse({ status: 200, description: 'Chat details' })
  @ApiResponse({ status: 404, description: 'Chat not found' })
  findOne(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.chatsService.findOne(id, user.id);
  }

  @Get(':id/messages')
  @ApiOperation({ summary: 'Get messages for a chat' })
  @ApiQuery({
    name: 'cursor',
    required: false,
    description: 'Pagination cursor',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    description: 'Messages per page',
  })
  @ApiResponse({ status: 200, description: 'List of messages' })
  getMessages(
    @Param('id') id: string,
    @CurrentUser() user: Prisma.User,
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: number,
  ) {
    return this.chatsService.getMessages(id, user.id, cursor, limit);
  }

  @Post(':id/messages')
  @ApiOperation({ summary: 'Send a message in a chat' })
  @ApiResponse({ status: 201, description: 'Message sent' })
  sendMessage(
    @Param('id') id: string,
    @CurrentUser() user: Prisma.User,
    @Body() dto: SendMessageDto,
  ) {
    return this.chatsService.sendMessage(id, user.id, dto);
  }

  @Put(':id/read')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark all messages in chat as read' })
  @ApiResponse({ status: 200, description: 'Messages marked as read' })
  markAsRead(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.chatsService.markAsRead(id, user.id);
  }

  @Put(':id/archive')
  @ApiOperation({ summary: 'Archive a chat' })
  @ApiResponse({ status: 200, description: 'Chat archived' })
  archiveChat(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.chatsService.archiveChat(id, user.id);
  }

  @Put(':id/unarchive')
  @ApiOperation({ summary: 'Unarchive a chat' })
  @ApiResponse({ status: 200, description: 'Chat unarchived' })
  unarchiveChat(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.chatsService.unarchiveChat(id, user.id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a chat' })
  @ApiResponse({ status: 204, description: 'Chat deleted' })
  deleteChat(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.chatsService.deleteChat(id, user.id);
  }

  @Put('messages/:messageId')
  @ApiOperation({ summary: 'Edit a message' })
  @ApiResponse({ status: 200, description: 'Message updated' })
  updateMessage(
    @Param('messageId') messageId: string,
    @CurrentUser() user: Prisma.User,
    @Body() dto: UpdateMessageDto,
  ) {
    return this.chatsService.updateMessage(messageId, user.id, dto);
  }

  @Delete('messages/:messageId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a message' })
  @ApiResponse({ status: 204, description: 'Message deleted' })
  deleteMessage(
    @Param('messageId') messageId: string,
    @CurrentUser() user: Prisma.User,
  ) {
    return this.chatsService.deleteMessage(messageId, user.id);
  }
}
