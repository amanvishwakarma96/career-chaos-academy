import '../core/json_reader.dart';

class ScoreModel {
  final int skill;
  final int discipline;
  final int ethics;
  final int communication;
  final int chaos;

  const ScoreModel({
    this.skill = 0,
    this.discipline = 0,
    this.ethics = 0,
    this.communication = 0,
    this.chaos = 0,
  });

  static const ScoreModel zero = ScoreModel();

  factory ScoreModel.fromJson(Map<String, dynamic> json) {
    return ScoreModel(
      skill: JsonReader.readInt(json, 'skill', parent: 'scoreImpact'),
      discipline: JsonReader.readInt(
        json,
        'discipline',
        parent: 'scoreImpact',
      ),
      ethics: JsonReader.readInt(json, 'ethics', parent: 'scoreImpact'),
      communication: JsonReader.readInt(
        json,
        'communication',
        parent: 'scoreImpact',
      ),
      chaos: JsonReader.readInt(json, 'chaos', parent: 'scoreImpact'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'skill': skill,
      'discipline': discipline,
      'ethics': ethics,
      'communication': communication,
      'chaos': chaos,
    };
  }

  ScoreModel add(ScoreModel other) {
    return ScoreModel(
      skill: skill + other.skill,
      discipline: discipline + other.discipline,
      ethics: ethics + other.ethics,
      communication: communication + other.communication,
      chaos: chaos + other.chaos,
    );
  }

  int get total => skill + discipline + ethics + communication - chaos;
}
