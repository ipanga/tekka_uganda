import {
  AFFINITY_WEIGHT_CATEGORY_VIEW,
  AFFINITY_WEIGHT_SAVE,
  TrackingService,
} from './tracking.service';

// Smoke tests for TrackingService. We can't reach Postgres in unit tests
// (mirrors the convention in notifications.service.spec.ts), so we mock
// PrismaService just enough to assert upsert payload shape and the
// swallow-on-error contract that prevents tracking from breaking the user
// path.

interface MockUpsertArgs {
  where: { userId_categoryId: { userId: string; categoryId: string } };
  create: {
    userId: string;
    categoryId: string;
    weight: number;
    eventCount: number;
  };
  update: {
    weight: { increment: number };
    eventCount: { increment: number };
    lastSeenAt: Date;
  };
}

function makeService(
  opts: { upsertImpl?: (args: MockUpsertArgs) => Promise<unknown> } = {},
) {
  const calls: MockUpsertArgs[] = [];
  const upsert = opts.upsertImpl ?? (() => Promise.resolve(undefined));
  const prisma = {
    userCategoryAffinity: {
      upsert: (args: MockUpsertArgs) => {
        calls.push(args);
        return upsert(args);
      },
    },
  };
  // Service requires a PrismaService instance — duck-type it.
  const svc = new TrackingService(prisma as never);
  return { svc, calls };
}

describe('TrackingService', () => {
  it('upserts with default category-view weight on recordCategoryView()', async () => {
    const { svc, calls } = makeService();
    await svc.recordCategoryView('u1', 'c1');
    expect(calls).toHaveLength(1);
    expect(calls[0].where.userId_categoryId).toEqual({
      userId: 'u1',
      categoryId: 'c1',
    });
    expect(calls[0].create.weight).toBe(AFFINITY_WEIGHT_CATEGORY_VIEW);
    expect(calls[0].create.eventCount).toBe(1);
    expect(calls[0].update.weight.increment).toBe(
      AFFINITY_WEIGHT_CATEGORY_VIEW,
    );
    expect(calls[0].update.eventCount.increment).toBe(1);
    expect(calls[0].update.lastSeenAt).toBeInstanceOf(Date);
  });

  it('uses the heavier save weight on recordSaveSignal()', async () => {
    const { svc, calls } = makeService();
    await svc.recordSaveSignal('u1', 'c1');
    expect(calls[0].create.weight).toBe(AFFINITY_WEIGHT_SAVE);
    expect(calls[0].update.weight.increment).toBe(AFFINITY_WEIGHT_SAVE);
  });

  it('weights save MORE than a category view (intent is stronger)', () => {
    expect(AFFINITY_WEIGHT_SAVE).toBeGreaterThan(AFFINITY_WEIGHT_CATEGORY_VIEW);
  });

  it('swallows upstream errors — never propagates to the caller', async () => {
    const { svc } = makeService({
      upsertImpl: () => Promise.reject(new Error('boom')),
    });
    // Must not throw. Tracking is best-effort.
    await expect(svc.recordCategoryView('u1', 'c1')).resolves.toBeUndefined();
    await expect(svc.recordSaveSignal('u1', 'c1')).resolves.toBeUndefined();
  });
});
