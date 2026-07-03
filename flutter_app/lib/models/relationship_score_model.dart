class RelationshipScoreModel {
  final int mentorTrust;
  final int clientTrust;
  final int teamTrust;
  final int publicReputation;

  static const zero = RelationshipScoreModel();

  const RelationshipScoreModel({
    this.mentorTrust = 0,
    this.clientTrust = 0,
    this.teamTrust = 0,
    this.publicReputation = 0,
  });

  int get total => mentorTrust + clientTrust + teamTrust + publicReputation;

  RelationshipScoreModel add(RelationshipScoreModel other) {
    return RelationshipScoreModel(
      mentorTrust: mentorTrust + other.mentorTrust,
      clientTrust: clientTrust + other.clientTrust,
      teamTrust: teamTrust + other.teamTrust,
      publicReputation: publicReputation + other.publicReputation,
    );
  }

  RelationshipScoreModel clamp({int min = -100, int max = 100}) {
    return RelationshipScoreModel(
      mentorTrust: mentorTrust.clamp(min, max).toInt(),
      clientTrust: clientTrust.clamp(min, max).toInt(),
      teamTrust: teamTrust.clamp(min, max).toInt(),
      publicReputation: publicReputation.clamp(min, max).toInt(),
    );
  }

  bool meets(RelationshipScoreModel required) {
    return mentorTrust >= required.mentorTrust &&
        clientTrust >= required.clientTrust &&
        teamTrust >= required.teamTrust &&
        publicReputation >= required.publicReputation;
  }

  factory RelationshipScoreModel.fromJson(Map<String, dynamic> json) {
    return RelationshipScoreModel(
      mentorTrust: _readInt(json['mentorTrust']),
      clientTrust: _readInt(json['clientTrust']),
      teamTrust: _readInt(json['teamTrust']),
      publicReputation: _readInt(json['publicReputation']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mentorTrust': mentorTrust,
      'clientTrust': clientTrust,
      'teamTrust': teamTrust,
      'publicReputation': publicReputation,
    };
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return 0;
  }
}
