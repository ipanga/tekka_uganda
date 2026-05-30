import { Injectable, Logger } from '@nestjs/common';
import * as Sentry from '@sentry/nestjs';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Slow-upsert threshold for the Sentry breadcrumb. Matches the
 * `SLOW_RANKED_QUERY_MS = 500` convention from listings.service.ts so the
 * two cooperative breadcrumb categories use the same yardstick.
 */
const SLOW_AFFINITY_UPSERT_MS = 500;

/**
 * Default weights for the two v1 affinity signals. Centralised here so the
 * ranking SQL in PR5b knows where to come look when it needs to retune
 * (and so the spec can assert that save > view).
 */
export const AFFINITY_WEIGHT_CATEGORY_VIEW = 1.0;
export const AFFINITY_WEIGHT_SAVE = 2.0;

@Injectable()
export class TrackingService {
  private readonly logger = new Logger(TrackingService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Upsert the (userId, categoryId) affinity row, accumulating weight and
   * bumping the recency timestamp. Tracking failures must never surface to
   * the user, so this method catches every error, logs to Sentry, and
   * returns void instead of propagating.
   */
  async recordCategoryView(
    userId: string,
    categoryId: string,
    weight: number = AFFINITY_WEIGHT_CATEGORY_VIEW,
  ): Promise<void> {
    const start = Date.now();
    try {
      await this.prisma.userCategoryAffinity.upsert({
        where: { userId_categoryId: { userId, categoryId } },
        create: { userId, categoryId, weight, eventCount: 1 },
        update: {
          weight: { increment: weight },
          eventCount: { increment: 1 },
          lastSeenAt: new Date(),
        },
      });

      const ms = Date.now() - start;
      if (ms > SLOW_AFFINITY_UPSERT_MS) {
        Sentry.addBreadcrumb({
          category: 'tracking.affinityUpsert',
          level: 'warning',
          message: `slow affinity upsert: ${ms}ms`,
          // No userId / categoryId in the data — keep PII off the breadcrumb.
          data: { ms, weight },
        });
      }
    } catch (err) {
      // Tracking is best-effort. Report and swallow.
      Sentry.captureException(err, { tags: { area: 'tracking' } });
      this.logger.warn(
        `affinity upsert failed: ${err instanceof Error ? err.message : err}`,
      );
    }
  }

  /**
   * Save signal. Saves are a stronger intent than a category browse, so
   * we tilt the weight up. Centralized here so the weight constant has a
   * single source of truth.
   */
  async recordSaveSignal(userId: string, categoryId: string): Promise<void> {
    return this.recordCategoryView(userId, categoryId, AFFINITY_WEIGHT_SAVE);
  }
}
