import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_client.dart';

part 'api_client_provider.g.dart';

@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) {
  return ApiClient();
}
