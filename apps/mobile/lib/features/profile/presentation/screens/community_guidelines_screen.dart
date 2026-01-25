import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Community Guidelines screen
class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Community Guidelines'),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          const SizedBox(height: AppSpacing.space4),

          // Introduction
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      'Building a Safe Community',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  'Tekka is a community of fashion lovers in Uganda. These guidelines help us maintain a safe, respectful, and enjoyable marketplace for everyone.',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Be Honest
          _GuidelineCard(
            icon: Icons.verified_outlined,
            title: 'Be Honest',
            color: AppColors.success,
            items: [
              'Use real photos of the actual items you are selling',
              'Accurately describe item condition, size, and any defects',
              'Be truthful about brands - do not sell counterfeits',
              'Set fair prices that reflect the item\'s true value',
              'Honor your commitments to buyers and sellers',
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Be Respectful
          _GuidelineCard(
            icon: Icons.favorite_outline,
            title: 'Be Respectful',
            color: AppColors.primary,
            items: [
              'Treat all users with courtesy and respect',
              'Communicate professionally in messages',
              'No harassment, bullying, or threatening behavior',
              'Respect different opinions and backgrounds',
              'Give constructive feedback in reviews',
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Be Safe
          _GuidelineCard(
            icon: Icons.shield_outlined,
            title: 'Be Safe',
            color: AppColors.warning,
            items: [
              'Meet in public, well-lit locations for exchanges',
              'Bring a friend or tell someone about your meetup',
              'Inspect items carefully before completing payment',
              'Never share personal financial information',
              'Trust your instincts - leave if something feels wrong',
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Be Legal
          _GuidelineCard(
            icon: Icons.gavel_outlined,
            title: 'Be Legal',
            color: AppColors.error,
            items: [
              'Only sell items you legally own or have permission to sell',
              'Do not sell stolen, counterfeit, or prohibited items',
              'Follow all applicable Ugandan laws and regulations',
              'Pay any required taxes on your sales',
              'Respect intellectual property and copyright',
            ],
          ),

          const SizedBox(height: AppSpacing.space6),

          // Prohibited Content
          Text(
            'Prohibited on Tekka',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          _ProhibitedItem(text: 'Counterfeit or replica items'),
          _ProhibitedItem(text: 'Stolen goods'),
          _ProhibitedItem(text: 'Weapons and dangerous items'),
          _ProhibitedItem(text: 'Drugs and controlled substances'),
          _ProhibitedItem(text: 'Adult or explicit content'),
          _ProhibitedItem(text: 'Hate speech or discriminatory content'),
          _ProhibitedItem(text: 'Spam, scams, or fraudulent listings'),
          _ProhibitedItem(text: 'Personal information of others'),

          const SizedBox(height: AppSpacing.space6),

          // Reviews and Ratings
          Text(
            'Reviews & Ratings',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            'Reviews help build trust in our community. When leaving reviews:\n\n'
            '• Be honest about your experience\n'
            '• Be specific about what went well or could improve\n'
            '• Focus on the transaction, not personal attacks\n'
            '• Do not offer incentives for positive reviews\n'
            '• Report fake or manipulated reviews',
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Reporting
          Text(
            'Reporting Violations',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            'Help us keep Tekka safe by reporting:\n\n'
            '• Suspicious or fraudulent listings\n'
            '• Users engaging in prohibited behavior\n'
            '• Harassment or threatening messages\n'
            '• Fake reviews or rating manipulation\n\n'
            'Use the report button on listings or user profiles, or contact us at support@tekka.ug',
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Consequences
          Text(
            'Enforcement',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            'Violations of these guidelines may result in:\n\n'
            '• Warning or content removal\n'
            '• Temporary account suspension\n'
            '• Permanent account ban\n'
            '• Reporting to law enforcement (for serious violations)\n\n'
            'We review all reports and take appropriate action based on the severity of the violation.',
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
            ),
          ),

          const SizedBox(height: AppSpacing.space8),

          // Community pledge
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.cardRadius,
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.handshake_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  'Our Community Pledge',
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  'Together, we commit to creating a marketplace where everyone feels welcome, safe, and respected. Thank you for being part of the Tekka community!',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
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

class _GuidelineCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<String> items;

  const _GuidelineCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.space3),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: color,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ProhibitedItem extends StatelessWidget {
  final String text;

  const _ProhibitedItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        children: [
          const Icon(
            Icons.block,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
