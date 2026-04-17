import 'package:flutter_test/flutter_test.dart';
import 'package:tekka/core/services/deep_link_mapper.dart';

// Integration contract: every URL the backend can emit via
// `NotificationsService.buildDeepLink` (apps/api/src/notifications/
// notifications.service.ts) must map to a non-null in-app route here.
// Keep this in sync with the backend spec.
void main() {
  group('backend deep_link round-trip', () {
    test('MESSAGE URL maps to /chat/:id', () {
      expect(
        mapDeepLinkUri(Uri.parse('https://tekka.ug/chat/c1')),
        '/chat/c1',
      );
    });

    test('LISTING_* URL maps to /listing/:id', () {
      expect(
        mapDeepLinkUri(Uri.parse('https://tekka.ug/listing/L1')),
        '/listing/L1',
      );
    });

    test('PRICE_DROP URL maps to /listing/:id', () {
      expect(
        mapDeepLinkUri(Uri.parse('https://tekka.ug/listing/L1')),
        '/listing/L1',
      );
    });

    test('NEW_REVIEW URL maps to /reviews/:userId', () {
      expect(
        mapDeepLinkUri(Uri.parse('https://tekka.ug/reviews/u1')),
        '/reviews/u1',
      );
    });

    test('MEETUP_* URL with id maps to /meetups/:id', () {
      expect(
        mapDeepLinkUri(Uri.parse('https://tekka.ug/meetups/m1')),
        '/meetups/m1',
      );
    });

    test('MEETUP_* URL without id maps to /meetups', () {
      expect(
        mapDeepLinkUri(Uri.parse('https://tekka.ug/meetups')),
        '/meetups',
      );
    });

    test('SYSTEM URL maps to /notifications', () {
      expect(
        mapDeepLinkUri(Uri.parse('https://tekka.ug/notifications')),
        '/notifications',
      );
    });
  });
}
