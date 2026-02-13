import {
  Controller,
  Get,
  Put,
  Post,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import * as Prisma from '@prisma/client';
import {
  UpdateUserDto,
  UpdateUserSettingsDto,
  RegisterFcmTokenDto,
  Setup2FADto,
  Verify2FACodeDto,
  SubmitIdentityVerificationDto,
  SendEmailVerificationDto,
  VerifyEmailCodeDto,
  UpdatePrivacySettingsDto,
} from './dto/update-user.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // Get current user's profile
  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMe(@CurrentUser() user: Prisma.User) {
    return this.usersService.getProfile(user.id);
  }

  // Update current user's profile
  @Put('me')
  @UseGuards(JwtAuthGuard)
  async updateMe(@CurrentUser() user: Prisma.User, @Body() dto: UpdateUserDto) {
    return this.usersService.update(user.id, dto);
  }

  // Update current user's settings
  @Put('me/settings')
  @UseGuards(JwtAuthGuard)
  async updateSettings(
    @CurrentUser() user: Prisma.User,
    @Body() dto: UpdateUserSettingsDto,
  ) {
    return this.usersService.updateSettings(user.id, dto);
  }

  // Get current user's stats
  @Get('me/stats')
  @UseGuards(JwtAuthGuard)
  async getMyStats(@CurrentUser() user: Prisma.User) {
    return this.usersService.getStats(user.id);
  }

  // Get current user's settings (including notification preferences)
  @Get('me/settings')
  @UseGuards(JwtAuthGuard)
  async getSettings(@CurrentUser() user: Prisma.User) {
    return this.usersService.getSettings(user.id);
  }

  // Register FCM token
  @Post('me/fcm-token')
  @UseGuards(JwtAuthGuard)
  async registerFcmToken(
    @CurrentUser() user: Prisma.User,
    @Body() dto: RegisterFcmTokenDto,
  ) {
    await this.usersService.registerFcmToken(user.id, dto);
    return { success: true };
  }

  // Remove FCM token
  @Delete('me/fcm-token/:token')
  @UseGuards(JwtAuthGuard)
  async removeFcmToken(
    @CurrentUser() user: Prisma.User,
    @Param('token') token: string,
  ) {
    await this.usersService.removeFcmToken(user.id, token);
    return { success: true };
  }

  // Get blocked users
  @Get('me/blocked')
  @UseGuards(JwtAuthGuard)
  async getBlockedUsers(@CurrentUser() user: Prisma.User) {
    return this.usersService.getBlockedUsers(user.id);
  }

  // Block a user
  @Post('me/blocked/:userId')
  @UseGuards(JwtAuthGuard)
  async blockUser(
    @CurrentUser() user: Prisma.User,
    @Param('userId') userId: string,
  ) {
    await this.usersService.blockUser(user.id, userId);
    return { success: true };
  }

  // Unblock a user
  @Delete('me/blocked/:userId')
  @UseGuards(JwtAuthGuard)
  async unblockUser(
    @CurrentUser() user: Prisma.User,
    @Param('userId') userId: string,
  ) {
    await this.usersService.unblockUser(user.id, userId);
    return { success: true };
  }

  // Get public profile of any user
  @Get(':userId')
  async getPublicProfile(@Param('userId') userId: string) {
    return this.usersService.getPublicProfile(userId);
  }

  // Get stats of any user
  @Get(':userId/stats')
  async getUserStats(@Param('userId') userId: string) {
    return this.usersService.getStats(userId);
  }

  // Get scheduled account deletion status
  @Get('me/deletion')
  @UseGuards(JwtAuthGuard)
  async getScheduledDeletion(@CurrentUser() user: Prisma.User) {
    return this.usersService.getScheduledDeletion(user.id);
  }

  // Schedule account deletion
  @Post('me/deletion')
  @UseGuards(JwtAuthGuard)
  async scheduleAccountDeletion(
    @CurrentUser() user: Prisma.User,
    @Body() dto: { reason: string; gracePeriodDays?: number },
  ) {
    return this.usersService.scheduleAccountDeletion(
      user.id,
      dto.reason,
      dto.gracePeriodDays,
    );
  }

  // Cancel scheduled account deletion
  @Delete('me/deletion')
  @UseGuards(JwtAuthGuard)
  async cancelScheduledDeletion(@CurrentUser() user: Prisma.User) {
    return this.usersService.cancelScheduledDeletion(user.id);
  }

  // Immediately delete account
  @Delete('me')
  @UseGuards(JwtAuthGuard)
  async deleteAccountImmediately(@CurrentUser() user: Prisma.User) {
    return this.usersService.deleteAccountImmediately(user.id);
  }

  // Get login sessions
  @Get('me/sessions')
  @UseGuards(JwtAuthGuard)
  async getLoginSessions(@CurrentUser() user: Prisma.User) {
    return this.usersService.getLoginSessions(user.id);
  }

  // Terminate a specific session
  @Delete('me/sessions/:sessionId')
  @UseGuards(JwtAuthGuard)
  async terminateSession(
    @CurrentUser() user: Prisma.User,
    @Param('sessionId') sessionId: string,
  ) {
    await this.usersService.terminateSession(user.id, sessionId);
    return { success: true };
  }

  // Sign out from all devices
  @Post('me/sessions/sign-out-all')
  @UseGuards(JwtAuthGuard)
  async signOutAllDevices(@CurrentUser() user: Prisma.User) {
    await this.usersService.signOutAllDevices(user.id);
    return { success: true };
  }

  // Get verification status
  @Get('me/verification-status')
  @UseGuards(JwtAuthGuard)
  async getVerificationStatus(@CurrentUser() user: Prisma.User) {
    return this.usersService.getVerificationStatus(user.id);
  }

  // 2FA Endpoints
  // Get 2FA status
  @Get('me/2fa')
  @UseGuards(JwtAuthGuard)
  async get2FAStatus(@CurrentUser() user: Prisma.User) {
    return this.usersService.get2FAStatus(user.id);
  }

  // Setup 2FA
  @Post('me/2fa/setup')
  @UseGuards(JwtAuthGuard)
  async setup2FA(@CurrentUser() user: Prisma.User, @Body() dto: Setup2FADto) {
    return this.usersService.setup2FA(user.id, dto.method);
  }

  // Send SMS code for 2FA
  @Post('me/2fa/send-sms')
  @UseGuards(JwtAuthGuard)
  async send2FASmsCode(@CurrentUser() user: Prisma.User) {
    return this.usersService.send2FASmsCode(user.id);
  }

  // Verify 2FA code
  @Post('me/2fa/verify')
  @UseGuards(JwtAuthGuard)
  async verify2FACode(
    @CurrentUser() user: Prisma.User,
    @Body() dto: Verify2FACodeDto,
  ) {
    return this.usersService.verify2FACode(user.id, dto.code, dto.method);
  }

  // Disable 2FA
  @Delete('me/2fa')
  @UseGuards(JwtAuthGuard)
  async disable2FA(@CurrentUser() user: Prisma.User) {
    return this.usersService.disable2FA(user.id);
  }

  // Regenerate backup codes
  @Post('me/2fa/backup-codes')
  @UseGuards(JwtAuthGuard)
  async regenerateBackupCodes(@CurrentUser() user: Prisma.User) {
    return this.usersService.regenerateBackupCodes(user.id);
  }

  // Identity Verification Endpoints
  // Get identity verification status
  @Get('me/identity-verification')
  @UseGuards(JwtAuthGuard)
  async getIdentityVerificationStatus(@CurrentUser() user: Prisma.User) {
    return this.usersService.getIdentityVerificationStatus(user.id);
  }

  // Submit identity verification
  @Post('me/identity-verification')
  @UseGuards(JwtAuthGuard)
  async submitIdentityVerification(
    @CurrentUser() user: Prisma.User,
    @Body() dto: SubmitIdentityVerificationDto,
  ) {
    return this.usersService.submitIdentityVerification(user.id, dto);
  }

  // Email Verification Endpoints
  // Send email verification code
  @Post('me/email-verification/send')
  @UseGuards(JwtAuthGuard)
  async sendEmailVerification(
    @CurrentUser() user: Prisma.User,
    @Body() dto: SendEmailVerificationDto,
  ) {
    return this.usersService.sendEmailVerificationCode(user.id, dto.email);
  }

  // Verify email code
  @Post('me/email-verification/verify')
  @UseGuards(JwtAuthGuard)
  async verifyEmailCode(
    @CurrentUser() user: Prisma.User,
    @Body() dto: VerifyEmailCodeDto,
  ) {
    return this.usersService.verifyEmailCode(user.id, dto.code);
  }

  // Remove email from account
  @Delete('me/email')
  @UseGuards(JwtAuthGuard)
  async removeEmail(@CurrentUser() user: Prisma.User) {
    return this.usersService.removeEmail(user.id);
  }

  // Privacy Settings Endpoints
  // Get privacy settings
  @Get('me/privacy')
  @UseGuards(JwtAuthGuard)
  async getPrivacySettings(@CurrentUser() user: Prisma.User) {
    return this.usersService.getPrivacySettings(user.id);
  }

  // Update privacy settings
  @Put('me/privacy')
  @UseGuards(JwtAuthGuard)
  async updatePrivacySettings(
    @CurrentUser() user: Prisma.User,
    @Body() dto: UpdatePrivacySettingsDto,
  ) {
    return this.usersService.updatePrivacySettings(user.id, dto);
  }

  // Get another user's privacy settings (for checking profile visibility)
  @Get(':userId/privacy')
  async getUserPrivacySettings(@Param('userId') userId: string) {
    return this.usersService.getPrivacySettings(userId);
  }

  // Check if current user can view target user's profile
  @Get('me/can-view/:targetUserId')
  @UseGuards(JwtAuthGuard)
  async canViewProfile(
    @CurrentUser() user: Prisma.User,
    @Param('targetUserId') targetUserId: string,
  ) {
    return this.usersService.canViewProfile(user.id, targetUserId);
  }

  // Check if current user can message target user
  @Get('me/can-message/:targetUserId')
  @UseGuards(JwtAuthGuard)
  async canMessageUser(
    @CurrentUser() user: Prisma.User,
    @Param('targetUserId') targetUserId: string,
  ) {
    return this.usersService.canMessageUser(user.id, targetUserId);
  }
}
