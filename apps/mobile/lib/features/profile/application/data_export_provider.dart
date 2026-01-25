import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Data export status
enum DataExportStatus {
  idle,
  collecting,
  packaging,
  ready,
  error,
}

/// Types of data that can be exported
enum ExportDataType {
  profile('Profile Information', 'Your account details and preferences'),
  listings('Your Listings', 'Items you have listed for sale'),
  purchases('Purchase History', 'Items you have purchased'),
  sales('Sales History', 'Items you have sold'),
  favorites('Favorites', 'Items you have saved'),
  messages('Messages', 'Your chat conversations'),
  reviews('Reviews', 'Reviews you have given and received'),
  searchHistory('Search History', 'Your recent searches'),
  activityLog('Activity Log', 'Your app activity');

  final String displayName;
  final String description;
  const ExportDataType(this.displayName, this.description);
}

/// State for data export
class DataExportState {
  final DataExportStatus status;
  final Set<ExportDataType> selectedTypes;
  final double progress;
  final String? currentStep;
  final String? exportFilePath;
  final String? errorMessage;
  final DateTime? exportDate;

  const DataExportState({
    this.status = DataExportStatus.idle,
    this.selectedTypes = const {},
    this.progress = 0.0,
    this.currentStep,
    this.exportFilePath,
    this.errorMessage,
    this.exportDate,
  });

  bool get isExporting =>
      status == DataExportStatus.collecting ||
      status == DataExportStatus.packaging;

  bool get hasExport => exportFilePath != null && status == DataExportStatus.ready;

  DataExportState copyWith({
    DataExportStatus? status,
    Set<ExportDataType>? selectedTypes,
    double? progress,
    String? currentStep,
    String? exportFilePath,
    String? errorMessage,
    DateTime? exportDate,
    bool clearError = false,
    bool clearExport = false,
  }) {
    return DataExportState(
      status: status ?? this.status,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      exportFilePath: clearExport ? null : (exportFilePath ?? this.exportFilePath),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      exportDate: clearExport ? null : (exportDate ?? this.exportDate),
    );
  }
}

/// Provider for data export functionality
class DataExportNotifier extends StateNotifier<DataExportState> {
  DataExportNotifier() : super(const DataExportState(
    selectedTypes: {
      ExportDataType.profile,
      ExportDataType.listings,
      ExportDataType.purchases,
      ExportDataType.sales,
      ExportDataType.favorites,
      ExportDataType.messages,
      ExportDataType.reviews,
    },
  ));

  /// Toggle a data type for export
  void toggleDataType(ExportDataType type) {
    final newSelection = Set<ExportDataType>.from(state.selectedTypes);
    if (newSelection.contains(type)) {
      newSelection.remove(type);
    } else {
      newSelection.add(type);
    }
    state = state.copyWith(selectedTypes: newSelection);
  }

  /// Select all data types
  void selectAll() {
    state = state.copyWith(
      selectedTypes: Set.from(ExportDataType.values),
    );
  }

  /// Deselect all data types
  void deselectAll() {
    state = state.copyWith(selectedTypes: {});
  }

  /// Start the data export process
  Future<void> startExport() async {
    if (state.selectedTypes.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please select at least one data type to export',
      );
      return;
    }

    state = state.copyWith(
      status: DataExportStatus.collecting,
      progress: 0.0,
      currentStep: 'Starting export...',
      clearError: true,
      clearExport: true,
    );

    try {
      final exportData = <String, dynamic>{
        'exportDate': DateTime.now().toIso8601String(),
        'appName': 'Tekka',
        'appVersion': '1.0.0',
        'dataTypes': state.selectedTypes.map((t) => t.name).toList(),
      };

      final totalTypes = state.selectedTypes.length;
      var completedTypes = 0;

      for (final type in state.selectedTypes) {
        state = state.copyWith(
          currentStep: 'Collecting ${type.displayName}...',
          progress: completedTypes / totalTypes * 0.8,
        );

        // Collect data for each type
        final data = await _collectData(type);
        exportData[type.name] = data;

        completedTypes++;

        // Small delay to show progress
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Package the data
      state = state.copyWith(
        status: DataExportStatus.packaging,
        currentStep: 'Packaging your data...',
        progress: 0.9,
      );

      final filePath = await _saveExportFile(exportData);

      state = state.copyWith(
        status: DataExportStatus.ready,
        progress: 1.0,
        currentStep: 'Export complete!',
        exportFilePath: filePath,
        exportDate: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        status: DataExportStatus.error,
        errorMessage: 'Failed to export data: ${e.toString()}',
        progress: 0.0,
        currentStep: null,
      );
    }
  }

