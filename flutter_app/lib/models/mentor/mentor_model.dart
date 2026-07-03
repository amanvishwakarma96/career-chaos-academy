import '../../core/json_reader.dart';

class MentorModel {
  final String id;
  final String name;
  final String title;
  final String style;
  final String description;
  final String archetype;
  final String emoji;
  final List<String> strengths;
  final List<String> encouragementLines;
  final List<String> roastLines;
  final String safetyBoundary;

  const MentorModel({
    required this.id,
    required this.name,
    required this.title,
    required this.style,
    required this.description,
    required this.archetype,
    required this.emoji,
    this.strengths = const <String>[],
    this.encouragementLines = const <String>[],
    this.roastLines = const <String>[],
    this.safetyBoundary = '',
  });

  factory MentorModel.fromJson(Map<String, dynamic> json) {
    return MentorModel(
      id: JsonReader.readString(json, 'id', parent: 'mentor'),
      name: JsonReader.readString(json, 'name', parent: 'mentor'),
      title: JsonReader.readString(json, 'title', parent: 'mentor'),
      style: JsonReader.readString(json, 'style', parent: 'mentor'),
      description: JsonReader.readString(json, 'description', parent: 'mentor'),
      archetype: JsonReader.readString(json, 'archetype', parent: 'mentor'),
      emoji: _readString(json['emoji'], '🧭'),
      strengths: _readStringList(json['strengths']),
      encouragementLines: _readStringList(json['encouragementLines']),
      roastLines: _readStringList(json['roastLines']),
      safetyBoundary: _readString(json['safetyBoundary'], ''),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'title': title,
      'style': style,
      'description': description,
      'archetype': archetype,
      'emoji': emoji,
      'strengths': strengths,
      'encouragementLines': encouragementLines,
      'roastLines': roastLines,
      'safetyBoundary': safetyBoundary,
    };
  }

  static String _readString(Object? value, String fallback) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

class MentorPreferenceModel {
  final String selectedMentorId;
  final bool roastModeEnabled;

  const MentorPreferenceModel({
    this.selectedMentorId = 'balanced_coach',
    this.roastModeEnabled = false,
  });

  static const MentorPreferenceModel defaults = MentorPreferenceModel();

  factory MentorPreferenceModel.fromJson(Map<String, dynamic> json) {
    return MentorPreferenceModel(
      selectedMentorId: _readString(json['selectedMentorId'], 'balanced_coach'),
      roastModeEnabled: json['roastModeEnabled'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'selectedMentorId': selectedMentorId,
      'roastModeEnabled': roastModeEnabled,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is MentorPreferenceModel &&
        other.selectedMentorId == selectedMentorId &&
        other.roastModeEnabled == roastModeEnabled;
  }

  @override
  int get hashCode => Object.hash(selectedMentorId, roastModeEnabled);

  MentorPreferenceModel copyWith({
    String? selectedMentorId,
    bool? roastModeEnabled,
  }) {
    return MentorPreferenceModel(
      selectedMentorId: selectedMentorId ?? this.selectedMentorId,
      roastModeEnabled: roastModeEnabled ?? this.roastModeEnabled,
    );
  }

  static String _readString(Object? value, String fallback) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }
}

class MentorFeedbackModel {
  final MentorModel mentor;
  final String headline;
  final String feedback;
  final List<String> weakAreas;
  final String nextActivitySuggestion;
  final String weeklySummary;
  final String? roastLine;
  final String safetyNote;

  const MentorFeedbackModel({
    required this.mentor,
    required this.headline,
    required this.feedback,
    this.weakAreas = const <String>[],
    this.nextActivitySuggestion = '',
    this.weeklySummary = '',
    this.roastLine,
    this.safetyNote = '',
  });

  bool get hasRoast => roastLine != null && roastLine!.trim().isNotEmpty;
}
