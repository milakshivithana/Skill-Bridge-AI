// SkillBridge AI — Module D Models
// Shortlist, Recommendation, Approval, AIWorkflow, AuditLog, Report

class Shortlist {
  final int id;
  final String title;
  final String vacancyTitle;
  final DateTime createdAt;
  final List<Recommendation> recommendations;

  const Shortlist({
    required this.id,
    required this.title,
    required this.vacancyTitle,
    required this.createdAt,
    required this.recommendations,
  });

  factory Shortlist.fromJson(Map<String, dynamic> json) {
    return Shortlist(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      vacancyTitle: json['vacancyTitle'] ?? 'N/A',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      recommendations: (json['recommendations'] as List? ?? [])
          .map((r) => Recommendation.fromJson(r))
          .toList(),
    );
  }
}

class Recommendation {
  final int id;
  final int applicationId;
  final int candidateId;
  final String candidateName;
  final String candidateEmail;
  final double calculatedScore;
  final String aiJustification;
  final String applicationStatus;

  const Recommendation({
    required this.id,
    required this.applicationId,
    required this.candidateId,
    required this.candidateName,
    required this.candidateEmail,
    required this.calculatedScore,
    required this.aiJustification,
    required this.applicationStatus,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] ?? 0,
      applicationId: json['applicationId'] ?? 0,
      candidateId: json['candidateId'] ?? 0,
      candidateName: json['candidateName'] ?? 'Unknown',
      candidateEmail: json['candidateEmail'] ?? '',
      calculatedScore: (json['calculatedScore'] ?? 0).toDouble(),
      aiJustification: json['aiJustification'] ?? '',
      applicationStatus: json['applicationStatus'] ?? 'UNKNOWN',
    );
  }
}

class Approval {
  final int id;
  final String decision;
  final String decisionBy;
  final String comments;
  final DateTime decisionAt;
  final int? applicationId;
  final String candidateName;
  final String vacancyTitle;

  const Approval({
    required this.id,
    required this.decision,
    required this.decisionBy,
    required this.comments,
    required this.decisionAt,
    this.applicationId,
    required this.candidateName,
    required this.vacancyTitle,
  });

  factory Approval.fromJson(Map<String, dynamic> json) {
    return Approval(
      id: json['id'] ?? 0,
      decision: json['decision'] ?? 'PENDING',
      decisionBy: json['decisionBy'] ?? 'System',
      comments: json['comments'] ?? '',
      decisionAt: DateTime.tryParse(json['decisionAt'] ?? '') ?? DateTime.now(),
      applicationId: json['applicationId'],
      candidateName: json['candidateName'] ?? 'Unknown',
      vacancyTitle: json['vacancyTitle'] ?? 'Unknown',
    );
  }
}

class AIWorkflow {
  final int id;
  final String workflowType;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final double? matchScore;
  final int? applicationId;
  final String candidateName;

  const AIWorkflow({
    required this.id,
    required this.workflowType,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.matchScore,
    this.applicationId,
    required this.candidateName,
  });

  factory AIWorkflow.fromJson(Map<String, dynamic> json) {
    return AIWorkflow(
      id: json['id'] ?? 0,
      workflowType: json['workflowType'] ?? 'RECRUITMENT',
      status: json['status'] ?? 'UNKNOWN',
      startedAt: DateTime.tryParse(json['startedAt'] ?? '') ?? DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      matchScore: json['matchScore'] != null
          ? (json['matchScore'] as num).toDouble()
          : null,
      applicationId: json['applicationId'],
      candidateName: json['candidateName'] ?? 'Unknown',
    );
  }
}

class AuditLog {
  final int id;
  final String entityName;
  final String action;
  final String performedBy;
  final DateTime timestamp;
  final String? details;

  const AuditLog({
    required this.id,
    required this.entityName,
    required this.action,
    required this.performedBy,
    required this.timestamp,
    this.details,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] ?? 0,
      entityName: json['entityType'] ?? '',
      action: json['action'] ?? '',
      performedBy: json['userId']?.toString() ?? 'System',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      details: json['summary'],
    );
  }
}

class AnalyticsSummary {
  final int totalApplications;
  final int totalApproved;
  final int totalRejected;
  final int totalPending;
  final double averageMatchScore;
  final int totalWorkflowsRun;

  const AnalyticsSummary({
    required this.totalApplications,
    required this.totalApproved,
    required this.totalRejected,
    required this.totalPending,
    required this.averageMatchScore,
    required this.totalWorkflowsRun,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalApplications: json['totalApplications'] ?? 0,
      totalApproved: json['approvedApplications'] ?? 0,
      totalRejected: json['rejectedApplications'] ?? 0,
      totalPending: json['pendingApprovals'] ?? 0,
      averageMatchScore: (json['averageMatchScore'] ?? 0).toDouble(),
      totalWorkflowsRun: json['totalAiWorkflowsRun'] ?? 0,
    );
  }
}
