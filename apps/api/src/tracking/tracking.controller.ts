import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import * as Prisma from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';
import { CategoryViewDto } from './dto/tracking.dto';
import { TrackingService } from './tracking.service';

@ApiTags('tracking')
@Controller('tracking')
export class TrackingController {
  constructor(private readonly tracking: TrackingService) {}

  /**
   * Best-effort beacon fired by clients when the viewer lands on a
   * category page. Returns 204 for both authed and guest sessions —
   * guests just no-op (the affinity table only has signal for logged-in
   * users; PR5b reads it back when ranking the "For You" surface).
   *
   * Tracking failures are swallowed inside the service, so a flaky DB
   * never breaks the user's navigation.
   */
  @Post('category-view')
  @UseGuards(OptionalJwtAuthGuard)
  @HttpCode(204)
  @ApiOperation({
    summary: 'Record a category-view affinity event for the viewer.',
  })
  async categoryView(
    @CurrentUser() user: Prisma.User | null,
    @Body() dto: CategoryViewDto,
  ): Promise<void> {
    if (user) {
      await this.tracking.recordCategoryView(user.id, dto.categoryId);
    }
  }
}
