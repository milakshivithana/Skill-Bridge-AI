class CVDocumentModel {
  final int id;
  final int candidateId;
  final String fileName;
  final String? fileUrl;
  final String? contentType;
  final int fileSizeBytes;
  final DateTime uploadedAt;

  CVDocumentModel({
    required this.id,
    required this.candidateId,
    required this.fileName,
    this.fileUrl,
    this.contentType,
    required this.fileSizeBytes,
    required this.uploadedAt,
  });

  factory CVDocumentModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return CVDocumentModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      candidateId: json['candidateId'] is int
          ? json['candidateId']
          : int.tryParse(json['candidateId']?.toString() ?? '0') ?? 0,
      fileName: json['fileName']?.toString() ?? 'Resume.pdf',
      fileUrl: json['fileUrl']?.toString(),
      contentType: json['contentType']?.toString(),
      fileSizeBytes: json['fileSizeBytes'] is int
          ? json['fileSizeBytes']
          : int.tryParse(json['fileSizeBytes']?.toString() ?? '0') ?? 0,
      uploadedAt: parseDate(json['uploadedAt']),
    );
  }

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
