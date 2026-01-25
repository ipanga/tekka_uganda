import { Module } from '@nestjs/common';
import { QuickRepliesController } from './quick-replies.controller';
import { QuickRepliesService } from './quick-replies.service';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [QuickRepliesController],
  providers: [QuickRepliesService],
  exports: [QuickRepliesService],
})
export class QuickRepliesModule {}
