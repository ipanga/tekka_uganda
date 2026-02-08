import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_provider.dart';
import '../features/auth/presentation/screens/phone_input_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/listing/presentation/screens/listing_detail_screen.dart';
import '../features/listing/presentation/screens/create_listing_screen.dart';
import '../features/listing/presentation/screens/edit_listing_screen.dart';
import '../features/chat/presentation/screens/chat_list_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/my_listings_screen.dart';
import '../features/profile/presentation/screens/saved_items_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';
import '../features/profile/presentation/screens/purchase_history_screen.dart';
import '../features/profile/presentation/screens/user_profile_screen.dart';
import '../features/profile/presentation/screens/help_screen.dart';
import '../features/profile/presentation/screens/safety_tips_screen.dart';
import '../features/profile/presentation/screens/blocked_users_screen.dart';
import '../features/profile/presentation/screens/seller_analytics_screen.dart';
import '../features/profile/presentation/screens/privacy_settings_screen.dart';
import '../features/profile/presentation/screens/security_settings_screen.dart';
import '../features/profile/presentation/screens/email_verification_screen.dart';
import '../features/profile/presentation/screens/identity_verification_screen.dart';
import '../features/profile/presentation/screens/account_deletion_screen.dart';
import '../features/profile/presentation/screens/terms_of_service_screen.dart';
import '../features/profile/presentation/screens/privacy_policy_screen.dart';
import '../features/profile/presentation/screens/community_guidelines_screen.dart';
import '../features/profile/presentation/screens/two_factor_auth_screen.dart';
import '../features/profile/presentation/screens/language_screen.dart';
import '../features/profile/presentation/screens/default_location_screen.dart';
import '../features/profile/presentation/screens/change_pin_screen.dart';
import '../features/profile/presentation/screens/app_lock_settings_screen.dart';
import '../features/profile/presentation/screens/data_export_screen.dart';
import '../features/search/presentation/screens/saved_searches_screen.dart';
import '../features/listing/presentation/screens/price_alerts_screen.dart';
import '../features/chat/presentation/screens/quick_reply_templates_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/notifications/presentation/screens/notification_detail_screen.dart';
import '../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../features/reviews/presentation/screens/reviews_screen.dart';
import '../features/reviews/presentation/screens/create_review_screen.dart';
import '../features/reviews/domain/entities/review.dart';
import '../features/meetup/presentation/screens/meetups_list_screen.dart';
import '../features/meetup/presentation/screens/meetup_detail_screen.dart';
import '../features/meetup/presentation/screens/safe_locations_screen.dart';
import '../features/report/presentation/screens/report_listing_screen.dart';
import '../shared/widgets/main_shell.dart';

/// Route paths
abstract class AppRoutes {
  static const String splash = '/';
  static const String phoneInput = '/auth/phone';
  static const String otpVerification = '/auth/otp';
  static const String onboarding = '/auth/onboarding';
  static const String home = '/home';
  static const String browse = '/browse';
  static const String listingDetail = '/listing/:id';
  static const String createListing = '/create-listing';
  static const String chatList = '/chat';
  static const String chat = '/chat/:id';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String myListings = '/profile/listings';
  static const String savedItems = '/profile/saved';
  static const String settings = '/profile/settings';
  static const String purchaseHistory = '/profile/purchases';
  static const String help = '/profile/help';
  static const String safetyTips = '/profile/safety';
  static const String blockedUsers = '/profile/blocked';
  static const String sellerAnalytics = '/profile/analytics';
  static const String notificationSettings = '/profile/notifications';
  static const String privacySettings = '/profile/privacy';
  static const String securitySettings = '/profile/security';
  static const String emailVerification = '/profile/verify-email';
  static const String identityVerification = '/profile/verify-identity';
  static const String accountDeletion = '/profile/delete-account';
  static const String twoFactorAuth = '/profile/two-factor-auth';
  static const String language = '/profile/language';
  static const String defaultLocation = '/profile/location';
  static const String changePin = '/profile/change-pin';
  static const String appLockSettings = '/profile/app-lock';
  static const String dataExport = '/profile/data-export';
  static const String savedSearches = '/profile/saved-searches';
  static const String priceAlerts = '/profile/price-alerts';
  static const String quickReplyTemplates = '/chat/quick-replies';
  static const String termsOfService = '/legal/terms';
  static const String privacyPolicy = '/legal/privacy';
  static const String communityGuidelines = '/legal/guidelines';
  static const String editListing = '/listing/:id/edit';
  static const String notifications = '/notifications';
  static const String reviews = '/reviews/:userId';
  static const String createReview = '/review/create';
  static const String userProfile = '/user/:userId';
  static const String meetups = '/meetups';
  static const String meetupDetail = '/meetups/:id';
  static const String safeLocations = '/meetups/locations';
  static const String reportListing = '/listing/:id/report';
  static const String notificationDetail = '/notifications/:id';
}

