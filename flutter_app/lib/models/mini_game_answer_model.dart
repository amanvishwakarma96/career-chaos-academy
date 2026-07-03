class MiniGameAnswerModel {
  final Set<String> selectedOptionIds;
  final Map<String, String> pairAnswers;
  final List<String> orderedItemIds;

  const MiniGameAnswerModel({
    this.selectedOptionIds = const <String>{},
    this.pairAnswers = const <String, String>{},
    this.orderedItemIds = const <String>[],
  });
}
