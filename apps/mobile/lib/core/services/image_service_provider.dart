import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client_provider.dart';
import 'image_service.dart';
import 'storage_service.dart';

/// Provider for ImageService
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

/// Provider for StorageService (uses backend Cloudinary upload)
final storageServiceProvider = Provider<StorageService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StorageService(apiClient: apiClient);
});
