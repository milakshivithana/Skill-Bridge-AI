class CertificateModel {
  final int id;
  final int candidateId;
  final String title;
  final String issuingOrganization;
  final DateTime issueDate;
  final DateTime? expiryDate;
  final String? credentialId;
  final String? credentialUrl;

  CertificateModel({
    required this.id,
    required this.candidateId,
    required this.title,
    required this.issuingOrganization,
    required this.issueDate,
    this.expiryDate,
    this.credentialId,
    this.credentialUrl,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return CertificateModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      candidateId: json['candidateId'] is int
          ? json['candidateId']
          : int.tryParse(json['candidateId']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      issuingOrganization: json['issuingOrganization']?.toString() ?? '',
      issueDate: parseDate(json['issueDate']),
      expiryDate:
          json['expiryDate'] != null ? parseDate(json['expiryDate']) : null,
      credentialId: json['credentialId']?.toString(),
      credentialUrl: json['credentialUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'issuingOrganization': issuingOrganization,
        'issueDate': issueDate.toIso8601String(),
        if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
        if (credentialId != null) 'credentialId': credentialId,
        if (credentialUrl != null) 'credentialUrl': credentialUrl,
      };
}
