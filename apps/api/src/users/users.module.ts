import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { ScheduledDeletionCronService } from './scheduled-deletion.cron';
import { AuthModule } from '../auth/auth.module';
import { EmailModule } from '../email/email.module';

@Module({
  imports: [AuthModule, EmailModule],
  controllers: [UsersController],
  providers: [UsersService, ScheduledDeletionCronService],
  exports: [UsersService],
})
export class UsersModule {}
