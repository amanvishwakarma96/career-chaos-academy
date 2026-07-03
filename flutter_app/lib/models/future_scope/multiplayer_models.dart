enum MultiplayerMode { solo, asyncChallenge, liveCoop }

class MultiplayerPlaceholderModel {
  final MultiplayerMode mode;
  final bool enabled;
  final String roomId;
  final List<String> participantIds;

  const MultiplayerPlaceholderModel({
    this.mode = MultiplayerMode.solo,
    this.enabled = false,
    this.roomId = '',
    this.participantIds = const <String>[],
  });

  factory MultiplayerPlaceholderModel.fromJson(Map<String, dynamic> json) {
    return MultiplayerPlaceholderModel(
      mode: _readMode(json['mode']),
      enabled: json['enabled'] is bool ? json['enabled'] as bool : false,
      roomId: json['roomId'] is String ? (json['roomId'] as String).trim() : '',
      participantIds: json['participantIds'] is List
          ? (json['participantIds'] as List).whereType<String>().toList(growable: false)
          : const <String>[],
    );
  }

  static MultiplayerMode _readMode(Object? value) {
    final raw = value is String ? value.trim().toLowerCase() : '';
    switch (raw) {
      case 'async_challenge':
      case 'asyncchallenge':
        return MultiplayerMode.asyncChallenge;
      case 'live_coop':
      case 'livecoop':
        return MultiplayerMode.liveCoop;
      default:
        return MultiplayerMode.solo;
    }
  }
}
