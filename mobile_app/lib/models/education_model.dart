class EducationModel {
  final int id;
  final int candidateId;
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final int startYear;
  final int endYear;
  final String? grade;

  EducationModel({
    required this.id,
    required this.candidateId,
    required this.institution,
    required this.degree,
    required this.fieldOfStudy,
    required this.startYear,
    required this.endYear,
    this.grade,
  });

  factory EducationModel.fromJson(Map<String, dynamic> json) {
    final sYear = json['startYear'] is int
        ? json['startYear'] as int
        : int.tryParse(json['startYear']?.toString() ?? '2020') ?? 2020;
    return EducationModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      candidateId: json['candidateId'] is int
          ? json['candidateId']
          : int.tryParse(json['candidateId']?.toString() ?? '0') ?? 0,
      institution: json['institution']?.toString() ?? '',
      degree: json['degree']?.toString() ?? '',
      fieldOfStudy: json['fieldOfStudy']?.toString() ?? '',
      startYear: sYear,
      endYear: json['endYear'] is int
          ? json['endYear'] as int
          : int.tryParse(json['endYear']?.toString() ?? sYear.toString()) ??
              sYear,
      grade: json['grade']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'institution': institution,
        'degree': degree,
        'fieldOfStudy': fieldOfStudy,
        'startYear': startYear,
        'endYear': endYear,
        if (grade != null && grade!.isNotEmpty) 'grade': grade,
      };

  String get yearRange => '$startYear – $endYear';
}
