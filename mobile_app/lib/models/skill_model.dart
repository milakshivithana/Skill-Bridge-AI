class SkillModel {
  final int id;
  final String name;
  final String category;

  SkillModel({
    required this.id,
    required this.name,
    required this.category,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
      };
}

class CandidateSkillModel {
  final int id;
  final int skillId;
  final String skillName;
  final String category;
  final int proficiencyLevel;
  final int yearsOfExperience;

  CandidateSkillModel({
    required this.id,
    required this.skillId,
    required this.skillName,
    required this.category,
    required this.proficiencyLevel,
    required this.yearsOfExperience,
  });

  factory CandidateSkillModel.fromJson(Map<String, dynamic> json) {
    return CandidateSkillModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      skillId: json['skillId'] is int
          ? json['skillId']
          : int.tryParse(json['skillId']?.toString() ?? '0') ?? 0,
      skillName: json['skillName']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      proficiencyLevel: json['proficiencyLevel'] is int
          ? json['proficiencyLevel']
          : int.tryParse(json['proficiencyLevel']?.toString() ?? '1') ?? 1,
      yearsOfExperience: json['yearsOfExperience'] is int
          ? json['yearsOfExperience']
          : int.tryParse(json['yearsOfExperience']?.toString() ?? '0') ?? 0,
    );
  }

  String get proficiencyLabel {
    switch (proficiencyLevel) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Intermediate';
      case 3:
        return 'Advanced';
      case 4:
        return 'Expert';
      case 5:
        return 'Master';
      default:
        return 'Level $proficiencyLevel';
    }
  }
}
