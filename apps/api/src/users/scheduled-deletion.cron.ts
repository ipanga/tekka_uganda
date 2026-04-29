import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import { UsersService } from './users.service';

@Injectable()
export class ScheduledDeletionCronService {
  private readonly logger = new Logger(ScheduledDeletionCronService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly usersService: UsersService,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async finalizeDueDeletions(): Promise<void> {
    const now = new Date();
    const due = await this.prisma.scheduledDeletion.findMany({
      where: {
        status: 'PENDING',
        scheduledDate: { lte: now },
      },
      select: { id: true, userId: true },
    });

    if (due.length === 0) {
      this.logger.log('No scheduled deletions due for finalization.');
      return;
    }

    this.logger.log(`Finalizing ${due.length} scheduled deletion(s)...`);

    let succeeded = 0;
    let failed = 0;

    for (const row of due) {
      try {
        await this.usersService.deleteAccountImmediately(row.userId);
        succeeded++;
      } catch (err: any) {
        failed++;
        this.logger.error(
          `Failed to finalize scheduled deletion ${row.id} (user ${row.userId}): ${err?.message ?? err}`,
        );
      }
    }

    this.logger.log(
      `Scheduled-deletion finalization complete: ${succeeded} succeeded, ${failed} failed.`,
    );
  }
}
