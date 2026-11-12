class ApiConstants {
  static const String liveBackendUrl =
      'https://skillbridge-g6r6.onrender.com/api';
  static const String localBackendUrl = 'http://localhost:5264/api';
  // Deployment default from main; local/emulator targets remain configurable.
  static String get baseUrl => const String.fromEnvironment('API_BASE_URL',
      defaultValue: liveBackendUrl);

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Candidate endpoints
  static const String candidateMe = '/candidates/me';
  static String candidateById(int id) => '/candidates/$id';
  static String candidateSkills(int id) => '/candidates/$id/skills';
  static String candidateSkillDelete(int id, int skillId) =>
      '/candidates/$id/skills/$skillId';
  static String candidateEducation(int id) => '/candidates/$id/education';
  static String candidateEducationDetail(int id, int eduId) =>
      '/candidates/$id/education/$eduId';
  static String candidateExperience(int id) => '/candidates/$id/experience';
  static String candidateExperienceDetail(int id, int expId) =>
      '/candidates/$id/experience/$expId';
  static String candidatePreferences(int id) => '/candidates/$id/preferences';
  static String candidateCv(int id) => '/candidates/$id/cv';
  static String candidateCertificates(int id) => '/candidates/$id/certificates';
  static String candidateCertificateDetail(int id, int certId) =>
      '/candidates/$id/certificates/$certId';
  static String candidateCompleteness(int id) => '/candidates/$id/completeness';

  // Taxonomy skills
  static const String skills = '/skills';

  // Vacancies
  static const String vacancies = '/vacancies';
  static String applyVacancy(int id) => '/vacancies/$id/apply';
  static const String myApplications = '/vacancies/my-applications';
}
