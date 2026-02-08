import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';

/// Help & Support screen with FAQs and contact options
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _expandedIndex;

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'How do I list an item for sale?',
      answer:
          'Tap the "+" button at the bottom of the screen to create a new listing. '
          'Add photos of your item, fill in the details like title, description, '
          'price, and category, then tap "Publish" to make it live.',
    ),
    _FaqItem(
      question: 'How do I contact a seller?',
      answer:
          'Go to the item you\'re interested in and tap "Message Seller". '
          'You can ask questions about the item, discuss the price, and '
          'arrange a meetup directly through the chat.',
    ),
    _FaqItem(
      question: 'How does payment work?',
      answer:
          'Tekka is a peer-to-peer marketplace. Payment is handled directly '
          'between buyers and sellers when you meet up. We recommend using '
          'mobile money for secure transactions.',
    ),
    _FaqItem(
      question: 'How do I arrange a meetup?',
      answer:
          'Once you\'ve agreed on a price, use the chat to suggest a safe meetup '
          'location. We provide a list of verified safe locations like shopping '
          'malls and cafes. Always meet in public places during daylight hours.',
    ),
    _FaqItem(
      question: 'What if an item is not as described?',
      answer:
          'Always inspect items carefully before completing payment. If you have '
          'issues with a seller, you can report them through their profile. We '
          'take reports seriously and may suspend accounts that violate our policies.',
    ),
    _FaqItem(
      question: 'How do reviews work?',
      answer:
          'After a successful transaction, both buyers and sellers can leave '
          'reviews for each other. Reviews help build trust in the community. '
          'Be honest and fair in your reviews.',
    ),
    _FaqItem(
      question: 'Can I edit or delete my listing?',
      answer:
          'Yes! Go to "My Listings" in your profile, find the listing you want '
          'to modify, and tap the edit icon. You can update details, change '
          'the price, or delete the listing entirely.',
    ),
    _FaqItem(
      question: 'How do I report a suspicious user?',
      answer:
          'Tap on the user\'s profile and select "Report User". Choose the reason '
          'for reporting and provide any relevant details. Our team reviews all '
          'reports within 24 hours.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.space4),

          // Contact options
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.space3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help?',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  'Our support team is here to help you.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Row(
                  children: [
                    Expanded(
                      child: _ContactButton(
                        icon: Icons.email_outlined,
                        label: 'Email Us',
                        onTap: () => _launchEmail(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: _ContactButton(
                        icon: Icons.phone_outlined,
                        label: 'Call Us',
                        onTap: () => _launchPhone(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // FAQs header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: Text(
              'Frequently Asked Questions',
              style: AppTypography.titleMedium,
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          // FAQ list
          Container(
            color: AppColors.surface,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _faqs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final faq = _faqs[index];
                final isExpanded = _expandedIndex == index;

                return _FaqTile(
                  question: faq.question,
                  answer: faq.answer,
                  isExpanded: isExpanded,
                  onTap: () {
                    setState(() {
                      _expandedIndex = isExpanded ? null : index;
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Additional resources
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: Text(
              'Additional Resources',
              style: AppTypography.titleMedium,
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.description_outlined,
                    color: AppColors.onSurfaceVariant,
                  ),
                  title: Text(
                    'Terms of Service',
                    style: AppTypography.bodyLarge,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onTap: () => context.push(AppRoutes.termsOfService),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.onSurfaceVariant,
                  ),
                  title: Text(
                    'Privacy Policy',
                    style: AppTypography.bodyLarge,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onTap: () => context.push(AppRoutes.privacyPolicy),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.gavel_outlined,
                    color: AppColors.onSurfaceVariant,
                  ),
                  title: Text(
                    'Community Guidelines',
                    style: AppTypography.bodyLarge,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onTap: () => context.push(AppRoutes.communityGuidelines),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space10),
        ],
      ),
    );
  }

  void _launchEmail() {
    const email = 'support@tekka.ug';
    Clipboard.setData(const ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email copied: $email')),
    );
  }

  void _launchPhone() {
    const phone = '+256 700 000 000';
    Clipboard.setData(const ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone copied: $phone')),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: AppSpacing.space3),
              Text(
                answer,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.space2),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.space2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
