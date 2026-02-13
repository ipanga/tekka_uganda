import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { ListingsModule } from './listings/listings.module';
import { ChatsModule } from './chats/chats.module';
import { ReviewsModule } from './reviews/reviews.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ReportsModule } from './reports/reports.module';
import { MeetupsModule } from './meetups/meetups.module';
import { PriceAlertsModule } from './price-alerts/price-alerts.module';
import { SavedSearchesModule } from './saved-searches/saved-searches.module';
import { QuickRepliesModule } from './quick-replies/quick-replies.module';
import { UploadModule } from './upload/upload.module';
import { AdminModule } from './admin/admin.module';
import { CategoriesModule } from './categories/categories.module';
import { AttributesModule } from './attributes/attributes.module';
import { LocationsModule } from './locations/locations.module';

@Module({
  controllers: [AppController],
  providers: [AppService],
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    ScheduleModule.forRoot(),
    PrismaModule,
    AuthModule,
    UsersModule,
    ListingsModule,
    ChatsModule,
    ReviewsModule,
    NotificationsModule,
    ReportsModule,
    MeetupsModule,
    PriceAlertsModule,
    SavedSearchesModule,
    QuickRepliesModule,
    UploadModule,
    AdminModule,
    CategoriesModule,
    AttributesModule,
    LocationsModule,
  ],
})
export class AppModule {}
