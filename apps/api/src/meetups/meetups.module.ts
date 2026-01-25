import { Module } from '@nestjs/common';
import { MeetupsController } from './meetups.controller';
import { MeetupsService } from './meetups.service';
import { PrismaModule } from '../prisma/prisma.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [PrismaModule, NotificationsModule, AuthModule],
  controllers: [MeetupsController],
  providers: [MeetupsService],
  exports: [MeetupsService],
})
export class MeetupsModule {}
