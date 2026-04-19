import 'package:flutter_test/flutter_test.dart';
import 'package:tekka/core/services/deep_link_mapper.dart';

void main() {
  group('mapDeepLinkUri', () {
    group('listing', () {
      test('maps /listing/:id', () {
        expect(
          mapDeepLinkUri(Uri.parse('https://tekka.ug/listing/abc123')),
          '/listing/abc123',
        );
      });

      test('returns null for /listing without id', () {
        expect(mapDeepLinkUri(Uri.parse('https://tekka.ug/listing')), null);
      });

      test('maps SEO URL /listing/:categorySlug/:slug to /listing/:slug', () {
        // Web uses SEO-friendly URLs like /listing/books/the-subtitle-art-...
        // The actual listing identifier is the last segment.
        expect(
          mapDeepLinkUri(
            Uri.parse(
              'https://tekka.ug/listing/books/the-subtitle-art-of-not-giving-a-fck-0hjwbz',
            ),
          ),
          '/listing/the-subtitle-art-of-not-giving-a-fck-0hjwbz',
        );
      });
    });

    group('chat', () {
      test('maps /chat/:id', () {
        expect(
          mapDeepLinkUri(Uri.parse('https://tekka.ug/chat/xyz789')),
          '/chat/xyz789',
        );
      });

      test('maps bare /chat to list', () {
        expect(mapDeepLinkUri(Uri.parse('https://tekka.ug/chat')), '/chat');
      });
    });

    group('user', () {
      test('maps /user/:id', () {
        expect(
          mapDeepLinkUri(Uri.parse('https://tekka.ug/user/user-1')),
          '/user/user-1',
        );
      });

      test('returns null for /user without id', () {
        expect(mapDeepLinkUri(Uri.parse('https://tekka.ug/user')), null);
      });
    });

    group('reviews', () {
      test('maps /reviews/:userId', () {
        expect(
          mapDeepLinkUri(Uri.parse('https://tekka.ug/reviews/user-42')),
          '/reviews/user-42',
        );
      });
    });

    group('notifications', () {
      test('maps /notifications', () {
        expect(
          mapDeepLinkUri(Uri.parse('https://tekka.ug/notifications')),
          '/notifications',
        );
      });

      test('maps /notifications/:id', () {
        expect(
          mapDeepLinkUri(Uri.parse('https://tekka.ug/notifications/n1')),
          '/notifications/n1',
        );
      });
    });

    group('meetups', () {
      test('maps bare /meetups', () {
        expect(
          mapDeepLinkUri(Uri.parse('https://tekka.ug/meetups')),
          '/meetups',
        );
      });

      test('maps /meetups/:id', () {
        expect(
          mapDeepLinkUri(Uri.parse('https://tekka.ug/meetups/m1')),
          '/meetups/m1',
        );
      });
    });

    group('profile', () {
      test('maps /profile', () {
        expect(
          mapDeepLinkUri(Uri.parse('https://tekka.ug/profile')),
          '/profile',
        );
      });

      test('maps /profile/:sub', () {
        expect(
          mapDeepLinkUri(Uri.parse('https://tekka.ug/profile/settings')),
          '/profile/settings',
        );
      });
    });

    group('passthrough top-level', () {
      test('/home', () {
        expect(mapDeepLinkUri(Uri.parse('https://tekka.ug/home')), '/home');
      });
      test('/browse', () {
        expect(mapDeepLinkUri(Uri.parse('https://tekka.ug/browse')), '/browse');
      });
      test('/saved', () {
        expect(mapDeepLinkUri(Uri.parse('https://tekka.ug/saved')), '/saved');
      });
    });

    group('host validation', () {
      test('accepts apex tekka.ug', () {
        expect(
          mapDeepLinkUri(Uri.parse('https://tekka.ug/listing/1')),
          '/listing/1',
        );
      });

      test('accepts www.tekka.ug', () {
        expect(
          mapDeepLinkUri(Uri.parse('https://www.tekka.ug/listing/1')),
          '/listing/1',
        );
      });

      test('rejects foreign host', () {
        expect(
          mapDeepLinkUri(Uri.parse('https://evil.com/listing/1')),
          null,
        );
      });

      test('accepts empty host (relative URIs from data payloads)', () {
        expect(mapDeepLinkUri(Uri.parse('/listing/1')), '/listing/1');
      });
    });

    group('unknown paths', () {
      test('unknown top-level returns null', () {
        expect(
          mapDeepLinkUri(Uri.parse('https://tekka.ug/admin-secrets')),
          null,
        );
      });
    });

    group('root', () {
      test('bare host goes home', () {
        expect(mapDeepLinkUri(Uri.parse('https://tekka.ug/')), '/home');
      });
    });
  });
}
