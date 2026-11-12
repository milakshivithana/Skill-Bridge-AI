import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/candidate_profile_model.dart';
import '../models/skill_model.dart';
import '../models/completeness_model.dart';

class CandidateProfileProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  CandidateProfileModel? _profile;
  ProfileCompletenessModel? _completeness;
  List<SkillModel> _taxonomySkills = [];

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingCv = false;
  String? _errorMessage;
  String? _successMessage;

  CandidateProfileModel? get profile => _profile;
  ProfileCompletenessModel? get completeness => _completeness;
  List<SkillModel> get taxonomySkills => _taxonomySkills;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isUploadingCv => _isUploadingCv;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiClient.get(ApiConstants.candidateMe);
      if (data != null) {
        _profile = CandidateProfileModel.fromJson(data as Map<String, dynamic>);
        if (_profile!.completeness != null) {
          _completeness = _profile!.completeness;
        } else {
          await refreshCompleteness();
        }
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCompleteness() async {
    if (_profile == null) return;
    try {
      final data = await _apiClient
          .get(ApiConstants.candidateCompleteness(_profile!.id));
      if (data != null) {
        _completeness =
            ProfileCompletenessModel.fromJson(data as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {
      // Non-critical, ignore
    }
  }

  Future<void> loadTaxonomySkills() async {
    try {
      final data = await _apiClient.get(ApiConstants.skills);
      if (data is List) {
        _taxonomySkills = data
            .map((e) => SkillModel.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {
      // Ignore
    }
  }

  Future<bool> updatePersonalDetails({
    required String phone,
    required String city,
    required String bio,
    String? linkedinUrl,
    String? portfolioUrl,
    String? gitHubUrl,
  }) async {
    if (_profile == null) return false;

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updatedData = await _apiClient.put(
        ApiConstants.candidateById(_profile!.id),
        body: {
          'phone': phone.trim(),
          'city': city.trim(),
          'bio': bio.trim(),
          'linkedinUrl':
              linkedinUrl?.trim().isEmpty == true ? null : linkedinUrl?.trim(),
          'portfolioUrl': portfolioUrl?.trim().isEmpty == true
              ? null
              : portfolioUrl?.trim(),
          'gitHubUrl':
              gitHubUrl?.trim().isEmpty == true ? null : gitHubUrl?.trim(),
        },
      );

      if (updatedData != null) {
        _profile =
            CandidateProfileModel.fromJson(updatedData as Map<String, dynamic>);
        await refreshCompleteness();
        _successMessage = 'Profile updated successfully!';
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  String _mapProficiency(int level) {
    if (level <= 1) return 'Beginner';
    if (level <= 3) return 'Intermediate';
    return 'Expert';
  }

  Future<bool> addSkill({
    required int skillId,
    required int proficiencyLevel,
    required int yearsOfExperience,
  }) async {
    if (_profile == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.candidateSkills(_profile!.id),
        body: {
          'skillId': skillId,
          'proficiencyLevel': _mapProficiency(proficiencyLevel),
          'yearsOfExperience': yearsOfExperience,
        },
      );

      await loadProfile();
      _successMessage = 'Skill added!';
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to add skill: $e';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  /// Create a new taxonomy skill (or find an existing one by name) then attach it.
  /// Uses the backend's idempotent, case-insensitive find-or-create behaviour.
  Future<bool> createAndAddSkill({
    required String skillName,
    required int proficiencyLevel,
  }) async {
    if (_profile == null) return false;

    final trimmed = skillName.trim();
    if (trimmed.isEmpty) {
      _errorMessage = 'Skill name cannot be empty.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: find-or-create in global taxonomy
      final created = await _apiClient.post(
        ApiConstants.skills,
        body: {'name': trimmed, 'category': 'General'},
      );
      final skillId = created['id'] as int;

      // Step 2: attach to candidate (backend deduplicates)
      await _apiClient.post(
        ApiConstants.candidateSkills(_profile!.id),
        body: {
          'skillId': skillId,
          'proficiencyLevel': _mapProficiency(proficiencyLevel),
          'yearsOfExperience': 1,
        },
      );

      // Refresh taxonomy list so the new skill appears in future searches
      await loadTaxonomySkills();
      await loadProfile();
      _successMessage = 'Skill "$trimmed" added!';
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to create skill: $e';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> removeSkill(int skillId) async {
    if (_profile == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient
          .delete(ApiConstants.candidateSkillDelete(_profile!.id, skillId));
      await loadProfile();
      _successMessage = 'Skill removed!';
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to remove skill: $e';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> addEducation({
    required String institution,
    required String degree,
    required String fieldOfStudy,
    required int startYear,
    int? endYear,
    String? grade,
  }) async {
    if (_profile == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.candidateEducation(_profile!.id),
        body: {
          'institution': institution.trim(),
          'degree': degree.trim(),
          'fieldOfStudy': fieldOfStudy.trim(),
          'startYear': startYear,
          'endYear': endYear ?? startYear,
          if (grade != null && grade.isNotEmpty) 'grade': grade.trim(),
        },
      );

      await loadProfile();
      _successMessage = 'Education qualification added!';
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to add education: $e';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteEducation(int eduId) async {
    if (_profile == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient
          .delete(ApiConstants.candidateEducationDetail(_profile!.id, eduId));
      await loadProfile();
      _successMessage = 'Education record deleted!';
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to delete education: $e';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> addExperience({
    required String company,
    required String title,
    String? location,
    required DateTime startDate,
    DateTime? endDate,
    required bool isCurrent,
    String? description,
  }) async {
    if (_profile == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.candidateExperience(_profile!.id),
        body: {
          'company': company.trim(),
          'title': title.trim(),
          if (location != null && location.isNotEmpty)
            'location': location.trim(),
          'startDate': startDate.toIso8601String(),
          if (endDate != null && !isCurrent)
            'endDate': endDate.toIso8601String(),
          'isCurrent': isCurrent,
          if (description != null && description.isNotEmpty)
            'description': description.trim(),
        },
      );

      await loadProfile();
      _successMessage = 'Work experience added!';
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to add experience: $e';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteExperience(int expId) async {
    if (_profile == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient
          .delete(ApiConstants.candidateExperienceDetail(_profile!.id, expId));
      await loadProfile();
      _successMessage = 'Experience record removed!';
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to delete experience: $e';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> updatePreferences({
    String? preferredRole,
    String? preferredLocation,
    String? employmentType,
    double? minimumExpectedStipend,
    required bool openForRelocation,
    required bool openForRemote,
  }) async {
    if (_profile == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.put(
        ApiConstants.candidatePreferences(_profile!.id),
        body: {
          'preferredRole': preferredRole?.trim(),
          'preferredLocation': preferredLocation?.trim(),
          'employmentType': employmentType?.trim(),
          'minimumExpectedStipend': minimumExpectedStipend,
          'openForRelocation': openForRelocation,
          'openForRemote': openForRemote,
        },
      );

      await loadProfile();
      _successMessage = 'Career preferences saved!';
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to update preferences: $e';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> uploadCv(String filePath) async {
    if (_profile == null) return false;

    _isUploadingCv = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _apiClient.postMultipart(
        ApiConstants.candidateCv(_profile!.id),
        filePath: filePath,
        fileFieldName: 'file',
      );

      await loadProfile();
      _successMessage = 'CV uploaded and processed successfully!';
      _isUploadingCv = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to upload CV: $e';
    }

    _isUploadingCv = false;
    notifyListeners();
    return false;
  }

  Future<bool> addCertificate({
    required String title,
    required String issuingOrganization,
    required DateTime issueDate,
    DateTime? expiryDate,
    String? credentialId,
    String? credentialUrl,
  }) async {
    if (_profile == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.candidateCertificates(_profile!.id),
        body: {
          'title': title.trim(),
          'issuingOrganization': issuingOrganization.trim(),
          'issueDate': issueDate.toIso8601String(),
          if (expiryDate != null) 'expiryDate': expiryDate.toIso8601String(),
          if (credentialId != null && credentialId.isNotEmpty)
            'credentialId': credentialId.trim(),
          if (credentialUrl != null && credentialUrl.isNotEmpty)
            'credentialUrl': credentialUrl.trim(),
        },
      );

      await loadProfile();
      _successMessage = 'Certificate added!';
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to add certificate: $e';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteCertificate(int certId) async {
    if (_profile == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.delete(
          ApiConstants.candidateCertificateDetail(_profile!.id, certId));
      await loadProfile();
      _successMessage = 'Certificate deleted!';
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to delete certificate: $e';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }
}
