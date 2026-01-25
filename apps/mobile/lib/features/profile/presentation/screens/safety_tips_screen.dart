import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Safety Tips screen for marketplace safety guidelines
class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safety Tips'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.successContainer,
              borderRadius: BorderRadius.circular(AppSpacing.space3),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(AppSpacing.space2),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.onSuccess,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stay Safe on Tekka',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.onSuccessContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        'Follow these tips for safe buying and selling.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSuccessContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Meeting safely
          const _SafetySection(
            icon: Icons.location_on_outlined,
            title: 'Meeting Safely',
            tips: [
              _SafetyTip(
                title: 'Meet in public places',
                description:
                    'Always meet in busy, well-lit public areas like shopping malls, '
                    'cafes, or bank lobbies. Avoid meeting at private residences.',
              ),
              _SafetyTip(
                title: 'Use our safe locations',
                description:
                    'We recommend verified safe meetup spots in Kampala and Entebbe. '
                    'Check the "Suggest Meetup" feature in chat.',
              ),
              _SafetyTip(
                title: 'Meet during daylight',
                description:
                    'Schedule meetups during daytime hours when possible. '
                    'If meeting in the evening, choose well-lit locations.',
              ),
              _SafetyTip(
                title: 'Tell someone',
                description:
                    'Let a friend or family member know where you\'re going '
                    'and who you\'re meeting.',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Payment safety
          const _SafetySection(
            icon: Icons.payments_outlined,
            title: 'Payment Safety',
            tips: [
              _SafetyTip(
                title: 'Inspect before paying',
                description:
                    'Always examine items thoroughly before completing payment. '
                    'Test electronics, check for defects, and verify authenticity.',
              ),
              _SafetyTip(
                title: 'Use mobile money',
                description:
                    'Mobile money provides a digital record of your transaction. '
                    'Avoid carrying large amounts of cash.',
              ),
              _SafetyTip(
                title: 'Never pay in advance',
                description:
                    'Don\'t send money before meeting and seeing the item. '
                    'Legitimate sellers will agree to payment upon delivery.',
              ),
              _SafetyTip(
                title: 'Get a receipt',
                description:
                    'For expensive items, ask for a written receipt with '
                    'seller details and item description.',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Avoiding scams
          const _SafetySection(
            icon: Icons.warning_amber_outlined,
            title: 'Avoiding Scams',
            tips: [
              _SafetyTip(
                title: 'Watch for red flags',
                description:
                    'Be cautious of prices that seem too good to be true, '
                    'pressure to act quickly, or requests for unusual payment methods.',
              ),
              _SafetyTip(
                title: 'Verify seller profiles',
                description:
                    'Check seller reviews, rating, and account age. '
                    'New accounts with no history may be riskier.',
              ),
              _SafetyTip(
                title: 'Keep communication on Tekka',
                description:
                    'Scammers often try to move conversations to WhatsApp or email. '
                    'Stay on the app for your protection.',
              ),
              _SafetyTip(
                title: 'Trust your instincts',
                description:
                    'If something feels wrong, walk away. There will always be '
                    'other items and other sellers.',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Selling safely
          const _SafetySection(
            icon: Icons.storefront_outlined,
            title: 'Selling Safely',
            tips: [
              _SafetyTip(
                title: 'Don\'t share personal info',
                description:
                    'Avoid sharing your home address, work location, or '
                    'personal phone number until necessary.',
              ),
              _SafetyTip(
                title: 'Confirm payment first',
                description:
                    'For mobile money payments, wait for confirmation before '
                    'handing over items. Check your balance.',
              ),
              _SafetyTip(
                title: 'Be accurate in listings',
                description:
                    'Describe items honestly and include photos of any defects. '
                    'This prevents disputes and builds trust.',
              ),
              _SafetyTip(
                title: 'Handle cash carefully',
                description:
                    'If accepting cash, count it before the buyer leaves. '
                    'Consider using a bank lobby for large transactions.',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space6),

          // Report section
          Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.space3),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      color: AppColors.error,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Text(
                      'Report Suspicious Activity',
                      style: AppTypography.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  'If you encounter a scam, fraud, or suspicious behavior, '
                  'report the user immediately. Our team reviews all reports '
                  'and takes action to keep the community safe.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  'To report a user, tap on their profile and select "Report User".',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
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

class _SafetySection extends StatelessWidget {
  const _SafetySection({
    required this.icon,
    required this.title,
    required this.tips,
  });

  final IconData icon;
  final String title;
  final List<_SafetyTip> tips;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.space3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.space3),
                Text(
                  title,
                  style: AppTypography.titleSmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...tips.asMap().entries.map((entry) {
            final index = entry.key;
            final tip = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip.title,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space1),
                            Text(
                              tip.description,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < tips.length - 1)
                  const Divider(height: 1, indent: 56),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SafetyTip {
  final String title;
  final String description;

  const _SafetyTip({required this.title, required this.description});
}
