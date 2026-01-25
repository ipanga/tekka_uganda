import {
  IsString,
  IsOptional,
  IsBoolean,
  IsEmail,
  MaxLength,
} from 'class-validator';

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  @MaxLength(50)
  displayName?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  bio?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  location?: string;

  @IsOptional()
  @IsString()
  photoUrl?: string;

  @IsOptional()
  @IsBoolean()
  isOnboardingComplete?: boolean;
}

export class UpdateUserSettingsDto {
  @IsOptional()
  @IsBoolean()
  priceAlertsEnabled?: boolean;

  @IsOptional()
  @IsString()
  language?: string;

  @IsOptional()
  @IsString()
  defaultLocation?: string;

  // Notification preferences
  @IsOptional()
  @IsBoolean()
  pushEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  emailEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  marketingEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  messageNotifications?: boolean;

  @IsOptional()
  @IsBoolean()
  offerNotifications?: boolean;

  @IsOptional()
  @IsBoolean()
  reviewNotifications?: boolean;

  @IsOptional()
  @IsBoolean()
  listingNotifications?: boolean;

  @IsOptional()
  @IsBoolean()
  systemNotifications?: boolean;

  @IsOptional()
  @IsBoolean()
  doNotDisturb?: boolean;

  @IsOptional()
  dndStartHour?: number;

  @IsOptional()
  dndEndHour?: number;

  // Security settings
  @IsOptional()
  @IsBoolean()
  pinEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  biometricEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  loginAlerts?: boolean;

  @IsOptional()
  @IsBoolean()
  requireTransactionConfirmation?: boolean;

  @IsOptional()
  transactionThreshold?: number;

  @IsOptional()
  @IsBoolean()
  twoFactorEnabled?: boolean;
}

export class RegisterFcmTokenDto {
  @IsString()
  token: string;

  @IsString()
  platform: string; // android, ios, web
}

export class Setup2FADto {
  @IsString()
  method: 'sms' | 'authenticatorApp';
}

export class Verify2FACodeDto {
  @IsString()
  code: string;

  @IsString()
  method: 'sms' | 'authenticatorApp';
}

export class SubmitIdentityVerificationDto {
  @IsString()
  documentType: 'nationalId' | 'passport' | 'drivingLicense';

  @IsString()
  documentNumber: string;

  @IsString()
  fullName: string;

  @IsString()
  dateOfBirth: string;

  @IsString()
  frontImageUrl: string;

  @IsOptional()
  @IsString()
  backImageUrl?: string;

  @IsOptional()
  @IsString()
  selfieUrl?: string;
}

export class SendEmailVerificationDto {
  @IsEmail()
  email: string;
}

export class VerifyEmailCodeDto {
  @IsString()
  code: string;
}

export class UpdatePrivacySettingsDto {
  @IsOptional()
  @IsString()
  profileVisibility?: 'public' | 'buyersOnly' | 'private';

  @IsOptional()
  @IsBoolean()
  showLocation?: boolean;

  @IsOptional()
  @IsBoolean()
  showPhoneNumber?: boolean;

  @IsOptional()
  @IsString()
  messagePermission?: 'everyone' | 'verifiedOnly' | 'noOne';

  @IsOptional()
  @IsBoolean()
  showOnlineStatus?: boolean;

  @IsOptional()
  @IsBoolean()
  showPurchaseHistory?: boolean;

  @IsOptional()
  @IsBoolean()
  showListingsCount?: boolean;

  @IsOptional()
  @IsBoolean()
  appearInSearch?: boolean;

  @IsOptional()
  @IsBoolean()
  allowProfileSharing?: boolean;
}
