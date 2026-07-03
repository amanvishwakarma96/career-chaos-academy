import 'package:flutter/foundation.dart';

import '../models/score_model.dart';

class ScoreService {
  ScoreService._();

  static final ScoreService instance = ScoreService._();

  final ValueNotifier<ScoreModel> score = ValueNotifier<ScoreModel>(
    ScoreModel.zero,
  );

  void apply(ScoreModel impact) {
    score.value = score.value.add(impact);
  }

  void setScore(ScoreModel updatedScore) {
    score.value = updatedScore;
  }

  void reset() {
    score.value = ScoreModel.zero;
  }
}
