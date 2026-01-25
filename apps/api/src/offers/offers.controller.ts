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
import { OffersService } from './offers.service';
import { CreateOfferDto, UpdateOfferDto, CounterOfferDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import * as Prisma from '@prisma/client';
import { OfferStatus } from '@prisma/client';

@ApiTags('offers')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('offers')
export class OffersController {
  constructor(private readonly offersService: OffersService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new offer on a listing' })
  @ApiResponse({ status: 201, description: 'Offer created' })
  @ApiResponse({ status: 409, description: 'Already have active offer' })
  create(@CurrentUser() user: Prisma.User, @Body() dto: CreateOfferDto) {
    return this.offersService.create(user.id, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all offers for current user' })
  @ApiQuery({
    name: 'role',
    required: false,
    enum: ['buyer', 'seller', 'all'],
    description: 'Filter by role',
  })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: OfferStatus,
    description: 'Filter by status',
  })
  @ApiResponse({ status: 200, description: 'List of offers' })
  findAll(
    @CurrentUser() user: Prisma.User,
    @Query('role') role?: 'buyer' | 'seller' | 'all',
    @Query('status') status?: OfferStatus,
  ) {
    return this.offersService.findAllForUser(user.id, role, status);
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get offer statistics for current user' })
  @ApiResponse({ status: 200, description: 'Offer statistics' })
  getStats(@CurrentUser() user: Prisma.User) {
    return this.offersService.getStats(user.id);
  }

  @Get('listing/:listingId')
  @ApiOperation({ summary: 'Get all offers for a listing (seller only)' })
  @ApiResponse({ status: 200, description: 'List of offers' })
  findForListing(
    @Param('listingId') listingId: string,
    @CurrentUser() user: Prisma.User,
  ) {
    return this.offersService.findForListing(listingId, user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a specific offer' })
  @ApiResponse({ status: 200, description: 'Offer details' })
  @ApiResponse({ status: 404, description: 'Offer not found' })
  findOne(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.offersService.findOne(id, user.id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update an offer (buyer only)' })
  @ApiResponse({ status: 200, description: 'Offer updated' })
  update(
    @Param('id') id: string,
    @CurrentUser() user: Prisma.User,
    @Body() dto: UpdateOfferDto,
  ) {
    return this.offersService.update(id, user.id, dto);
  }

  @Post(':id/accept')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Accept an offer (seller only)' })
  @ApiResponse({ status: 200, description: 'Offer accepted' })
  accept(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.offersService.accept(id, user.id);
  }

  @Post(':id/reject')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reject an offer (seller only)' })
  @ApiResponse({ status: 200, description: 'Offer rejected' })
  reject(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.offersService.reject(id, user.id);
  }

  @Post(':id/counter')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Make a counter offer (seller only)' })
  @ApiResponse({ status: 200, description: 'Counter offer made' })
  counter(
    @Param('id') id: string,
    @CurrentUser() user: Prisma.User,
    @Body() dto: CounterOfferDto,
  ) {
    return this.offersService.counter(id, user.id, dto);
  }

  @Post(':id/accept-counter')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Accept a counter offer (buyer only)' })
  @ApiResponse({ status: 200, description: 'Counter offer accepted' })
  acceptCounter(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.offersService.acceptCounter(id, user.id);
  }

  @Post(':id/decline-counter')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Decline a counter offer (buyer only)' })
  @ApiResponse({ status: 200, description: 'Counter offer declined' })
  declineCounter(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.offersService.declineCounter(id, user.id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cancel an offer (buyer only)' })
  @ApiResponse({ status: 200, description: 'Offer cancelled' })
  cancel(@Param('id') id: string, @CurrentUser() user: Prisma.User) {
    return this.offersService.cancel(id, user.id);
  }
}
