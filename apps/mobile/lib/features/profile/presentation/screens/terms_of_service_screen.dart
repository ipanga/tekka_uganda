import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Terms of Service screen
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Terms of Service')),
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
                'Welcome to Tekka ("we," "our," or "us"). These Terms of Service ("Terms") govern your access to and use of the Tekka mobile application and related services (collectively, the "Service"). By accessing or using the Service, you agree to be bound by these Terms.\n\n'
                'Tekka is a consumer-to-consumer (C2C) marketplace platform that enables users in Uganda to buy and sell fashion items, including clothing, accessories, and related products.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Eligibility
          _SectionTitle(title: '2. Eligibility'),
          const _SectionContent(
            content:
                'To use the Service, you must:\n\n'
                '• Be at least 18 years old\n'
                '• Have the legal capacity to enter into binding contracts\n'
                '• Have a valid phone number for account verification\n'
                '• Be a resident of Uganda or have a valid Ugandan phone number\n'
                '• Not be prohibited from using the Service under applicable laws',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Account Registration
          _SectionTitle(title: '3. Account Registration'),
          const _SectionContent(
            content:
                'To access certain features of the Service, you must create an account. When creating an account, you agree to:\n\n'
                '• Provide accurate, current, and complete information\n'
                '• Maintain and promptly update your account information\n'
                '• Keep your account credentials secure and confidential\n'
                '• Notify us immediately of any unauthorized access\n'
                '• Accept responsibility for all activities under your account\n\n'
                'We reserve the right to suspend or terminate accounts that violate these Terms or contain false information.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // User Conduct
          _SectionTitle(title: '4. User Conduct'),
          const _SectionContent(
            content:
                'When using the Service, you agree NOT to:\n\n'
                '• Post false, misleading, or fraudulent listings\n'
                '• Sell counterfeit, stolen, or prohibited items\n'
                '• Harass, threaten, or abuse other users\n'
                '• Use the Service for illegal purposes\n'
                '• Attempt to manipulate prices or reviews\n'
                '• Create multiple accounts to circumvent restrictions\n'
                '• Share account credentials with third parties\n'
                '• Collect user data without consent\n'
                '• Interfere with the proper functioning of the Service',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Listings and Transactions
          _SectionTitle(title: '5. Listings and Transactions'),
          const _SectionContent(
            content:
                'As a Seller, you agree to:\n\n'
                '• Provide accurate descriptions and authentic photos of items\n'
                '• Disclose any defects, damage, or wear\n'
                '• Set fair and honest prices\n'
                '• Respond promptly to buyer inquiries\n'
                '• Complete transactions as agreed\n'
                '• Deliver items in the condition described\n\n'
                'As a Buyer, you agree to:\n\n'
                '• Read listings carefully before making offers\n'
                '• Communicate respectfully with sellers\n'
                '• Complete payment as agreed\n'
                '• Inspect items at meetup before completing purchase',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Prohibited Items
          _SectionTitle(title: '6. Prohibited Items'),
          const _SectionContent(
            content:
                'The following items are prohibited on Tekka:\n\n'
                '• Counterfeit or replica designer items\n'
                '• Stolen or illegally obtained goods\n'
                '• Weapons, drugs, or controlled substances\n'
                '• Hazardous materials\n'
                '• Items that infringe intellectual property rights\n'
                '• Adult content or explicit materials\n'
                '• Items prohibited by Ugandan law\n'
                '• Any items we determine to be inappropriate',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Fees
          _SectionTitle(title: '7. Fees and Payments'),
          const _SectionContent(
            content:
                'Tekka does not currently charge fees for listing or selling items. All transactions are conducted directly between buyers and sellers.\n\n'
                'We reserve the right to introduce fees in the future with prior notice. Users will be notified of any fee changes through the app or email.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Safety
          _SectionTitle(title: '8. Safety'),
          const _SectionContent(
            content:
                'Your safety is important to us. When meeting for transactions:\n\n'
                '• Meet in public, well-lit locations\n'
                '• Bring a friend or inform someone of your whereabouts\n'
                '• Inspect items thoroughly before payment\n'
                '• Use secure payment methods\n'
                '• Trust your instincts - if something feels wrong, leave\n\n'
                'Tekka is not responsible for any harm, loss, or damage arising from in-person meetings or transactions.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Intellectual Property
          _SectionTitle(title: '9. Intellectual Property'),
          const _SectionContent(
            content:
                'The Tekka name, logo, and all related graphics, icons, and service names are trademarks of Tekka. You may not use our trademarks without prior written permission.\n\n'
                'By posting content on Tekka, you grant us a non-exclusive, worldwide, royalty-free license to use, display, and distribute your content in connection with the Service.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Limitation of Liability
          _SectionTitle(title: '10. Limitation of Liability'),
          const _SectionContent(
            content:
                'TO THE MAXIMUM EXTENT PERMITTED BY LAW:\n\n'
                '• The Service is provided "AS IS" without warranties of any kind\n'
                '• We do not guarantee the quality, safety, or legality of listed items\n'
                '• We are not responsible for user conduct or transaction disputes\n'
                '• Our liability is limited to the amount you paid us (if any)\n'
                '• We are not liable for indirect, incidental, or consequential damages',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Dispute Resolution
          _SectionTitle(title: '11. Dispute Resolution'),
          const _SectionContent(
            content:
                'Disputes between users should be resolved directly between the parties. Tekka may, at its discretion, assist in mediating disputes but is under no obligation to do so.\n\n'
                'Any disputes with Tekka shall be resolved through binding arbitration in Kampala, Uganda, in accordance with Ugandan law.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Termination
          _SectionTitle(title: '12. Termination'),
          const _SectionContent(
            content:
                'We may suspend or terminate your account at any time for:\n\n'
                '• Violation of these Terms\n'
                '• Fraudulent or illegal activity\n'
                '• Conduct that harms other users or the platform\n'
                '• Extended periods of inactivity\n'
                '• Any reason at our sole discretion\n\n'
                'You may delete your account at any time through the app settings.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Changes to Terms
          _SectionTitle(title: '13. Changes to Terms'),
          const _SectionContent(
            content:
                'We may update these Terms from time to time. We will notify you of material changes through the app or email. Continued use of the Service after changes constitutes acceptance of the new Terms.',
          ),

          const SizedBox(height: AppSpacing.space6),

          // Contact
          _SectionTitle(title: '14. Contact Us'),
          const _SectionContent(
            content:
                'If you have questions about these Terms, please contact us:\n\n'
                'Email: support@tekka.ug\n'
                'Address: Kampala, Uganda',
          ),

          const SizedBox(height: AppSpacing.space8),

          // Agreement note
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    'By using Tekka, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
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
        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
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
