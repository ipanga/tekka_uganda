import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/api_client.dart';
import '../../features/auth/data/repositories/user_api_repository.dart';
import '../../features/listing/data/repositories/listing_api_repository.dart';
import '../../features/listing/data/repositories/category_api_repository.dart';
import '../../features/chat/data/repositories/chat_api_repository.dart';

part 'repository_providers.g.dart';

/// API Client provider - singleton
@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) {
  return ApiClient();
}

/// User API repository
@Riverpod(keepAlive: true)
UserApiRepository userApiRepository(UserApiRepositoryRef ref) {
  return UserApiRepository(ref.watch(apiClientProvider));
}

/// Listing API repository
@Riverpod(keepAlive: true)
ListingApiRepository listingApiRepository(ListingApiRepositoryRef ref) {
  return ListingApiRepository(ref.watch(apiClientProvider));
}

/// Chat API repository
@Riverpod(keepAlive: true)
ChatApiRepository chatApiRepository(ChatApiRepositoryRef ref) {
  return ChatApiRepository(ref.watch(apiClientProvider));
}

/// Category API repository (for hierarchical categories and locations)
@Riverpod(keepAlive: true)
CategoryApiRepository categoryApiRepository(CategoryApiRepositoryRef ref) {
  return CategoryApiRepository(ref.watch(apiClientProvider));
}
