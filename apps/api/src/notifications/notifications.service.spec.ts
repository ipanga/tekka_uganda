import { NotificationType } from '@prisma/client';
import { NotificationsService } from './notifications.service';

// Minimal smoke test for the deep-link contract produced by the FCM payload
// enrichment. Runs buildDeepLink for each notification type and asserts the
// URL pattern matches what the Flutter app's deep link mapper accepts.

type BuildDeepLink = (
  type: NotificationType,
  data?: Record<string, unknown>,
  notificationId?: string,
) => string | null;

describe('NotificationsService.buildDeepLink', () => {
  // Construct the instance without real dependencies — buildDeepLink is pure.
  const service = new NotificationsService(null as never, null as never);
  const buildDeepLink: BuildDeepLink = (type, data, notificationId) =>
    (service as unknown as { buildDeepLink: BuildDeepLink }).buildDeepLink(
      type,
      data,
      notificationId,
    );

  it('MESSAGE -> /chat/:id', () => {
    expect(buildDeepLink(NotificationType.MESSAGE, { chatId: 'c1' })).toBe(
      'https://tekka.ug/chat/c1',
    );
  });

  it('MESSAGE without chatId -> null', () => {
    expect(buildDeepLink(NotificationType.MESSAGE, {})).toBeNull();
  });

  it.each([
    NotificationType.LISTING_APPROVED,
    NotificationType.LISTING_REJECTED,
    NotificationType.LISTING_SOLD,
    NotificationType.PRICE_DROP,
  ] as const)('%s -> /listing/:id', (type) => {
    expect(buildDeepLink(type, { listingId: 'L1' })).toBe(
      'https://tekka.ug/listing/L1',
    );
  });

  it('NEW_REVIEW uses userId first', () => {
    expect(
      buildDeepLink(NotificationType.NEW_REVIEW, {
        userId: 'u1',
        reviewerId: 'u2',
      }),
    ).toBe('https://tekka.ug/reviews/u1');
  });

  it('NEW_REVIEW falls back to reviewerId', () => {
    expect(
      buildDeepLink(NotificationType.NEW_REVIEW, { reviewerId: 'u2' }),
    ).toBe('https://tekka.ug/reviews/u2');
  });

  it('MEETUP_PROPOSED with id', () => {
    expect(
      buildDeepLink(NotificationType.MEETUP_PROPOSED, { meetupId: 'm1' }),
    ).toBe('https://tekka.ug/meetups/m1');
  });

  it('MEETUP_ACCEPTED without id falls back to /meetups', () => {
    expect(buildDeepLink(NotificationType.MEETUP_ACCEPTED, {})).toBe(
      'https://tekka.ug/meetups',
    );
  });

  it('SYSTEM with notificationId -> /notifications/:id (admin broadcast detail)', () => {
    expect(buildDeepLink(NotificationType.SYSTEM, {}, 'n_abc123')).toBe(
      'https://tekka.ug/notifications/n_abc123',
    );
  });

  it('SYSTEM with notificationId AND listingId -> still /notifications/:id (detail screen renders View Listing button)', () => {
    expect(
      buildDeepLink(
        NotificationType.SYSTEM,
        { listingId: 'L42', type: 'listing' },
        'n_abc123',
      ),
    ).toBe('https://tekka.ug/notifications/n_abc123');
  });

  it('SYSTEM without notificationId -> /notifications (legacy fallback)', () => {
    expect(buildDeepLink(NotificationType.SYSTEM, {})).toBe(
      'https://tekka.ug/notifications',
    );
  });

  it('OFFER types (deprecated) -> null', () => {
    expect(
      buildDeepLink(NotificationType.OFFER, { listingId: 'x' }),
    ).toBeNull();
  });

  it('ignores non-string id fields', () => {
    expect(
      buildDeepLink(NotificationType.MESSAGE, {
        chatId: 123 as unknown as string,
      }),
    ).toBeNull();
  });
});
