class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? candidateId;
  final String? token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.candidateId,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['userId'] ?? json['id'];
    final id =
        rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    final rawCandidateId = json['candidateId'];
    final candidateId = rawCandidateId is int
        ? rawCandidateId
        : int.tryParse(rawCandidateId?.toString() ?? '');

    return UserModel(
      id: id,
      name: json['fullName']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      candidateId: candidateId,
      token: json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fullName': name,
      'email': email,
      'role': role,
      'candidateId': candidateId,
      if (token != null) 'token': token,
    };
  }
}
