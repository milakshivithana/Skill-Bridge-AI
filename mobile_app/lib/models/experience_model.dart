class ExperienceModel {
  final int id;
  final int candidateId;
  final String company;
  final String title;
  final String? location;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? description;

  ExperienceModel({
    required this.id,
    required this.candidateId,
    required this.company,
    required this.title,
    this.location,
    required this.startDate,
    this.endDate,
    required this.isCurrent,
    this.description,
  });

  factory ExperienceModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return ExperienceModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      candidateId: json['candidateId'] is int
          ? json['candidateId']
          : int.tryParse(json['candidateId']?.toString() ?? '0') ?? 0,
      company: json['company']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      location: json['location']?.toString(),
      startDate: parseDate(json['startDate']),
      endDate: json['endDate'] != null ? parseDate(json['endDate']) : null,
      isCurrent: json['isCurrent'] == true,
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'company': company,
        'title': title,
        'location': location,
        'startDate': startDate.toIso8601String(),
        if (endDate != null && !isCurrent)
          'endDate': endDate!.toIso8601String(),
        'isCurrent': isCurrent,
        if (description != null) 'description': description,
      };

  String get durationText {
    final startStr = '${startDate.month}/${startDate.year}';
    final endStr = isCurrent
        ? 'Present'
        : (endDate != null ? '${endDate!.month}/${endDate!.year}' : 'Present');
    return '$startStr – $endStr';
  }
}
