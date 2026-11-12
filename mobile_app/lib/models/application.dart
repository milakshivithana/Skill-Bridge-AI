class ApplicationStatusHistory {
  final int id;
  final String status;
  final String notes;
  final DateTime changedAt;

  ApplicationStatusHistory({
    required this.id,
    required this.status,
    required this.notes,
    required this.changedAt,
  });

  factory ApplicationStatusHistory.fromJson(Map<String, dynamic> json) {
    return ApplicationStatusHistory(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      notes: json['notes'] ?? '',
      changedAt: json['changedAt'] != null
          ? DateTime.parse(json['changedAt'])
          : DateTime.now(),
    );
  }
}

class ApplicationEvaluation {
  final double matchScore;
  final Map<String, dynamic>? evidence;
  ApplicationEvaluation({required this.matchScore, this.evidence});
  factory ApplicationEvaluation.fromJson(Map<String, dynamic> json) =>
      ApplicationEvaluation(
        matchScore: (json['matchScore'] as num).toDouble(),
        evidence: json['evidence'] as Map<String, dynamic>?,
      );
}

class CandidateApplication {
  final ApplicationEvaluation? evaluation;
  bool get canEvaluate =>
      status == 'SUBMITTED' || status == 'REVISION_REQUESTED';
  final int id;
  final int candidateId;
  final String candidateName;
  final String candidateEmail;
  final int vacancyId;
  final String vacancyTitle;
  final String companyName;
  final String status;
  final double matchScore;
  final bool eligibilityPassed;
  final DateTime appliedAt;
  final DateTime updatedAt;
  final List<ApplicationStatusHistory> statusHistories;

  CandidateApplication({
    this.evaluation,
    required this.id,
    required this.candidateId,
    required this.candidateName,
    required this.candidateEmail,
    required this.vacancyId,
    required this.vacancyTitle,
    required this.companyName,
    required this.status,
    required this.matchScore,
    required this.eligibilityPassed,
    required this.appliedAt,
    required this.updatedAt,
    required this.statusHistories,
  });

  factory CandidateApplication.fromJson(Map<String, dynamic> json) {
    var historyList = json['statusHistories'] as List? ?? [];

    return CandidateApplication(
      evaluation: json['evaluation'] == null
          ? null
          : ApplicationEvaluation.fromJson(json['evaluation']),
      id: json['id'] ?? 0,
      candidateId: json['candidateId'] ?? 0,
      candidateName: json['candidateName'] ?? '',
      candidateEmail: json['candidateEmail'] ?? '',
      vacancyId: json['vacancyId'] ?? 0,
      vacancyTitle: json['vacancyTitle'] ?? 'Vacancy #${json['vacancyId']}',
      companyName: json['companyName'] ?? 'Independent',
      status: json['status'] ?? 'SUBMITTED',
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
      eligibilityPassed: json['eligibilityPassed'] ?? false,
      appliedAt: json['appliedAt'] != null
          ? DateTime.parse(json['appliedAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      statusHistories:
          historyList.map((h) => ApplicationStatusHistory.fromJson(h)).toList(),
    );
  }
}

class EligibilityResult {
  final int candidateId;
  final int vacancyId;
  final bool isEligible;
  final List<String> passedRequirements;
  final List<String> failedRequirements;
  final List<String> matchedSkills;
  final List<String> missingMandatorySkills;
  final String summaryNotes;

  EligibilityResult({
    required this.candidateId,
    required this.vacancyId,
    required this.isEligible,
    required this.passedRequirements,
    required this.failedRequirements,
    required this.matchedSkills,
    required this.missingMandatorySkills,
    required this.summaryNotes,
  });

  factory EligibilityResult.fromJson(Map<String, dynamic> json) {
    return EligibilityResult(
      candidateId: json['candidateId'] ?? 0,
      vacancyId: json['vacancyId'] ?? 0,
      isEligible: json['isEligible'] ?? false,
      passedRequirements: List<String>.from(json['passedRequirements'] ?? []),
      failedRequirements: List<String>.from(json['failedRequirements'] ?? []),
      matchedSkills: List<String>.from(json['matchedSkills'] ?? []),
      missingMandatorySkills:
          List<String>.from(json['missingMandatorySkills'] ?? []),
      summaryNotes: json['summaryNotes'] ?? '',
    );
  }
}
