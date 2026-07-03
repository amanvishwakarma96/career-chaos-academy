enum CareerRank {
  intern,
  junior,
  associate,
  professional,
  senior,
  expert,
  legend,
}

class RankModel {
  final CareerRank rank;
  final String title;
  final int minimumXp;
  final int? nextRankXp;

  const RankModel({
    required this.rank,
    required this.title,
    required this.minimumXp,
    this.nextRankXp,
  });

  double progressWithinRank(int xp) {
    final next = nextRankXp;
    if (next == null) {
      return 1;
    }

    final range = next - minimumXp;
    if (range <= 0) {
      return 1;
    }

    return ((xp - minimumXp) / range).clamp(0, 1).toDouble();
  }

  int xpToNextRank(int xp) {
    final next = nextRankXp;
    if (next == null) {
      return 0;
    }

    return (next - xp).clamp(0, next).toInt();
  }
}
