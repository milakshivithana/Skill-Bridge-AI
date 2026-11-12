import 'skill_model.dart';
import 'education_model.dart';
import 'experience_model.dart';
import 'preference_model.dart';
import 'cv_document_model.dart';
import 'certificate_model.dart';
import 'completeness_model.dart';

class CandidateProfileModel {
  final int id;
  final int userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? city;
  final String? bio;
  final String? linkedinUrl;
  final String? portfolioUrl;
  final String? gitHubUrl;
  final ProfileCompletenessModel? completeness;
  final List<CandidateSkillModel> skills;
  final List<EducationModel> educations;
  final List<ExperienceModel> experiences;
  final List<CertificateModel> certificates;
  final CandidatePreferenceModel? preferences;
  final CVDocumentModel? cvDocument;

  CandidateProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.city,
    this.bio,
    this.linkedinUrl,
    this.portfolioUrl,
    this.gitHubUrl,
    this.completeness,
    this.skills = const [],
    this.educations = const [],
    this.experiences = const [],
    this.certificates = const [],
    this.preferences,
    this.cvDocument,
  });

  factory CandidateProfileModel.fromJson(Map<String, dynamic> json) {
    return CandidateProfileModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      city: json['city']?.toString(),
      bio: json['bio']?.toString(),
      linkedinUrl: json['linkedinUrl']?.toString(),
      portfolioUrl: json['portfolioUrl']?.toString(),
      gitHubUrl: json['gitHubUrl']?.toString(),
      completeness: json['completeness'] != null
          ? ProfileCompletenessModel.fromJson(
              json['completeness'] as Map<String, dynamic>)
          : null,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) =>
                  CandidateSkillModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      educations: (json['educations'] as List<dynamic>?)
              ?.map((e) => EducationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      experiences: (json['experiences'] as List<dynamic>?)
              ?.map((e) => ExperienceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      certificates: (json['certificates'] as List<dynamic>?)
              ?.map((e) => CertificateModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      preferences: (json['preference'] != null || json['preferences'] != null)
          ? CandidatePreferenceModel.fromJson((json['preference'] ??
              json['preferences']) as Map<String, dynamic>)
          : null,
      cvDocument: json['cvDocument'] != null
          ? CVDocumentModel.fromJson(json['cvDocument'] as Map<String, dynamic>)
          : (json['cvDocuments'] is List &&
                  (json['cvDocuments'] as List).isNotEmpty
              ? CVDocumentModel.fromJson(
                  (json['cvDocuments'] as List).first as Map<String, dynamic>)
              : null),
    );
  }
}