  /// Collect data for a specific type
  Future<Map<String, dynamic>> _collectData(ExportDataType type) async {
    // Simulated data collection - in production, this would fetch from Firestore
    switch (type) {
      case ExportDataType.profile:
        return {
          'displayName': 'Demo User',
          'email': 'user@example.com',
          'phone': '+256700000000',
          'location': 'Kampala, Uganda',
          'joinDate': '2024-01-15T10:30:00Z',
          'bio': 'Fashion enthusiast',
          'profileComplete': true,
        };

      case ExportDataType.listings:
        return {
          'totalListings': 12,
          'activeListings': 8,
          'soldListings': 4,
          'items': [
            {
              'id': 'listing_001',
              'title': 'Vintage Denim Jacket',
              'price': 85000,
              'currency': 'UGX',
              'status': 'active',
              'createdAt': '2024-06-10T14:20:00Z',
            },
            // More items would be included in actual export
          ],
        };

      case ExportDataType.purchases:
        return {
          'totalPurchases': 5,
          'totalSpent': 425000,
          'currency': 'UGX',
          'items': [
            {
              'id': 'purchase_001',
              'itemTitle': 'Designer Handbag',
              'price': 150000,
              'date': '2024-05-20T09:15:00Z',
              'seller': 'FashionStore',
            },
          ],
        };

      case ExportDataType.sales:
        return {
          'totalSales': 4,
          'totalEarned': 340000,
          'currency': 'UGX',
          'items': [
            {
              'id': 'sale_001',
              'itemTitle': 'Casual Sneakers',
              'price': 75000,
              'date': '2024-05-15T16:30:00Z',
              'buyer': 'ShoeCollector',
            },
          ],
        };

      case ExportDataType.favorites:
        return {
          'totalFavorites': 23,
          'items': [
            {
              'id': 'fav_001',
              'itemId': 'item_123',
              'itemTitle': 'Summer Dress',
              'savedAt': '2024-06-01T11:00:00Z',
            },
          ],
        };

      case ExportDataType.messages:
        return {
          'totalConversations': 15,
          'totalMessages': 234,
          'conversations': [
            {
              'id': 'conv_001',
              'participant': 'Seller123',
              'messageCount': 12,
              'lastMessage': '2024-06-08T18:45:00Z',
              // Note: Full message content would be included
            },
          ],
        };

      case ExportDataType.reviews:
        return {
          'reviewsGiven': 3,
          'reviewsReceived': 5,
          'averageRating': 4.8,
          'given': [
            {
              'id': 'review_001',
              'toUser': 'GreatSeller',
              'rating': 5,
              'comment': 'Excellent quality!',
              'date': '2024-05-22T10:00:00Z',
            },
          ],
          'received': [
            {
              'id': 'review_002',
              'fromUser': 'HappyBuyer',
              'rating': 5,
              'comment': 'Fast shipping!',
              'date': '2024-05-25T14:30:00Z',
            },
          ],
        };

      case ExportDataType.searchHistory:
        return {
          'searches': [
            {'query': 'vintage jeans', 'date': '2024-06-09T08:00:00Z'},
            {'query': 'nike sneakers', 'date': '2024-06-08T15:30:00Z'},
            {'query': 'leather bag', 'date': '2024-06-07T12:00:00Z'},
          ],
        };

      case ExportDataType.activityLog:
        return {
          'activities': [
            {'action': 'login', 'date': '2024-06-09T07:30:00Z'},
            {'action': 'listing_created', 'date': '2024-06-08T14:20:00Z'},
            {'action': 'purchase', 'date': '2024-06-07T16:45:00Z'},
          ],
        };
    }
  }

  /// Save export data to a file
  Future<String> _saveExportFile(Map<String, dynamic> data) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'tekka_data_export_$timestamp.json';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(jsonString);

    return filePath;
  }

  /// Delete the exported file
  Future<void> deleteExport() async {
    if (state.exportFilePath != null) {
      try {
        final file = File(state.exportFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Ignore deletion errors
      }
    }

    state = state.copyWith(
      status: DataExportStatus.idle,
      clearExport: true,
    );
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Reset to initial state
  void reset() {
    state = const DataExportState(
      selectedTypes: {
        ExportDataType.profile,
        ExportDataType.listings,
        ExportDataType.purchases,
        ExportDataType.sales,
        ExportDataType.favorites,
        ExportDataType.messages,
        ExportDataType.reviews,
      },
    );
  }
}

/// Provider for data export
final dataExportProvider =
    StateNotifierProvider<DataExportNotifier, DataExportState>((ref) {
  return DataExportNotifier();
});
