enum SafetyReviewStatus { draft, pending, approved, rejected, needsChanges }

class SafetyReviewModel {
  final SafetyReviewStatus status;
  final String reviewedBy;
  final String reviewedAt;
  final List<String> domains;
  final List<String> guardrails;
  final String notes;

  const SafetyReviewModel({
    this.status = SafetyReviewStatus.draft,
    this.reviewedBy = '',
    this.reviewedAt = '',
    this.domains = const <String>[],
    this.guardrails = const <String>[],
    this.notes = '',
  });

  static const draft = SafetyReviewModel();

  factory SafetyReviewModel.fromJson(Map<String, dynamic> json) {
    return SafetyReviewModel(
      status: _readStatus(json['status']),
      reviewedBy: _readString(json['reviewedBy']),
      reviewedAt: _readString(json['reviewedAt']),
      domains: _readStringList(json['domains']),
      guardrails: _readStringList(json['guardrails']),
      notes: _readString(json['notes']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status.name,
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt,
        'domains': domains,
        'guardrails': guardrails,
        'notes': notes,
      };

  bool get isApproved => status == SafetyReviewStatus.approved;

  static SafetyReviewStatus _readStatus(Object? value) {
    final raw = value is String ? value.trim().toLowerCase() : '';
    switch (raw) {
      case 'pending':
        return SafetyReviewStatus.pending;
      case 'approved':
        return SafetyReviewStatus.approved;
      case 'rejected':
        return SafetyReviewStatus.rejected;
      case 'needschanges':
      case 'needs_changes':
        return SafetyReviewStatus.needsChanges;
      default:
        return SafetyReviewStatus.draft;
    }
  }

  static String _readString(Object? value) => value is String ? value.trim() : '';
  static List<String> _readStringList(Object? value) {
    if (value is! List) return const <String>[];
    return value.whereType<String>().where((item) => item.trim().isNotEmpty).toList(growable: false);
  }
}
