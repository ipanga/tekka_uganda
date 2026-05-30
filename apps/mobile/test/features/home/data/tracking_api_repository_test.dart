import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekka/core/services/api_client.dart';
import 'package:tekka/features/home/data/repositories/tracking_api_repository.dart';

/// PR5a — verifies the affinity-tracking beacon hits the right path with
/// the right body, and that an exception from the network layer is fully
/// swallowed so the caller's UI flow never breaks.

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient api;
  late TrackingApiRepository repo;

  setUp(() {
    api = _MockApiClient();
    repo = TrackingApiRepository(api);
  });

  test('recordCategoryView POSTs /tracking/category-view with the id', () async {
    when(
      () => api.post<dynamic>(any(), data: any(named: 'data')),
    ).thenAnswer((_) async => null);

    await repo.recordCategoryView('cat-123');

    final captured = verify(
      () => api.post<dynamic>(
        captureAny(),
        data: captureAny(named: 'data'),
      ),
    ).captured;
    expect(captured[0], '/tracking/category-view');
    expect(captured[1], {'categoryId': 'cat-123'});
  });

  test('recordCategoryView swallows exceptions', () async {
    when(
      () => api.post<dynamic>(any(), data: any(named: 'data')),
    ).thenThrow(Exception('boom'));

    // Must not throw — tracking is best-effort.
    await expectLater(repo.recordCategoryView('cat-x'), completes);
  });
}
