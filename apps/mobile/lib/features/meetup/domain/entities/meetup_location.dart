/// Represents a safe meetup location
class MeetupLocation {
  final String id;
  final String name;
  final String address;
  final String area; // e.g., "Kampala CBD", "Ntinda"
  final double latitude;
  final double longitude;
  final MeetupLocationType type;
  final List<String> amenities; // e.g., "CCTV", "Security", "Parking"
  final String? description;
  final bool isVerified;
  final int usageCount; // How many meetups happened here

  const MeetupLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.amenities = const [],
    this.description,
    this.isVerified = false,
    this.usageCount = 0,
  });

  factory MeetupLocation.fromMap(Map<String, dynamic> map) {
    return MeetupLocation(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      area: map['area'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      type: MeetupLocationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MeetupLocationType.publicSpace,
      ),
      amenities: List<String>.from(map['amenities'] as List? ?? []),
      description: map['description'] as String?,
      isVerified: map['isVerified'] as bool? ?? false,
      usageCount: map['usageCount'] as int? ?? 0,
    );
  }

  /// Factory for parsing API JSON response
  factory MeetupLocation.fromJson(Map<String, dynamic> json) {
    return MeetupLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      area: json['area'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      type: _parseLocationType(json['type'] as String?),
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'] as List)
          : [],
      description: json['description'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      usageCount: json['usageCount'] as int? ?? 0,
    );
  }

  static MeetupLocationType _parseLocationType(String? type) {
    if (type == null) return MeetupLocationType.publicSpace;
    switch (type.toUpperCase()) {
      case 'MALL':
        return MeetupLocationType.mall;
      case 'CAFE':
        return MeetupLocationType.cafe;
      case 'PUBLIC_SPACE':
        return MeetupLocationType.publicSpace;
      case 'PETROL_STATION':
        return MeetupLocationType.petrolStation;
      case 'BANK':
        return MeetupLocationType.bank;
      case 'POLICE_STATION':
        return MeetupLocationType.policeStation;
      default:
        return MeetupLocationType.other;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      'amenities': amenities,
      'description': description,
      'isVerified': isVerified,
      'usageCount': usageCount,
    };
  }

  MeetupLocation copyWith({
    String? id,
    String? name,
    String? address,
    String? area,
    double? latitude,
    double? longitude,
    MeetupLocationType? type,
    List<String>? amenities,
    String? description,
    bool? isVerified,
    int? usageCount,
  }) {
    return MeetupLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      area: area ?? this.area,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      amenities: amenities ?? this.amenities,
      description: description ?? this.description,
      isVerified: isVerified ?? this.isVerified,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}

/// Type of meetup location
enum MeetupLocationType {
  mall('Shopping Mall'),
  cafe('Cafe / Restaurant'),
  publicSpace('Public Space'),
  petrolStation('Petrol Station'),
  bank('Bank / ATM'),
  policeStation('Police Station'),
  other('Other');

  final String displayName;
  const MeetupLocationType(this.displayName);
}

/// Scheduled meetup between buyer and seller
class ScheduledMeetup {
  final String id;
  final String chatId;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final MeetupLocation location;
  final DateTime scheduledAt;
  final MeetupStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? cancelReason;

  const ScheduledMeetup({
    required this.id,
    required this.chatId,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.location,
    required this.scheduledAt,
    this.status = MeetupStatus.proposed,
    this.notes,
    required this.createdAt,
    this.completedAt,
    this.cancelReason,
  });

  factory ScheduledMeetup.fromMap(Map<String, dynamic> map) {
    return ScheduledMeetup(
      id: map['id'] as String,
      chatId: map['chatId'] as String,
      listingId: map['listingId'] as String,
      buyerId: map['buyerId'] as String,
      sellerId: map['sellerId'] as String,
      location: MeetupLocation.fromMap(map['location'] as Map<String, dynamic>),
      scheduledAt: DateTime.parse(map['scheduledAt'] as String),
      status: MeetupStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MeetupStatus.proposed,
      ),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      cancelReason: map['cancelReason'] as String?,
    );
  }

  /// Factory for parsing API JSON response
  factory ScheduledMeetup.fromJson(Map<String, dynamic> json) {
    // API returns location as embedded object or as separate fields
    final locationData = json['location'] as Map<String, dynamic>?;
    final location = locationData != null
        ? MeetupLocation.fromJson(locationData)
        : MeetupLocation(
            id: json['locationId'] as String? ?? '',
            name: json['locationName'] as String? ?? '',
            address: json['locationAddress'] as String? ?? '',
            area: '',
            latitude: 0,
            longitude: 0,
            type: MeetupLocationType.other,
          );

    // Parse listing ID from embedded object or direct field
    final listing = json['listing'] as Map<String, dynamic>?;
    final listingId = listing?['id'] ?? json['listingId'] as String;

    return ScheduledMeetup(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      listingId: listingId,
      buyerId: json['buyerId'] as String,
      sellerId: json['sellerId'] as String,
      location: location,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      status: _parseMeetupStatus(json['status'] as String?),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      cancelReason: json['cancelReason'] as String?,
    );
  }

  static MeetupStatus _parseMeetupStatus(String? status) {
    if (status == null) return MeetupStatus.proposed;
    switch (status.toUpperCase()) {
      case 'PROPOSED':
        return MeetupStatus.proposed;
      case 'CONFIRMED':
        return MeetupStatus.confirmed;
      case 'COMPLETED':
        return MeetupStatus.completed;
      case 'CANCELLED':
        return MeetupStatus.cancelled;
      case 'NO_SHOW':
        return MeetupStatus.noShow;
      default:
        return MeetupStatus.proposed;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'listingId': listingId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'location': location.toMap(),
      'scheduledAt': scheduledAt.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelReason': cancelReason,
    };
  }

  ScheduledMeetup copyWith({
    String? id,
    String? chatId,
    String? listingId,
    String? buyerId,
    String? sellerId,
    MeetupLocation? location,
    DateTime? scheduledAt,
    MeetupStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? completedAt,
    String? cancelReason,
  }) {
    return ScheduledMeetup(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      listingId: listingId ?? this.listingId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      location: location ?? this.location,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }

  /// Check if meetup is upcoming (within next 24 hours)
  bool get isUpcoming {
    final now = DateTime.now();
    final diff = scheduledAt.difference(now);
    return diff.inHours >= 0 &&
        diff.inHours <= 24 &&
        status == MeetupStatus.confirmed;
  }

  /// Get formatted date
  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[scheduledAt.month - 1]} ${scheduledAt.day}';
  }

  /// Get formatted time
  String get formattedTime {
    final hour = scheduledAt.hour;
    final minute = scheduledAt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

/// Status of a scheduled meetup
enum MeetupStatus {
  proposed('Proposed'),
  confirmed('Confirmed'),
  completed('Completed'),
  cancelled('Cancelled'),
  noShow('No Show');

  final String displayName;
  const MeetupStatus(this.displayName);
}
