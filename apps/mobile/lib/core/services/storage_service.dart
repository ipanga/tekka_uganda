import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Service for handling image uploads via backend Cloudinary
class StorageService {
  ApiClient? _apiClient;

  StorageService({ApiClient? apiClient}) : _apiClient = apiClient;

  /// Set the API client (used for dependency injection)
  void setApiClient(ApiClient client) {
    _apiClient = client;
  }

  /// Upload profile image and return download URL
  Future<String?> uploadProfileImage({
    required File imageFile,
    required String userId,
  }) async {
    return uploadImage(imageFile: imageFile, path: 'profiles');
  }

  /// Upload listing image and return download URL
  Future<String?> uploadListingImage({
    required File imageFile,
    required String userId,
    required String listingId,
  }) async {
    return uploadImage(imageFile: imageFile, path: 'listings');
  }

  /// Upload chat image and return download URL
  Future<String?> uploadChatImage({
    required File imageFile,
    required String chatId,
  }) async {
    return uploadImage(imageFile: imageFile, path: 'chats');
  }

  /// Upload image via backend and return Cloudinary URL
  Future<String?> uploadImage({
    required File imageFile,
    required String path,
  }) async {
    if (_apiClient == null) {
      debugPrint('StorageService: API client not initialized');
      return null;
    }

    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient!.post<Map<String, dynamic>>(
        '/upload/image',
        data: formData,
      );

      return response['url'] as String?;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Upload multiple images via backend and return Cloudinary URLs
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String path,
  }) async {
    if (_apiClient == null) {
      debugPrint('StorageService: API client not initialized');
      return [];
    }

    try {
      final files = await Future.wait(
        imageFiles.map((file) async {
          final fileName = file.path.split('/').last;
          return MultipartFile.fromFile(file.path, filename: fileName);
        }),
      );

      final formData = FormData.fromMap({
        'files': files,
      });

      final response = await _apiClient!.post<Map<String, dynamic>>(
        '/upload/images',
        data: formData,
      );

      final urls = response['urls'] as List<dynamic>?;
      return urls?.cast<String>() ?? [];
    } catch (e) {
      debugPrint('Error uploading multiple images: $e');
      return [];
    }
  }

  /// Delete image from storage (no-op for now, handled by backend)
  Future<bool> deleteImage(String imageUrl) async {
    // Cloudinary deletion is handled by the backend when listings are deleted
    debugPrint('deleteImage called - handled by backend');
    return true;
  }

  /// Delete all images in a folder (no-op for now, handled by backend)
  Future<void> deleteFolder(String path) async {
    // Cloudinary folder deletion is handled by the backend
    debugPrint('deleteFolder called - handled by backend');
  }
}