/// App router configuration
/// Using keepAlive to prevent router recreation on auth state changes
final appRouterProvider = Provider<GoRouter>((ref) {
  // Keep reference to previous router to preserve navigation state
  ref.keepAlive();

  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == AppRoutes.splash;

      // Wait for auth state to load
      if (authState.isLoading) {
        return null;
      }

      final user = authState.valueOrNull;
      final isAuthenticated = user != null;
      final isOnboardingComplete = user?.isOnboardingComplete ?? false;

      // If not authenticated, redirect to phone input
      if (!isAuthenticated && !isAuthRoute && !isSplash) {
        return AppRoutes.phoneInput;
      }

      // If authenticated but onboarding not complete
      if (isAuthenticated && !isOnboardingComplete && !isAuthRoute) {
        return AppRoutes.onboarding;
      }

      // If authenticated and on auth route, redirect to home
      if (isAuthenticated && isOnboardingComplete && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Auth routes (outside shell)
      GoRoute(
        path: AppRoutes.phoneInput,
        builder: (context, state) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpVerificationScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) {
              // Parse query parameters for filters
              final categoryId = state.uri.queryParameters['categoryId'];
              final search = state.uri.queryParameters['search'];
              return NoTransitionPage(
                child: HomeScreen(
                  initialCategoryId: categoryId,
                  initialSearch: search,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.browse,
            redirect: (context, state) {
              // Redirect /browse to /home with preserved query params
              final queryParams = state.uri.queryParameters;
              if (queryParams.isEmpty) {
                return AppRoutes.home;
              }
              return Uri(
                path: AppRoutes.home,
                queryParameters: queryParams,
              ).toString();
            },
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(), // Fallback, redirect should catch this
            ),
          ),
          GoRoute(
            path: AppRoutes.chatList,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ChatListScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      // Full-screen routes (outside shell)
      GoRoute(
        path: AppRoutes.listingDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ListingDetailScreen(listingId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.createListing,
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatScreen(chatId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.myListings,
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.savedItems,
        builder: (context, state) => const SavedItemsScreen(),
      ),
      GoRoute(
        path: AppRoutes.editListing,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditListingScreen(listingId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.purchaseHistory,
        builder: (context, state) => const PurchaseHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.help,
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: AppRoutes.safetyTips,
        builder: (context, state) => const SafetyTipsScreen(),
      ),
      GoRoute(
        path: AppRoutes.blockedUsers,
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellerAnalytics,
        builder: (context, state) => const SellerAnalyticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacySettings,
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.securitySettings,
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.identityVerification,
        builder: (context, state) => const IdentityVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountDeletion,
        builder: (context, state) => const AccountDeletionScreen(),
      ),
      GoRoute(
        path: AppRoutes.twoFactorAuth,
        builder: (context, state) => const TwoFactorAuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.language,
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: AppRoutes.defaultLocation,
        builder: (context, state) => const DefaultLocationScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePin,
        builder: (context, state) => const ChangePinScreen(),
      ),
      GoRoute(
        path: AppRoutes.appLockSettings,
        builder: (context, state) => const AppLockSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.dataExport,
        builder: (context, state) => const DataExportScreen(),
      ),
      GoRoute(
        path: AppRoutes.savedSearches,
        builder: (context, state) => const SavedSearchesScreen(),
      ),
      GoRoute(
        path: AppRoutes.priceAlerts,
        builder: (context, state) => const PriceAlertsScreen(),
      ),
      GoRoute(
        path: AppRoutes.quickReplyTemplates,
        builder: (context, state) => const QuickReplyTemplatesScreen(),
      ),
      GoRoute(
        path: AppRoutes.termsOfService,
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.communityGuidelines,
        builder: (context, state) => const CommunityGuidelinesScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.reviews,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final userName = state.extra as String? ?? 'User';
          return ReviewsScreen(userId: userId, userName: userName);
        },
      ),
      GoRoute(
        path: AppRoutes.createReview,
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          return CreateReviewScreen(
            revieweeId: params['revieweeId'] as String,
            revieweeName: params['revieweeName'] as String,
            listingId: params['listingId'] as String,
            listingTitle: params['listingTitle'] as String,
            reviewType: params['reviewType'] as ReviewType,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.userProfile,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: AppRoutes.meetups,
        builder: (context, state) => const MeetupsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.safeLocations,
        builder: (context, state) => const SafeLocationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.meetupDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MeetupDetailScreen(meetupId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.reportListing,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final params = state.extra as Map<String, dynamic>;
          return ReportListingScreen(
            listingId: id,
            listingTitle: params['listingTitle'] as String,
            sellerId: params['sellerId'] as String,
            sellerName: params['sellerName'] as String,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notificationDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return NotificationDetailScreen(notificationId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.matchedLocation}')),
    ),
  );
});
