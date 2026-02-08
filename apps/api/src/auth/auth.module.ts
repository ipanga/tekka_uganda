import { Module, OnModuleInit } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { initializeFirebase } from './firebase-admin';
import { FirebaseAuthGuard } from './guards/firebase-auth.guard';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { AdminGuard, SuperAdminGuard } from './guards/admin.guard';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { OtpService } from './otp.service';
import { ThinkXCloudService } from './thinkxcloud.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [
    PrismaModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: {
          expiresIn: '7d',
        },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    ThinkXCloudService,
    OtpService,
    FirebaseAuthGuard,
    JwtAuthGuard,
    AdminGuard,
    SuperAdminGuard,
  ],
  exports: [
    AuthService,
    OtpService,
    FirebaseAuthGuard,
    JwtAuthGuard,
    AdminGuard,
    SuperAdminGuard,
    JwtModule,
  ],
})
export class AuthModule implements OnModuleInit {
  constructor(private configService: ConfigService) {}

  onModuleInit() {
    // Initialize Firebase for push notifications only
    try {
      initializeFirebase(this.configService);
    } catch (error) {
      console.warn(
        'Firebase initialization failed (push notifications will not work):',
        error,
      );
    }
  }
}
