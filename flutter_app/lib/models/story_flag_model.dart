class StoryFlagModel {
  final String id;
  final String label;
  final String description;
  final String category;
  final bool isPositive;

  const StoryFlagModel({
    required this.id,
    this.label = '',
    this.description = '',
    this.category = 'general',
    this.isPositive = false,
  });

  factory StoryFlagModel.fromJson(Map<String, dynamic> json) {
    return StoryFlagModel(
      id: _readString(json['id']),
      label: _readString(json['label']),
      description: _readString(json['description']),
      category: _readString(json['category'], fallback: 'general'),
      isPositive: json['isPositive'] is bool ? json['isPositive'] as bool : false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'description': description,
      'category': category,
      'isPositive': isPositive,
    };
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }
}
