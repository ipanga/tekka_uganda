/// Report reason categories
enum ReportReason {
  spam,
  scam,
  inappropriateContent,
  harassment,
  fakeProfile,
  counterfeitItems,
  noShow,
  other,
}

/// Extension for report reason display
extension ReportReasonExtension on ReportReason {
  String get displayName {
    switch (this) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.scam:
        return 'Scam or fraud';
      case ReportReason.inappropriateContent:
        return 'Inappropriate content';
      case ReportReason.harassment:
        return 'Harassment or bullying';
      case ReportReason.fakeProfile:
        return 'Fake profile';
      case ReportReason.counterfeitItems:
        return 'Counterfeit items';
      case ReportReason.noShow:
        return 'No-show at meetup';
      case ReportReason.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case ReportReason.spam:
        return 'Unwanted promotional content or repeated messages';
      case ReportReason.scam:
        return 'Attempting to deceive or defraud users';
      case ReportReason.inappropriateContent:
        return 'Offensive, explicit, or inappropriate content';
      case ReportReason.harassment:
        return 'Threatening, abusive, or harassing behavior';
      case ReportReason.fakeProfile:
        return 'Impersonation or misleading profile information';
      case ReportReason.counterfeitItems:
        return 'Selling fake or counterfeit products';
      case ReportReason.noShow:
        return 'Did not show up to agreed meetup';
      case ReportReason.other:
        return 'Other reason not listed above';
    }
  }
}

/// Report status
enum ReportStatus {
  pending,
  reviewed,
  actionTaken,
  dismissed,
}

/// Report entity
class Report {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reportedUserId;
  final String reportedUserName;
  final ReportReason reason;
  final String? additionalDetails;
  final String? listingId;
  final String? chatId;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? adminNotes;

  const Report({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.reason,
    this.additionalDetails,
    this.listingId,
    this.chatId,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.reviewedAt,
    this.adminNotes,
  });

  Report copyWith({
    String? id,
    String? reporterId,
    String? reporterName,
    String? reportedUserId,
    String? reportedUserName,
    ReportReason? reason,
    String? additionalDetails,
    String? listingId,
    String? chatId,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? adminNotes,
  }) {
    return Report(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reportedUserName: reportedUserName ?? this.reportedUserName,
      reason: reason ?? this.reason,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      listingId: listingId ?? this.listingId,
      chatId: chatId ?? this.chatId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'reason': reason.name,
      'additionalDetails': additionalDetails,
      'listingId': listingId,
      'chatId': chatId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'adminNotes': adminNotes,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] as String,
      reporterId: map['reporterId'] as String,
      reporterName: map['reporterName'] as String,
      reportedUserId: map['reportedUserId'] as String,
      reportedUserName: map['reportedUserName'] as String,
      reason: ReportReason.values.firstWhere(
        (e) => e.name == map['reason'],
        orElse: () => ReportReason.other,
      ),
      additionalDetails: map['additionalDetails'] as String?,
      listingId: map['listingId'] as String?,
      chatId: map['chatId'] as String?,
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.parse(map['reviewedAt'] as String)
          : null,
      adminNotes: map['adminNotes'] as String?,
    );
  }
}

/// Request to create a report
class CreateReportRequest {
  final String reportedUserId;
  final String reportedUserName;
  final ReportReason reason;
  final String? additionalDetails;
  final String? listingId;
  final String? chatId;

  const CreateReportRequest({
    required this.reportedUserId,
    required this.reportedUserName,
    required this.reason,
    this.additionalDetails,
    this.listingId,
    this.chatId,
  });
}
