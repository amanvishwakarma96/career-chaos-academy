import '../core/json_reader.dart';
import 'outcome_model.dart';
import 'score_model.dart';

class ChoiceModel {
  final String text;
  final OutcomeModel outcome;
  final ScoreModel scoreImpact;

  const ChoiceModel({
    required this.text,
    required this.outcome,
    required this.scoreImpact,
  });

  factory ChoiceModel.fromJson(Map<String, dynamic> json) {
    return ChoiceModel(
      text: JsonReader.readString(json, 'text', parent: 'choice'),
      outcome: OutcomeModel.fromJson(
        JsonReader.readMap(json, 'outcome', parent: 'choice'),
      ),
      scoreImpact: ScoreModel.fromJson(
        JsonReader.readMap(json, 'scoreImpact', parent: 'choice'),
      ),
    );
  }
}
