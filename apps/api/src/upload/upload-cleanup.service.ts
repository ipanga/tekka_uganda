import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { UploadService } from './upload.service';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Maximum number of archived-listing image batches the cron will purge
 * in a single pass. A safety circuit — a runaway query that wants to
 * delete thousands of images at once is almost always a bug and we'd
 * rather page an operator than silently destroy seller data.
 */
const ARCHIVED_CLEANUP_SAFETY_LIMIT = 100;

/** Cap on per-row retry attempts before the row is left for manual review. */
const MAX_RETRY_ATTEMPTS = 5;

@Injectable()
export class UploadCleanupService {
  private readonly logger = new Logger(UploadCleanupService.name);

  constructor(
    private readonly uploadService: UploadService,
    private readonly prisma: PrismaService,
  ) {}

  /**
   * Clean up temporary images older than 24 hours.
   * Runs daily at 2 AM.
   *
   * Targets images uploaded via /upload/image(s) that were never
   * claimed by a listing create/update operation.
   */
  @Cron(CronExpression.EVERY_DAY_AT_2AM)
  async cleanupTemporaryImages(): Promise<void> {
    this.logger.log('Starting cleanup of temporary Cloudinary images...');

    try {
      const deleted = await this.uploadService.cleanupTempImages(24);
      this.logger.log(`Cleanup complete: ${deleted} orphaned image(s) deleted`);
    } catch (error) {
      this.logger.error(`Cleanup task failed: ${error.message}`);
    }
  }

  /**
   * Daily at 4 AM: hard-delete Cloudinary images for listings that have
   * been archived past the retention window. The DB row stays for
   * history; only the media is purged. Configurable via
   * `ARCHIVED_LISTING_RETENTION_DAYS` (default 30).
   *
   * Refuses to run if more than ARCHIVED_CLEANUP_SAFETY_LIMIT listings
   * would be processed in one pass — that's almost always a bug.
   */
  @Cron(CronExpression.EVERY_DAY_AT_4AM)
  async cleanupArchivedListingImages(): Promise<void> {
    const retentionDays = Number(
      process.env.ARCHIVED_LISTING_RETENTION_DAYS ?? 30,
    );
    if (!Number.isFinite(retentionDays) || retentionDays < 1) {
      this.logger.warn(
        `Invalid ARCHIVED_LISTING_RETENTION_DAYS (${process.env.ARCHIVED_LISTING_RETENTION_DAYS}); skipping cleanup`,
      );
      return;
    }
    const cutoff = new Date(Date.now() - retentionDays * 86_400_000);

    this.logger.log(
      `Scanning ARCHIVED listings with archivedAt < ${cutoff.toISOString()} (retention ${retentionDays}d)`,
    );

    const due = await this.prisma.listing.findMany({
      where: {
        status: 'ARCHIVED',
        archivedAt: { lt: cutoff },
        OR: [
          { imageUrls: { isEmpty: false } },
          { imagePublicIds: { isEmpty: false } },
        ],
      },
      select: { id: true, imageUrls: true, imagePublicIds: true },
      take: ARCHIVED_CLEANUP_SAFETY_LIMIT + 1,
    });

    if (due.length > ARCHIVED_CLEANUP_SAFETY_LIMIT) {
      this.logger.error(
        `Archived cleanup refused: ${due.length} listings due, > safety limit ${ARCHIVED_CLEANUP_SAFETY_LIMIT}. Investigate before re-running.`,
      );
      return;
    }

    if (due.length === 0) {
      this.logger.log('No archived listings due for media cleanup');
      return;
    }

    let totalDeleted = 0;
    let totalFailed = 0;
    for (const listing of due) {
      try {
        const result =
          listing.imagePublicIds.length > 0
            ? await this.uploadService.deleteImagesByPublicIds(
                listing.imagePublicIds,
              )
            : await this.uploadService.deleteImagesByUrls(listing.imageUrls);

        totalDeleted += result.deleted;
        totalFailed += result.failed;

        // Clear the URLs/public_ids on the listing so the same row isn't
        // reprocessed next pass (status stays ARCHIVED for history).
        await this.prisma.listing.update({
          where: { id: listing.id },
          data: { imageUrls: [], imagePublicIds: [] },
        });
      } catch (error: any) {
        this.logger.error(
          `Failed to purge media for archived listing ${listing.id}: ${error?.message ?? error}`,
        );
      }
    }

    this.logger.log(
      `Archived listing cleanup: ${due.length} listings processed, ${totalDeleted} images deleted, ${totalFailed} failed`,
    );
  }

  /**
   * Hourly: retry Cloudinary deletes that previously failed. Exponential
   * backoff per row (2^attemptCount hours since last attempt). Rows past
   * MAX_RETRY_ATTEMPTS are left for manual review.
   */
  @Cron(CronExpression.EVERY_HOUR)
  async retryFailedDeletions(): Promise<void> {
    const candidates = await this.prisma.failedMediaDeletion.findMany({
      where: { attemptCount: { lt: MAX_RETRY_ATTEMPTS } },
      orderBy: { lastAttemptAt: 'asc' },
      take: 200,
    });

    if (candidates.length === 0) return;

    const now = Date.now();
    let succeeded = 0;
    let failed = 0;
    let skipped = 0;

    for (const row of candidates) {
      // Exponential backoff: 2^attemptCount hours since last attempt.
      const backoffMs = Math.pow(2, row.attemptCount) * 3_600_000;
      if (now - row.lastAttemptAt.getTime() < backoffMs) {
        skipped++;
        continue;
      }

      if (!row.publicId) {
        // URL-only rows can't be retried automatically (most often the
        // public_id couldn't be extracted in the first place). Bump
        // attemptCount so they age out naturally.
        await this.prisma.failedMediaDeletion.update({
          where: { id: row.id },
          data: {
            attemptCount: row.attemptCount + 1,
            lastAttemptAt: new Date(),
            lastError: 'no public_id; manual review required',
          },
        });
        failed++;
        continue;
      }

      const result = await this.uploadService.destroyResourceRaw(row.publicId);
      if (result.success) {
        await this.prisma.failedMediaDeletion.delete({ where: { id: row.id } });
        succeeded++;
      } else {
        await this.prisma.failedMediaDeletion.update({
          where: { id: row.id },
          data: {
            attemptCount: row.attemptCount + 1,
            lastAttemptAt: new Date(),
            lastError: (result.error ?? 'unknown').slice(0, 500),
          },
        });
        failed++;
      }
    }

    this.logger.log(
      `Retry queue: ${succeeded} succeeded, ${failed} failed, ${skipped} skipped (backoff)`,
    );
  }
}
