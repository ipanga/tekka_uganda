import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { UploadService } from './upload.service';

@Injectable()
export class UploadCleanupService {
  private readonly logger = new Logger(UploadCleanupService.name);

  constructor(private readonly uploadService: UploadService) {}

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
      this.logger.log(
        `Cleanup complete: ${deleted} orphaned image(s) deleted`,
      );
    } catch (error) {
      this.logger.error(`Cleanup task failed: ${error.message}`);
    }
  }
}
