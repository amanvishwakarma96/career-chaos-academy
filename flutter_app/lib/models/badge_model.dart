class BadgeModel {
  final String id;
  final String title;
  final String description;
  final String lockedHint;
  final String iconKey;

  const BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.lockedHint,
    required this.iconKey,
  });
}
