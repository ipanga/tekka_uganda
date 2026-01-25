import {
  Injectable,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateReportDto } from './dto';

@Injectable()
export class ReportsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Create a report
   */
  async create(reporterId: string, dto: CreateReportDto) {
    // Must report either a user or a listing
    if (!dto.reportedUserId && !dto.reportedListingId) {
      throw new BadRequestException(
        'Must specify either reportedUserId or reportedListingId',
      );
    }

    // Can't report yourself
    if (dto.reportedUserId === reporterId) {
      throw new BadRequestException('Cannot report yourself');
    }

    // Check for duplicate reports
    const existingReport = await this.prisma.report.findFirst({
      where: {
        reporterId,
        ...(dto.reportedUserId && { reportedUserId: dto.reportedUserId }),
        ...(dto.reportedListingId && {
          reportedListingId: dto.reportedListingId,
        }),
        status: 'PENDING',
      },
    });

    if (existingReport) {
      throw new ConflictException('You have already reported this');
    }

    // Create the report
    const report = await this.prisma.report.create({
      data: {
        reporterId,
        reportedUserId: dto.reportedUserId,
        reportedListingId: dto.reportedListingId,
        reason: dto.reason,
        description: dto.description,
      },
    });

    return report;
  }

  /**
   * Get reports by reporter
   */
  async findByReporter(reporterId: string) {
    return this.prisma.report.findMany({
      where: { reporterId },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Check if user has already reported another user
   */
  async hasReported(
    reporterId: string,
    reportedUserId: string,
  ): Promise<boolean> {
    const report = await this.prisma.report.findFirst({
      where: {
        reporterId,
        reportedUserId,
      },
    });
    return !!report;
  }
}
