import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/push_notification_service.dart';
import 'repository_providers.dart';

/// Push notification service provider
final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService(
    userApiRepository: ref.watch(userApiRepositoryProvider),
  );
});
