/// Quick reply template entity
class QuickReplyTemplate {
  final String id;
  final String text;
  final String? category;
  final int usageCount;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final bool isDefault;

  QuickReplyTemplate({
    required this.id,
    required this.text,
    this.category,
    this.usageCount = 0,
    DateTime? createdAt,
    this.lastUsedAt,
    this.isDefault = false,
  }) : createdAt = createdAt ?? DateTime.now();

  QuickReplyTemplate copyWith({
    String? id,
    String? text,
    String? category,
    int? usageCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool? isDefault,
  }) {
    return QuickReplyTemplate(
      id: id ?? this.id,
      text: text ?? this.text,
      category: category ?? this.category,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'usageCount': usageCount,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  factory QuickReplyTemplate.fromMap(Map<String, dynamic> map) {
    return QuickReplyTemplate(
      id: map['id'] as String,
      text: map['text'] as String,
      category: map['category'] as String?,
      usageCount: map['usageCount'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastUsedAt: map['lastUsedAt'] != null
          ? DateTime.parse(map['lastUsedAt'] as String)
          : null,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  /// Factory for parsing API JSON response
  factory QuickReplyTemplate.fromJson(Map<String, dynamic> json) {
    return QuickReplyTemplate(
      id: json['id'] as String,
      text: json['text'] as String,
      category: json['category'] as String?,
      usageCount: json['usageCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => toMap();
}

/// Categories for quick reply templates
enum TemplateCategory {
  greeting('Greeting', 'Hi, hello, etc.'),
  availability('Availability', 'Is this available?'),
  pricing('Pricing', 'Price negotiations'),
  meetup('Meetup', 'Meeting arrangements'),
  thanks('Thanks', 'Thank you messages'),
  custom('Custom', 'Your custom templates');

  final String displayName;
  final String description;
  const TemplateCategory(this.displayName, this.description);
}

/// Get default quick reply templates
List<QuickReplyTemplate> getDefaultTemplates() {
  return [
    // Buyer templates
    QuickReplyTemplate(
      id: 'default_1',
      text: 'Is this still available?',
      category: 'availability',
      isDefault: true,
    ),
    QuickReplyTemplate(
      id: 'default_2',
      text: "What's your lowest price?",
      category: 'pricing',
      isDefault: true,
    ),
    QuickReplyTemplate(
      id: 'default_3',
      text: 'Can we arrange a meetup?',
      category: 'meetup',
      isDefault: true,
    ),
    QuickReplyTemplate(
      id: 'default_4',
      text: 'Can you send more photos?',
      category: 'availability',
      isDefault: true,
    ),
    QuickReplyTemplate(
      id: 'default_5',
      text: 'Is the price negotiable?',
      category: 'pricing',
      isDefault: true,
    ),
    // Seller templates
    QuickReplyTemplate(
      id: 'default_6',
      text: 'Yes, it is still available!',
      category: 'availability',
      isDefault: true,
    ),
    QuickReplyTemplate(
      id: 'default_7',
      text: 'The price is fixed, sorry.',
      category: 'pricing',
      isDefault: true,
    ),
    QuickReplyTemplate(
      id: 'default_8',
      text: "I can do a small discount if you're buying today.",
      category: 'pricing',
      isDefault: true,
    ),
    QuickReplyTemplate(
      id: 'default_9',
      text: 'When would you like to meet?',
      category: 'meetup',
      isDefault: true,
    ),
    QuickReplyTemplate(
      id: 'default_10',
      text: 'Thank you for your interest!',
      category: 'thanks',
      isDefault: true,
    ),
  ];
}
