import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../auth/application/auth_provider.dart';

/// ID document types supported for verification
enum IdDocumentType { nationalId, passport, drivingLicense }

extension IdDocumentTypeExtension on IdDocumentType {
  String get displayName {
    switch (this) {
      case IdDocumentType.nationalId:
        return 'National ID';
      case IdDocumentType.passport:
        return 'Passport';
      case IdDocumentType.drivingLicense:
        return 'Driving License';
    }
  }

  String get description {
    switch (this) {
      case IdDocumentType.nationalId:
        return 'Ugandan National ID Card';
      case IdDocumentType.passport:
        return 'Valid Passport';
      case IdDocumentType.drivingLicense:
        return 'Valid Driving License';
    }
  }

  String get apiValue => name;

  static IdDocumentType? fromString(String? value) {
    if (value == null) return null;
    return IdDocumentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IdDocumentType.nationalId,
    );
  }
}

/// Identity verification state
enum IdentityVerificationState {
  initial,
  selectingDocument,
  enteringDetails,
  uploading,
  submitted,
  underReview,
  verified,
  rejected,
  error,
}

/// Identity verification status and data
class IdentityVerificationStatus {
  final IdentityVerificationState state;
  final IdDocumentType? documentType;
  final String? documentNumber;
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? frontImageUrl;
  final String? backImageUrl;
  final String? selfieUrl;
  final String? errorMessage;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;

  const IdentityVerificationStatus({
    this.state = IdentityVerificationState.initial,
    this.documentType,
    this.documentNumber,
    this.fullName,
    this.dateOfBirth,
    this.frontImageUrl,
    this.backImageUrl,
    this.selfieUrl,
    this.errorMessage,
    this.rejectionReason,
    this.submittedAt,
    this.verifiedAt,
  });

