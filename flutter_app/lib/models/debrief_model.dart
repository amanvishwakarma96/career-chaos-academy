class DebriefModel {
  final String whatWentWell;
  final String whatWasMissed;
  final String realWorldPrinciple;

  const DebriefModel({
    this.whatWentWell = '',
    this.whatWasMissed = '',
    this.realWorldPrinciple = '',
  });

  static const DebriefModel empty = DebriefModel();

  factory DebriefModel.fromJson(Map<String, dynamic> json) {
    return DebriefModel(
      whatWentWell: _readString(json['whatWentWell']),
      whatWasMissed: _readString(json['whatWasMissed']),
      realWorldPrinciple: _readString(json['realWorldPrinciple']),
    );
  }

  static String _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return '';
  }

  bool get hasContent =>
      whatWentWell.isNotEmpty ||
      whatWasMissed.isNotEmpty ||
      realWorldPrinciple.isNotEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'whatWentWell': whatWentWell,
      'whatWasMissed': whatWasMissed,
      'realWorldPrinciple': realWorldPrinciple,
    };
  }
}
