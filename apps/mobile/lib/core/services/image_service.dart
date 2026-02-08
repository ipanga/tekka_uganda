import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../config/app_config.dart';

/// Service for handling image picking and compression
class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Pick a single image from gallery
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: AppConfig.maxImageWidth.toDouble(),
      maxHeight: AppConfig.maxImageHeight.toDouble(),
      imageQuality: AppConfig.imageQuality,
    );

    if (image == null) return null;
    return File(image.path);
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: AppConfig.maxImageWidth.toDouble(),
      maxHeight: AppConfig.maxImageHeight.toDouble(),
      imageQuality: AppConfig.imageQuality,
      limit: maxImages,
    );

    return images.map((xfile) => File(xfile.path)).toList();
  }

  /// Take a photo with camera
  Future<File?> takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: AppConfig.maxImageWidth.toDouble(),
      maxHeight: AppConfig.maxImageHeight.toDouble(),
      imageQuality: AppConfig.imageQuality,
    );

    if (image == null) return null;
    return File(image.path);
  }

  /// Compress image file
  /// If the file is over 1MB, uses more aggressive compression to ensure
  /// the final file size is under 1MB while preserving visual quality.
  Future<File?> compressImage(File file, {int? quality}) async {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(
      dir.path,
      '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
    );

    // Determine compression quality based on file size
    final fileSizeMB = getFileSizeMB(file);
    int compressionQuality;

    if (quality != null) {
      compressionQuality = quality;
    } else if (fileSizeMB > 3) {
      // Very large files: aggressive compression
      compressionQuality = 60;
    } else if (fileSizeMB > 1) {
      // Large files: moderate compression to get under 1MB
      compressionQuality = 70;
    } else {
      // Normal files: standard quality
      compressionQuality = 85;
    }

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: compressionQuality,
      minWidth: 800,
      minHeight: 800,
    );

    if (result == null) return null;

    final compressedFile = File(result.path);

    // If still over 1MB, try again with lower quality
    if (getFileSizeMB(compressedFile) > 1 && compressionQuality > 50) {
      debugPrint('Image still over 1MB after compression, retrying with lower quality');
      return compressImage(file, quality: compressionQuality - 15);
    }

    return compressedFile;
  }

  /// Compress multiple images
  Future<List<File>> compressImages(List<File> files, {int quality = 85}) async {
    final compressed = <File>[];

    for (final file in files) {
      final result = await compressImage(file, quality: quality);
      if (result != null) {
        compressed.add(result);
      }
    }

    return compressed;
  }

  /// Get file size in MB
  double getFileSizeMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  /// Validate image file
  String? validateImage(File file) {
    final extension = path.extension(file.path).toLowerCase();
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

    if (!allowedExtensions.contains(extension)) {
      return 'Invalid image format. Use JPG, PNG, or WebP.';
    }

    final sizeMB = getFileSizeMB(file);
    if (sizeMB > AppConfig.maxImageSizeMB) {
      return 'Image too large. Maximum size is ${AppConfig.maxImageSizeMB}MB.';
    }

    return null;
  }

  /// Clean up temporary compressed files
  Future<void> cleanupTempFiles(List<File> files) async {
    for (final file in files) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting temp file: $e');
      }
    }
  }
}