  IdentityVerificationStatus copyWith({
    IdentityVerificationState? state,
    IdDocumentType? documentType,
    String? documentNumber,
    String? fullName,
    DateTime? dateOfBirth,
    String? frontImageUrl,
    String? backImageUrl,
    String? selfieUrl,
    String? errorMessage,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? verifiedAt,
  }) {
    return IdentityVerificationStatus(
      state: state ?? this.state,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      frontImageUrl: frontImageUrl ?? this.frontImageUrl,
      backImageUrl: backImageUrl ?? this.backImageUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      errorMessage: errorMessage,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  factory IdentityVerificationStatus.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const IdentityVerificationStatus();

    final stateStr = map['state'] as String?;
    IdentityVerificationState state = IdentityVerificationState.initial;
    if (stateStr != null) {
      state = IdentityVerificationState.values.firstWhere(
        (e) => e.name == stateStr,
        orElse: () => IdentityVerificationState.initial,
      );
    }

    final docTypeStr = map['documentType'] as String?;
    IdDocumentType? docType = IdDocumentTypeExtension.fromString(docTypeStr);

    return IdentityVerificationStatus(
      state: state,
      documentType: docType,
      documentNumber: map['documentNumber'] as String?,
      fullName: map['fullName'] as String?,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'] as String)
          : null,
      frontImageUrl: map['frontImageUrl'] as String?,
      backImageUrl: map['backImageUrl'] as String?,
      selfieUrl: map['selfieUrl'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      submittedAt: map['submittedAt'] != null
          ? DateTime.parse(map['submittedAt'] as String)
          : null,
      verifiedAt: map['verifiedAt'] != null
          ? DateTime.parse(map['verifiedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'state': state.name,
      'documentType': documentType?.name,
      'documentNumber': documentNumber,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'frontImageUrl': frontImageUrl,
      'backImageUrl': backImageUrl,
      'selfieUrl': selfieUrl,
      'rejectionReason': rejectionReason,
      'submittedAt': submittedAt?.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }

  bool get canSubmit {
    return documentType != null &&
        documentNumber != null &&
        documentNumber!.isNotEmpty &&
        fullName != null &&
        fullName!.isNotEmpty &&
        dateOfBirth != null &&
        frontImageUrl != null;
  }

  bool get isComplete {
    return state == IdentityVerificationState.verified;
  }

  bool get isPending {
    return state == IdentityVerificationState.underReview ||
        state == IdentityVerificationState.submitted;
  }
}

/// Identity verification notifier
class IdentityVerificationNotifier
    extends StateNotifier<IdentityVerificationStatus> {
  final Ref _ref;

  IdentityVerificationNotifier(this._ref)
    : super(const IdentityVerificationStatus()) {
    _loadExistingVerification();
  }

  Future<void> _loadExistingVerification() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final repository = _ref.read(userApiRepositoryProvider);
      final data = await repository.getIdentityVerificationStatus();
      state = IdentityVerificationStatus.fromMap(data);
    } catch (e) {
      // Ignore errors on initial load
    }
  }

  void setDocumentType(IdDocumentType type) {
    state = state.copyWith(
      state: IdentityVerificationState.enteringDetails,
      documentType: type,
    );
  }

  void setDocumentDetails({
    required String documentNumber,
    required String fullName,
    required DateTime dateOfBirth,
  }) {
    state = state.copyWith(
      documentNumber: documentNumber,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
    );
  }

  void setFrontImage(String url) {
    state = state.copyWith(frontImageUrl: url);
  }

  void setBackImage(String url) {
    state = state.copyWith(backImageUrl: url);
  }

  void setSelfie(String url) {
    state = state.copyWith(selfieUrl: url);
  }

  Future<bool> submitVerification() async {
    if (!state.canSubmit) {
      state = state.copyWith(
        state: IdentityVerificationState.error,
        errorMessage: 'Please complete all required fields',
      );
      return false;
    }

    state = state.copyWith(state: IdentityVerificationState.uploading);

    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        state = state.copyWith(
          state: IdentityVerificationState.error,
          errorMessage: 'Not authenticated',
        );
        return false;
      }

      final repository = _ref.read(userApiRepositoryProvider);
      await repository.submitIdentityVerification(
        documentType: state.documentType!.apiValue,
        documentNumber: state.documentNumber!,
        fullName: state.fullName!,
        dateOfBirth: state.dateOfBirth!.toIso8601String(),
        frontImageUrl: state.frontImageUrl!,
        backImageUrl: state.backImageUrl,
        selfieUrl: state.selfieUrl,
      );

      state = state.copyWith(
        state: IdentityVerificationState.underReview,
        submittedAt: DateTime.now(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        state: IdentityVerificationState.error,
        errorMessage: 'Failed to submit verification. Please try again.',
      );
      return false;
    }
  }

  void reset() {
    state = const IdentityVerificationStatus();
  }

  void goBack() {
    switch (state.state) {
      case IdentityVerificationState.enteringDetails:
        state = state.copyWith(
          state: IdentityVerificationState.selectingDocument,
        );
        break;
      default:
        break;
    }
  }
}

/// Identity verification provider
final identityVerificationProvider =
    StateNotifierProvider<
      IdentityVerificationNotifier,
      IdentityVerificationStatus
    >((ref) => IdentityVerificationNotifier(ref));

/// Stream provider for identity verification status (using polling)
final identityVerificationStreamProvider =
    StreamProvider<IdentityVerificationStatus>((ref) {
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return Stream.value(const IdentityVerificationStatus());
      }

      final repository = ref.watch(userApiRepositoryProvider);

      late StreamController<IdentityVerificationStatus> controller;
      Timer? timer;
      bool isDisposed = false;

      Future<void> poll() async {
        if (isDisposed) return;
        try {
          final data = await repository.getIdentityVerificationStatus();
          if (!isDisposed) {
            controller.add(IdentityVerificationStatus.fromMap(data));
          }
        } catch (e) {
          if (!isDisposed) {
            controller.addError(e);
          }
        }
      }

      controller = StreamController<IdentityVerificationStatus>(
        onListen: () {
          poll();
          timer = Timer.periodic(const Duration(seconds: 60), (_) => poll());
        },
        onCancel: () {
          isDisposed = true;
          timer?.cancel();
        },
      );

      return controller.stream;
    });

/// Check if identity is verified
final isIdentityVerifiedProvider = Provider<bool>((ref) {
  final status = ref.watch(identityVerificationStreamProvider);
  return status.valueOrNull?.isComplete ?? false;
});

/// Check if identity verification is pending
final isIdentityPendingProvider = Provider<bool>((ref) {
  final status = ref.watch(identityVerificationStreamProvider);
  return status.valueOrNull?.isPending ?? false;
});
