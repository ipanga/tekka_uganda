import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/api_client.dart';

/// Best-effort beacons for the PR5a affinity-tracking surface.
///
/// All methods swallow errors internally: a flaky tracking endpoint must
/// never break a user navigation. Callers are also free to `.catch()` or
/// `unawaited()` without worrying about loss of signal.
///
/// PR5b will read the accumulated per-user category affinity to rank the
/// "For You" home section. PR5a only writes — there is no client-facing
/// read endpoint here yet.
class TrackingApiRepository {
  TrackingApiRepository(this._api);

  final ApiClient _api;

  /// Fires when the viewer lands on a category page (web /explore?categoryId
  /// or Flutter category chip / browse filter). The server upserts a
  /// per-(user, category) affinity row; guests are no-op'd server-side.
  Future<void> recordCategoryView(String categoryId) async {
    try {
      await _api.post(
        '/tracking/category-view',
        data: {'categoryId': categoryId},
      );
    } catch (_) {
      // Best-effort. Tracking failures must not surface to the user.
    }
  }
}

/// Manual Riverpod provider — matches the style of [trendingListingsProvider]
/// in features/listing/application/listing_provider.dart rather than the
/// codegen `@Riverpod` style, so a one-file feature doesn't pull
/// build_runner into its critical path.
final trackingApiRepositoryProvider = Provider<TrackingApiRepository>(
  (ref) => TrackingApiRepository(ref.watch(apiClientProvider)),
);
