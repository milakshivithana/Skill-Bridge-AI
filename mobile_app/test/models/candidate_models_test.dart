import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/skill_model.dart';
import 'package:mobile_app/models/education_model.dart';
import 'package:mobile_app/models/cv_document_model.dart';
import 'package:mobile_app/models/completeness_model.dart';

void main() {
  group('Candidate Models Test Suite', () {
    test(
        'CandidateSkillModel deserializes and maps proficiency label correctly',
        () {
      final json = {
        'id': 1,
        'skillId': 10,
        'skillName': 'React',
        'category': 'Frontend',
        'proficiencyLevel': 3,
        'yearsOfExperience': 2,
      };

      final model = CandidateSkillModel.fromJson(json);

      expect(model.id, 1);
      expect(model.skillId, 10);
      expect(model.skillName, 'React');
      expect(model.proficiencyLevel, 3);
      expect(model.proficiencyLabel, 'Advanced');
      expect(model.yearsOfExperience, 2);
    });

    test(
        'ProfileCompletenessModel correctly parses deterministic fields and eligibility',
        () {
      final json = {
        'candidateId': 5,
        'completionPercentage': 100,
        'isEligibleForApplication': true,
        'completedFields': [
          'Phone',
          'City',
          'Bio',
          'Skills',
          'Education',
          'CVDocument'
        ],
        'missingFields': [],
      };

      final model = ProfileCompletenessModel.fromJson(json);

      expect(model.candidateId, 5);
      expect(model.completionPercentage, 100);
      expect(model.isEligibleForApplication, true);
      expect(model.completedFields.length, 6);
      expect(model.missingFields.isEmpty, true);
    });

    test('EducationModel calculates yearRange accurately', () {
      final json = {
        'id': 1,
        'candidateId': 5,
        'institution': 'SLIIT',
        'degree': 'BSc (Hons) in IT',
        'fieldOfStudy': 'Software Engineering',
        'startYear': 2022,
        'endYear': 2026,
        'grade': '3.8 GPA',
      };

      final model = EducationModel.fromJson(json);

      expect(model.institution, 'SLIIT');
      expect(model.yearRange, '2022 – 2026');
      expect(model.grade, '3.8 GPA');
    });

    test('CVDocumentModel formats file sizes properly', () {
      final smallDoc = CVDocumentModel(
        id: 1,
        candidateId: 5,
        fileName: 'resume.pdf',
        fileSizeBytes: 500,
        uploadedAt: DateTime.now(),
      );

      final kbDoc = CVDocumentModel(
        id: 2,
        candidateId: 5,
        fileName: 'cv.pdf',
        fileSizeBytes: 204800, // 200 KB
        uploadedAt: DateTime.now(),
      );

      expect(smallDoc.formattedSize, '500 B');
      expect(kbDoc.formattedSize, '200.0 KB');
    });
  });
}
