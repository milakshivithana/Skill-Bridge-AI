class VacancySkill {
  final int skillId;
  final String skillName;
  final String category;
  final bool isMandatory;

  VacancySkill({
    required this.skillId,
    required this.skillName,
    required this.category,
    required this.isMandatory,
  });

  factory VacancySkill.fromJson(Map<String, dynamic> json) {
    return VacancySkill(
      skillId: json['skillId'] ?? 0,
      skillName: json['skillName'] ?? '',
      category: json['category'] ?? '',
      isMandatory: json['isMandatory'] ?? true,
    );
  }
}

class VacancyRequirement {
  final int id;
  final String requirementText;
  final bool isNonNegotiable;

  VacancyRequirement({
    required this.id,
    required this.requirementText,
    required this.isNonNegotiable,
  });

  factory VacancyRequirement.fromJson(Map<String, dynamic> json) {
    return VacancyRequirement(
      id: json['id'] ?? 0,
      requirementText: json['requirementText'] ?? '',
      isNonNegotiable: json['isNonNegotiable'] ?? true,
    );
  }
}

class Vacancy {
  final bool hasApplied;
  final String? currentApplicationStatus;
  final int id;
  final int companyId;
  final String companyName;
  final String title;
  final String description;
  final String location;
  final String employmentType;
  final bool isActive;
  final DateTime applicationDeadline;
  final DateTime createdAt;
  final int applicationCount;
  final List<VacancySkill> skills;
  final List<VacancyRequirement> requirements;

  Vacancy({
    this.hasApplied = false,
    this.currentApplicationStatus,
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.title,
    required this.description,
    required this.location,
    required this.employmentType,
    required this.isActive,
    required this.applicationDeadline,
    required this.createdAt,
    required this.applicationCount,
    required this.skills,
    required this.requirements,
  });

  factory Vacancy.fromJson(Map<String, dynamic> json) {
    var skList = json['skills'] as List? ?? [];
    var reqList = json['requirements'] as List? ?? [];

    return Vacancy(
      hasApplied: json['hasApplied'] == true,
      currentApplicationStatus: json['currentApplicationStatus'],
      id: json['id'] ?? 0,
      companyId: json['companyId'] ?? 0,
      companyName:
          json['companyName'] ?? json['company']?['name'] ?? 'Independent',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? 'Colombo',
      employmentType: json['employmentType'] ?? 'Internship',
      isActive: json['isActive'] ?? true,
      applicationDeadline: json['applicationDeadline'] != null
          ? DateTime.parse(json['applicationDeadline'])
          : DateTime.now().add(const Duration(days: 30)),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      applicationCount: json['applicationCount'] ?? 0,
      skills: skList.map((s) => VacancySkill.fromJson(s)).toList(),
      requirements: reqList.map((r) => VacancyRequirement.fromJson(r)).toList(),
    );
  }
}

class SavedVacancy {
  final int id;
  final int candidateId;
  final int vacancyId;
  final String vacancyTitle;
  final String companyName;
  final String location;
  final String employmentType;
  final DateTime savedAt;

  SavedVacancy({
    required this.id,
    required this.candidateId,
    required this.vacancyId,
    required this.vacancyTitle,
    required this.companyName,
    required this.location,
    required this.employmentType,
    required this.savedAt,
  });

  factory SavedVacancy.fromJson(Map<String, dynamic> json) {
    return SavedVacancy(
      id: json['id'] ?? 0,
      candidateId: json['candidateId'] ?? 0,
      vacancyId: json['vacancyId'] ?? 0,
      vacancyTitle: json['vacancyTitle'] ?? '',
      companyName: json['companyName'] ?? '',
      location: json['location'] ?? '',
      employmentType: json['employmentType'] ?? '',
      savedAt: json['savedAt'] != null
          ? DateTime.parse(json['savedAt'])
          : DateTime.now(),
    );
  }
}
