/// Division within a city (e.g., Makindye, Nakawa)
class Division {
  final String id;
  final String? cityId;
  final String name;
  final bool isActive;
  final int sortOrder;
  final City? city;

  const Division({
    required this.id,
    this.cityId,
    required this.name,
    this.isActive = true,
    this.sortOrder = 0,
    this.city,
  });

  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id'] as String,
      cityId: json['cityId'] as String?,
      name: json['name'] as String,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      city: json['city'] != null
          ? City.fromJson(json['city'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cityId': cityId,
    'name': name,
    'isActive': isActive,
    'sortOrder': sortOrder,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Division && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// City (e.g., Kampala, Entebbe)
class City {
  final String id;
  final String name;
  final bool isActive;
  final int sortOrder;
  final List<Division> divisions;

  const City({
    required this.id,
    required this.name,
    this.isActive = true,
    this.sortOrder = 0,
    this.divisions = const [],
  });

  /// Get active divisions only
  List<Division> get activeDivisions =>
      divisions.where((d) => d.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  factory City.fromJson(Map<String, dynamic> json) {
    final divisionsJson = json['divisions'] as List<dynamic>? ?? [];
    return City(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      divisions: divisionsJson
          .map((e) => Division.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isActive': isActive,
    'sortOrder': sortOrder,
    'divisions': divisions.map((d) => d.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a selected location (city + optional division)
class SelectedLocation {
  final City city;
  final Division? division;

  const SelectedLocation({required this.city, this.division});

  /// Get display text (e.g., "Kampala, Makindye" or just "Kampala")
  String get displayText {
    if (division != null) {
      return '${city.name}, ${division!.name}';
    }
    return city.name;
  }

  /// Get city ID
  String get cityId => city.id;

  /// Get division ID (if selected)
  String? get divisionId => division?.id;
}
