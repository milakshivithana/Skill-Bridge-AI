class CandidatePreferenceModel {
  final int id;
  final int candidateId;
  final String? preferredRole;
  final String? preferredLocation;
  final String? employmentType;
  final double? minimumExpectedStipend;
  final bool openForRelocation;
  final bool openForRemote;

  CandidatePreferenceModel({
    required this.id,
    required this.candidateId,
    this.preferredRole,
    this.preferredLocation,
    this.employmentType,
    this.minimumExpectedStipend,
    required this.openForRelocation,
    required this.openForRemote,
  });

  factory CandidatePreferenceModel.fromJson(Map<String, dynamic> json) {
    double? parseNum(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    return CandidatePreferenceModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      candidateId: json['candidateId'] is int
          ? json['candidateId']
          : int.tryParse(json['candidateId']?.toString() ?? '0') ?? 0,
      preferredRole: json['preferredRole']?.toString(),
      preferredLocation: json['preferredLocation']?.toString(),
      employmentType: json['employmentType']?.toString(),
      minimumExpectedStipend: parseNum(json['minimumExpectedStipend']),
      openForRelocation: json['openForRelocation'] == true,
      openForRemote: json['openForRemote'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'preferredRole': preferredRole,
        'preferredLocation': preferredLocation,
        'employmentType': employmentType,
        'minimumExpectedStipend': minimumExpectedStipend,
        'openForRelocation': openForRelocation,
        'openForRemote': openForRemote,
      };
}
