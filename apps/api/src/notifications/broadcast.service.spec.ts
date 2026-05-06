import { NotificationType, UserRole } from '@prisma/client';
import { NotificationsService } from './notifications.service';
import { BroadcastAudience } from './dto';

// Audience resolution and broadcast() fan-out are the load-bearing pieces of
// the admin broadcast feature. Each test wires a minimal Prisma mock — no DB.

type Mock = jest.Mock;

function makeService() {
  const prisma = {
    user: {
      findMany: jest.fn() as Mock,
      count: jest.fn() as Mock,
    },
    broadcast: {
      create: jest.fn() as Mock,
      update: jest.fn() as Mock,
    },
    notification: {
      create: jest.fn() as Mock,
    },
    fcmToken: {
      findMany: jest.fn().mockResolvedValue([]) as Mock,
    },
  };
  const config = {} as never;
  const service = new NotificationsService(prisma as never, config);
  return { service, prisma };
}

describe('NotificationsService.resolveAudience', () => {
  it('ALL → all non-suspended user IDs', async () => {
    const { service, prisma } = makeService();
    prisma.user.findMany.mockResolvedValue([{ id: 'u1' }, { id: 'u2' }]);

    const ids = await (service as any).resolveAudience(
      BroadcastAudience.ALL,
      undefined,
      undefined,
    );

    expect(ids).toEqual(['u1', 'u2']);
    expect(prisma.user.findMany).toHaveBeenCalledWith({
      where: { isSuspended: false },
      select: { id: true },
    });
  });

  it('ROLE → users with the given role, excluding suspended', async () => {
    const { service, prisma } = makeService();
    prisma.user.findMany.mockResolvedValue([{ id: 'mod1' }]);

    const ids = await (service as any).resolveAudience(
      BroadcastAudience.ROLE,
      UserRole.MODERATOR,
      undefined,
    );

    expect(ids).toEqual(['mod1']);
    expect(prisma.user.findMany).toHaveBeenCalledWith({
      where: { isSuspended: false, role: UserRole.MODERATOR },
      select: { id: true },
    });
  });

  it('ROLE without role → empty (defensive)', async () => {
    const { service, prisma } = makeService();
    const ids = await (service as any).resolveAudience(
      BroadcastAudience.ROLE,
      undefined,
      undefined,
    );
    expect(ids).toEqual([]);
    expect(prisma.user.findMany).not.toHaveBeenCalled();
  });

  it('SPECIFIC → returns the provided list verbatim, no DB hit, no filtering', async () => {
    const { service, prisma } = makeService();
    const ids = await (service as any).resolveAudience(
      BroadcastAudience.SPECIFIC,
      undefined,
      ['a', 'b', 'c'],
    );
    expect(ids).toEqual(['a', 'b', 'c']);
    expect(prisma.user.findMany).not.toHaveBeenCalled();
  });
});

describe('NotificationsService.broadcast', () => {
  it('creates a Broadcast row, fans out per-user notifications with broadcastId, and finalizes recipientCount', async () => {
    const { service, prisma } = makeService();
    prisma.user.findMany.mockResolvedValue([{ id: 'u1' }, { id: 'u2' }]);
    prisma.broadcast.create.mockResolvedValue({
      id: 'b1',
      title: 'Sale',
      body: '20% off',
      audience: 'ALL',
      role: null,
      listingId: null,
      createdById: 'admin1',
      recipientCount: 0,
      createdAt: new Date(),
    });
    prisma.notification.create.mockImplementation(
      ({ data }: { data: Record<string, unknown> }) =>
        Promise.resolve({ id: `n-${String(data.userId)}`, ...data }),
    );
    prisma.broadcast.update.mockResolvedValue(undefined);

    const result = await service.broadcast(
      {
        title: 'Sale',
        body: '20% off',
        audience: BroadcastAudience.ALL,
      },
      'admin1',
    );

    expect(prisma.broadcast.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        title: 'Sale',
        body: '20% off',
        audience: 'ALL',
        role: null,
        listingId: null,
        createdById: 'admin1',
        recipientCount: 0,
      }),
    });

    // One Notification.create per resolved user, each carrying broadcastId=b1
    expect(prisma.notification.create).toHaveBeenCalledTimes(2);
    const created = prisma.notification.create.mock.calls.map((c) => c[0].data);
    expect(created.every((d) => d.broadcastId === 'b1')).toBe(true);
    expect(created.every((d) => d.type === NotificationType.SYSTEM)).toBe(true);
    expect(created.map((d) => d.userId).sort()).toEqual(['u1', 'u2']);

    // recipientCount is updated to the succeeded count after fan-out
    expect(prisma.broadcast.update).toHaveBeenCalledWith({
      where: { id: 'b1' },
      data: { recipientCount: 2 },
    });

    expect(result.result).toEqual({ succeeded: 2, failed: 0, total: 2 });
    expect(result.broadcast.recipientCount).toBe(2);
  });

  it('product-linked broadcast threads listingId into per-user notification data', async () => {
    const { service, prisma } = makeService();
    prisma.user.findMany.mockResolvedValue([{ id: 'u1' }]);
    prisma.broadcast.create.mockResolvedValue({
      id: 'b2',
      title: 'New drop',
      body: 'Check it out',
      audience: 'ALL',
      role: null,
      listingId: 'LST123',
      createdById: 'admin1',
      recipientCount: 0,
      createdAt: new Date(),
    });
    prisma.notification.create.mockResolvedValue({});
    prisma.broadcast.update.mockResolvedValue(undefined);

    await service.broadcast(
      {
        title: 'New drop',
        body: 'Check it out',
        audience: BroadcastAudience.ALL,
        listingId: 'LST123',
      },
      'admin1',
    );

    const created = prisma.notification.create.mock.calls[0][0].data;
    // Include type:'listing' so the Flutter detail screen renders a "View
    // Listing" action button — see notification_detail_screen.dart:328.
    expect(created.data).toEqual({ listingId: 'LST123', type: 'listing' });
    expect(created.type).toBe(NotificationType.SYSTEM);
  });
});
