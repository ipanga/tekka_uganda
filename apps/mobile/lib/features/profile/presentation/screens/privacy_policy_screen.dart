import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Privacy Policy screen
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          const SizedBox(height: AppSpacing.space4),

          // Last updated
          Text(
            'Last updated: January 2026',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Introduction
          _SectionTitle(title: '1. Introduction'),
          const _SectionContent(
            content:
                'Tekka ("we," "our," or "us") respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, store, and protect your information when you use the Tekka mobile application and related services.\n\n'
                'By using Tekka, you consent to the data practices described in this policy.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Information We Collect
          _SectionTitle(title: '2. Information We Collect'),
          const _SectionContent(
            content:
                'We collect the following types of information:\n\n'
                'Account Information:\n'
                '• Phone number (required for verification)\n'
                '• Display name and profile photo\n'
                '• Email address (optional, for verification)\n'
                '• Location (city/area)\n\n'
                'Identity Verification (if submitted):\n'
                '• Government ID type and number\n'
                '• Full legal name and date of birth\n'
                '• ID document photos\n\n'
                'Listing Information:\n'
                '• Product photos and descriptions\n'
                '• Pricing information\n'
                '• Category and condition details\n\n'
                'Usage Information:\n'
                '• Device information and identifiers\n'
                '• App usage patterns and preferences\n'
                '• Search history within the app\n'
                '• Communication logs between users',
          ),

          const SizedBox(height: AppSpacing.space6),

          // How We Use Your Information
          _SectionTitle(title: '3. How We Use Your Information'),
          const _SectionContent(
            content:
                'We use your information to:\n\n'
                '• Create and manage your account\n'
                '• Verify your identity and phone number\n'
                '• Enable buying and selling features\n'
                '• Facilitate communication between users\n'
                '• Improve our services and user experience\n'
                '• Send important notifications and updates\n'
                '• Detect and prevent fraud or abuse\n'
                '• Comply with legal obligations\n'
                '• Resolve disputes and enforce our policies',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Information Sharing
          _SectionTitle(title: '4. Information Sharing'),
          const _SectionContent(
            content:
                'We may share your information with:\n\n'
                'Other Users:\n'
                '• Your public profile (name, photo, location, listings)\n'
                '• Verification status badges\n'
                '• Reviews and ratings\n\n'
                'Service Providers:\n'
                '• Cloud hosting and storage providers\n'
                '• Analytics and monitoring services\n'
                '• Communication service providers\n\n'
                'Legal Requirements:\n'
                '• When required by law or legal process\n'
                '• To protect our rights and safety\n'
                '• To prevent fraud or illegal activity\n\n'
                'We do NOT sell your personal information to third parties.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Data Security
          _SectionTitle(title: '5. Data Security'),
          const _SectionContent(
            content:
                'We implement security measures to protect your data:\n\n'
                '• Encryption of data in transit and at rest\n'
                '• Secure authentication with OTP verification\n'
                '• Regular security audits and updates\n'
                '• Access controls and monitoring\n'
                '• Secure cloud infrastructure\n\n'
                'While we strive to protect your information, no system is completely secure. We cannot guarantee absolute security.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Data Retention
          _SectionTitle(title: '6. Data Retention'),
          const _SectionContent(
            content:
                'We retain your data for as long as:\n\n'
                '• Your account is active\n'
                '• Necessary to provide our services\n'
                '• Required by law or for legal claims\n\n'
                'When you delete your account:\n'
                '• Personal data is removed within 30 days\n'
                '• Some data may be retained for legal compliance\n'
                '• Anonymized data may be retained for analytics',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Your Rights
          _SectionTitle(title: '7. Your Rights'),
          const _SectionContent(
            content:
                'You have the right to:\n\n'
                '• Access your personal data\n'
                '• Correct inaccurate information\n'
                '• Delete your account and data\n'
                '• Export your data\n'
                '• Opt out of marketing communications\n'
                '• Control privacy settings\n\n'
                'To exercise these rights, visit Settings > Privacy or contact us at privacy@tekka.ug',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Privacy Settings
          _SectionTitle(title: '8. Privacy Controls'),
          const _SectionContent(
            content:
                'You can control your privacy through:\n\n'
                'Profile Visibility:\n'
                '• Public - visible to all users\n'
                '• Buyers Only - visible to past buyers\n'
                '• Private - limited visibility\n\n'
                'Information Sharing:\n'
                '• Show/hide location\n'
                '• Show/hide phone number\n'
                '• Show/hide online status\n'
                '• Control who can message you\n\n'
                'Access these settings in Settings > Privacy.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Children's Privacy
          _SectionTitle(title: "9. Children's Privacy"),
          const _SectionContent(
            content:
                'Tekka is not intended for users under 18 years old. We do not knowingly collect personal information from children.\n\n'
                'If we become aware that we have collected data from a child, we will delete it promptly.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // International Data
          _SectionTitle(title: '10. Data Location'),
          const _SectionContent(
            content:
                'Your data is primarily stored and processed in servers located in secure cloud facilities. By using Tekka, you consent to the transfer and processing of your data as described in this policy.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Cookies and Tracking
          _SectionTitle(title: '11. Analytics and Tracking'),
          const _SectionContent(
            content:
                'We use analytics tools to understand how users interact with our app. This includes:\n\n'
                '• Crash reports and error logs\n'
                '• Feature usage statistics\n'
                '• Performance monitoring\n\n'
                'This data is used to improve the app and is not used for advertising.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Changes to Policy
          _SectionTitle(title: '12. Changes to This Policy'),
          const _SectionContent(
            content:
                'We may update this Privacy Policy from time to time. We will notify you of significant changes through:\n\n'
                '• In-app notifications\n'
                '• Email (if provided)\n'
                '• Updated "Last modified" date\n\n'
                'Continued use after changes constitutes acceptance of the updated policy.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Contact
          _SectionTitle(title: '13. Contact Us'),
          const _SectionContent(
            content:
                'For privacy-related questions or concerns:\n\n'
                'Email: privacy@tekka.ug\n'
                'Address: Kampala, Uganda\n\n'
                'We will respond to your inquiry within 30 days.',
          ),

          const SizedBox(height: AppSpacing.space8),

          // Privacy note
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    'Your privacy matters to us. We are committed to being transparent about our data practices and giving you control over your information.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space10),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionContent extends StatelessWidget {
  final String content;

  const _SectionContent({required this.content});

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.onSurface,
        height: 1.6,
      ),
    );
  }
}
