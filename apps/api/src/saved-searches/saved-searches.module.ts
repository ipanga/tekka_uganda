import { Module } from '@nestjs/common';
import { SavedSearchesController } from './saved-searches.controller';
import { SavedSearchesService } from './saved-searches.service';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [SavedSearchesController],
  providers: [SavedSearchesService],
  exports: [SavedSearchesService],
})
export class SavedSearchesModule {}
