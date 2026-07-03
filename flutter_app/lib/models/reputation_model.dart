import '../core/json_reader.dart';

class ReputationModel {
  final int trust;
  final int safety;
  final int professionalism;
  final int reliability;
  final int stakeholderConfidence;

  const ReputationModel({
    this.trust = 0,
    this.safety = 0,
    this.professionalism = 0,
    this.reliability = 0,
    this.stakeholderConfidence = 0,
  });

  static const ReputationModel zero = ReputationModel();

  factory ReputationModel.fromJson(Map<String, dynamic> json) {
    return ReputationModel(
      trust: JsonReader.readInt(json, 'trust', parent: 'reputationImpact'),
      safety: JsonReader.readInt(json, 'safety', parent: 'reputationImpact'),
      professionalism: JsonReader.readInt(
        json,
        'professionalism',
        parent: 'reputationImpact',
      ),
      reliability: JsonReader.readInt(
        json,
        'reliability',
        parent: 'reputationImpact',
      ),
      stakeholderConfidence: JsonReader.readInt(
        json,
        'stakeholderConfidence',
        parent: 'reputationImpact',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'trust': trust,
      'safety': safety,
      'professionalism': professionalism,
      'reliability': reliability,
      'stakeholderConfidence': stakeholderConfidence,
    };
  }

  ReputationModel add(ReputationModel other) {
    return ReputationModel(
      trust: trust + other.trust,
      safety: safety + other.safety,
      professionalism: professionalism + other.professionalism,
      reliability: reliability + other.reliability,
      stakeholderConfidence: stakeholderConfidence + other.stakeholderConfidence,
    );
  }

  int get total =>
      trust + safety + professionalism + reliability + stakeholderConfidence;

  List<String> strengths() {
    final items = <String, int>{
      'Trust': trust,
      'Safety': safety,
      'Professionalism': professionalism,
      'Reliability': reliability,
      'Stakeholder Confidence': stakeholderConfidence,
    }.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return items.where((item) => item.value > 0).take(3).map((item) {
      return '${item.key} +${item.value}';
    }).toList(growable: false);
  }

  List<String> weaknesses() {
    final items = <String, int>{
      'Trust': trust,
      'Safety': safety,
      'Professionalism': professionalism,
      'Reliability': reliability,
      'Stakeholder Confidence': stakeholderConfidence,
    }.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return items.where((item) => item.value < 0).take(3).map((item) {
      return '${item.key} ${item.value}';
    }).toList(growable: false);
  }
}
