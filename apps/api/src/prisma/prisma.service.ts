import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  constructor() {
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
    });
    const adapter = new PrismaPg(pool);

    super({
      adapter,
      log:
        process.env.NODE_ENV === 'development'
          ? ['query', 'info', 'warn', 'error']
          : ['error'],
    });
  }

  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }

  async cleanDatabase() {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('Cannot clean database in production');
    }

    // Delete in order respecting foreign key constraints
    const models = [
      'adminAction',
      'notification',
      'priceAlert',
      'savedSearch',
      'review',
      'meetup',
      'message',
      'chat',
      'savedItem',
      'quickReplyTemplate',
      'listing',
      'report',
      'blockedUser',
      'fcmToken',
      'user',
      'safeLocation',
    ];

    for (const model of models) {
      await (this as any)[model].deleteMany();
    }
  }
}
