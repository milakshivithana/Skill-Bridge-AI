class ProfileCompletenessModel {
  final int candidateId;
  final int completionPercentage;
  final bool isEligibleForApplication;
  final List<String> completedFields;
  final List<String> missingFields;

  ProfileCompletenessModel({
    required this.candidateId,
    required this.completionPercentage,
    required this.isEligibleForApplication,
    required this.completedFields,
    required this.missingFields,
  });

  factory ProfileCompletenessModel.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    final rawPct =
        json['completionPercentage'] ?? json['profileScorePercentage'];
    final pct =
        rawPct is int ? rawPct : int.tryParse(rawPct?.toString() ?? '0') ?? 0;

    final isEligible = json['isEligibleForApplication'] == true ||
        json['isComplete'] == true ||
        json['isProfileComplete'] == true ||
        pct == 100;

    return ProfileCompletenessModel(
      candidateId: json['candidateId'] is int
          ? json['candidateId']
          : int.tryParse(json['candidateId']?.toString() ?? '0') ?? 0,
      completionPercentage: pct,
      isEligibleForApplication: isEligible,
      completedFields: parseList(json['completedFields']),
      missingFields: parseList(json['missingFields']),
    );
  }
}
