const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5264/api';

// ---- Existing Types ----
export interface User {
  userId: number;
  fullName: string;
  email: string;
  role: 'Candidate' | 'Recruiter' | 'Interviewer' | 'Administrator';
  candidateId?: number;
  interviewerId?: number;
  token: string;
}

export interface Vacancy {
  id: number;
  companyId?: number;
  companyName?: string;
  title: string;
  description: string;
  location: string;
  employmentType: string;
  isActive: boolean;
  hasApplied: boolean;
  currentApplicationStatus?: string | null;
  applicationDeadline?: string;
  createdAt?: string;
  applicationCount?: number;
  company?: { name: string };
  vacancySkills?: Array<{ skill?: { name: string }; isMandatory: boolean }>;
  skills?: VacancySkill[];
  requirements?: VacancyRequirement[];
}

export interface ApplicationEvaluation {
  workflowId: number;
  evaluatedAt: string;
  matchScore: number;
  evidence?: {
    matched_required_skills?: string[];
    matched_skills?: string[];
    missing_required_skills?: string[];
    matched_preferred_skills?: string[];
    missing_preferred_skills?: string[];
    reasoning?: string;
    education_evidence?: Record<string, unknown>[];
    experience_evidence?: Record<string, unknown>[];
    requirements_review?: { text: string; result: string }[];
  };
}

export interface Application {
  evaluation?: ApplicationEvaluation;
  id: number;
  candidateId: number;
  candidateName?: string;
  candidateEmail?: string;
  vacancyId: number;
  vacancyTitle?: string;
  companyName?: string;
  status: string;
  matchScore: number;
  eligibilityPassed: boolean;
  appliedAt: string;
  updatedAt?: string;
  candidate?: { user?: { fullName: string; email: string } };
  vacancy?: { title: string; company?: { name: string } };
  statusHistories?: ApplicationStatusHistory[];
}

export interface Interview {
  id: number;
  applicationId: number;
  scheduledTime: string;
  durationMinutes: number;
  status: string;
  meetingLinkOrLocation: string;
  vacancyTitle: string;
  candidateName: string;
  interviewerName?: string;
}

async function recruitmentRequest<T>(path: string, token: string, method = 'GET'): Promise<T> {
  const res = await fetch(`${API_BASE_URL}${path}`, {
    method,
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const error = await res.json().catch(() => ({}));
    throw new Error(error.message || `Request failed (${res.status}).`);
  }
  return res.json();
}

export interface RecruitmentAnalytics {
  totalVacancies: number;
  totalApplications: number;
  pendingApprovals: number;
  approvedApplications: number;
  rejectedApplications: number;
  revisionRequested: number;
  inAiMatching: number;
  averageMatchScore: number;
  aiWorkflowSuccessRate: string;
  totalAiWorkflowsRun: number;
  totalAuditActions: number;
}

export interface PendingApproval {
  applicationId: number;
  candidateName: string;
  candidateEmail: string;
  vacancyTitle: string;
  companyName: string;
  matchScore: number;
  eligibilityPassed: boolean;
  status: string;
  appliedAt: string;
  aiWorkflowId?: number;
  aiJustification: string;
  matchedSkills: string[];
  proposedInterviewSlot: string;
}

export interface RecommendationDto {
  id: number;
  applicationId: number;
  candidateName: string;
  candidateEmail: string;
  calculatedScore: number;
  aiJustification: string;
  applicationStatus: string;
}

export interface ShortlistResponse {
  id: number;
  title: string;
  vacancyTitle: string;
  createdAt: string;
  recommendations: RecommendationDto[];
}

export interface AuditLogEntry {
  id: number;
  userId: number;
  action: string;
  entityType: string;
  entityId: number;
  timestamp: string;
  summary: string;
}

// ---- Component A: Candidate Module Types ----
export interface CandidateProfileDto {
  id: number;
  userId: number;
  fullName: string;
  email: string;
  phone?: string;
  city?: string;
  bio?: string;
  linkedInUrl?: string;
  portfolioUrl?: string;
  createdAt: string;
  updatedAt?: string;
}

export interface UpdateCandidateProfileDto {
  phone?: string;
  city?: string;
  bio?: string;
  linkedInUrl?: string;
  portfolioUrl?: string;
}

export interface SkillDto {
  id: number;
  name: string;
  category?: string;
}

export interface CandidateSkillDto {
  id: number;
  skillId: number;
  skillName: string;
  category?: string;
  proficiencyLevel?: string;
  yearsOfExperience?: number;
}

export interface AddCandidateSkillDto {
  skillId?: number;
  skillName?: string;
  category?: string;
  proficiencyLevel?: string;
  yearsOfExperience?: number;
}

export interface EducationDto {
  id: number;
  candidateId?: number;
  institution: string;
  degree: string;
  fieldOfStudy?: string;
  startYear: number;
  endYear: number;
  createdAt?: string;
  updatedAt?: string;
}

export interface CreateEducationDto {
  institution: string;
  degree: string;
  fieldOfStudy?: string;
  startYear: number;
  endYear: number;
}

export interface ExperienceDto {
  id: number;
  companyName: string;
  jobTitle: string;
  location?: string;
  startDate: string;
  endDate?: string;
  isCurrent: boolean;
  description?: string;
}

export interface CreateExperienceDto {
  companyName: string;
  jobTitle: string;
  location?: string;
  startDate: string;
  endDate?: string;
  isCurrent?: boolean;
  description?: string;
}

export interface CandidatePreferenceDto {
  id: number;
  preferredJobType?: string;
  preferredLocation?: string;
  expectedStipend?: number;
  preferredIndustry?: string;
  isOpenToRemote: boolean;
  isOpenToRelocation: boolean;
  noticePeriodDays?: number;
}

export interface UpdateCandidatePreferenceDto {
  preferredJobType?: string;
  preferredLocation?: string;
  expectedStipend?: number;
  preferredIndustry?: string;
  isOpenToRemote?: boolean;
  isOpenToRelocation?: boolean;
  noticePeriodDays?: number;
}

export interface CVDocumentDto {
  id: number;
  fileName: string;
  fileSizeBytes?: number;
  contentType?: string;
  uploadedAt: string;
}

export interface CertificateDto {
  id: number;
  name: string;
  issuingOrganization: string;
  issueDate: string;
  expiryDate?: string;
  credentialId?: string;
  credentialUrl?: string;
}

export interface CreateCertificateDto {
  name: string;
  issuingOrganization: string;
  issueDate: string;
  expiryDate?: string;
  credentialId?: string;
  credentialUrl?: string;
}

export interface ProfileCompletenessDto {
  candidateId: number;
  isComplete: boolean;
  completionPercentage: number;
  missingFields: string[];
  completedFields?: string[];
  evaluatedAt?: string;
  // Aliases for compatibility
  isProfileComplete: boolean;
  profileScorePercentage: number;
  isEligibleToApply: boolean;
}

export interface CandidateSummaryDto {
  id: number;
  fullName: string;
  email: string;
  city?: string;
  skills: string[];
  profileScorePercentage: number;
}

export interface PagedResultDto<T> {
  items: T[];
  totalCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export interface VacancySkill {
  skillId: number;
  skillName: string;
  category?: string;
  isMandatory: boolean;
}

export interface VacancyRequirement {
  id: number;
  requirementText: string;
  isNonNegotiable: boolean;
}

export interface PaginatedVacancies {
  items: Vacancy[];
  totalCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export interface Company {
  id: number;
  name: string;
  industry: string;
  location: string;
  website: string;
  activeVacanciesCount?: number;
}

export interface ApplicationStatusHistory {
  id: number;
  status: string;
  notes: string;
  changedAt: string;
}

export interface SavedVacancy {
  id: number;
  candidateId: number;
  vacancyId: number;
  vacancyTitle: string;
  companyName: string;
  location: string;
  employmentType: string;
  savedAt: string;
}

export interface EligibilityResult {
  candidateId: number;
  vacancyId: number;
  isEligible: boolean;
  passedRequirements: string[];
  failedRequirements: string[];
  matchedSkills: string[];
  missingMandatorySkills: string[];
  summaryNotes: string;
}

export interface InterviewScore {
  id?: number;
  interviewId?: number;
  metricName: string;
  score: number;
}

export interface InterviewFeedback {
  id?: number;
  interviewId?: number;
  comments: string;
  outcomeRecommendation: 'RECOMMEND_HIRE' | 'REJECT' | 'SECOND_ROUND';
}

export interface InterviewSlot {
  id: number;
  interviewerId: number;
  slotStartTime: string;
  slotEndTime: string;
  isBooked: boolean;
  interviewer?: {
    user?: { fullName: string; email: string };
    department?: string;
  };
}

export interface InterviewItem {
  id: number;
  applicationId: number;
  interviewerId?: number;
  scheduledTime: string;
  durationMinutes: number;
  status: 'SCHEDULED' | 'CONFIRMED' | 'RESCHEDULED' | 'COMPLETED' | 'CANCELLED';
  meetingLinkOrLocation: string;
  createdAt: string;
  application?: {
    candidate?: { user?: { fullName: string; email: string } };
    vacancy?: { title: string; company?: { name: string } };
  };
  interviewer?: {
    department?: string;
    user?: { fullName: string; email: string };
  };
  scores?: InterviewScore[];
  feedbacks?: InterviewFeedback[];
}

// ---- API Methods ----
export const api = {
  // ---- Auth Header Helpers ----
  getAuthHeaders(token: string): Record<string, string> {
    return {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    };
  },

  getAuthHeadersMultipart(token: string): Record<string, string> {
    return { 'Authorization': `Bearer ${token}` };
  },

  // ---- Auth ----
  async register(data: { fullName: string; email: string; password: string; role: string }): Promise<User> {
    const res = await fetch(`${API_BASE_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Registration failed' }));
      throw new Error(err.message || 'Registration failed.');
    }
    return await res.json();
  },

  async login(data: { email: string; password: string }): Promise<User> {
    const res = await fetch(`${API_BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Invalid credentials' }));
      throw new Error(err.message || 'Invalid email or password.');
    }
    return await res.json();
  },

  // ---- Candidate Profile ----
  async getMyProfile(token: string): Promise<CandidateProfileDto> {
    const res = await fetch(`${API_BASE_URL}/candidates/me`, { headers: this.getAuthHeaders(token) });
    if (!res.ok) throw new Error('Failed to load profile.');
    return await res.json();
  },

  async getCandidateProfile(candidateId: number, token: string): Promise<CandidateProfileDto> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}`, { headers: this.getAuthHeaders(token) });
    if (!res.ok) throw new Error('Failed to load candidate profile.');
    return await res.json();
  },

  async updateCandidateProfile(
    candidateId: number,
    data: UpdateCandidateProfileDto,
    token: string
  ): Promise<CandidateProfileDto> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}`, {
      method: 'PUT',
      headers: this.getAuthHeaders(token),
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Update failed' }));
      const errors = err.errors && typeof err.errors === 'object' ? Object.values(err.errors).flat().join(' ') : undefined;
      throw new Error(errors || err.message || err.title || 'Failed to update profile.');
    }
    return await res.json();
  },

  // ---- Candidate Search (Recruiter / Admin) ----
  async searchCandidates(
    token: string,
    params?: { query?: string; city?: string; skill?: string; page?: number; pageSize?: number }
  ): Promise<PagedResultDto<CandidateSummaryDto>> {
    const qs = new URLSearchParams();
    if (params?.query) qs.set('query', params.query);
    if (params?.city) qs.set('city', params.city);
    if (params?.skill) qs.set('skill', params.skill);
    if (params?.page) qs.set('page', String(params.page));
    if (params?.pageSize) qs.set('pageSize', String(params.pageSize));
    const res = await fetch(`${API_BASE_URL}/candidates?${qs}`, { headers: this.getAuthHeaders(token) });
    if (!res.ok) throw new Error('Failed to search candidates.');
    return await res.json();
  },

  // ---- Skills Taxonomy ----
  async getAllSkills(token: string): Promise<SkillDto[]> {
    const res = await fetch(`${API_BASE_URL}/skills`, { headers: this.getAuthHeaders(token) });
    if (!res.ok) throw new Error('Failed to load skills.');
    return await res.json();
  },

  async createSkill(data: { name: string; category?: string }, token: string): Promise<SkillDto> {
    const res = await fetch(`${API_BASE_URL}/skills`, {
      method: 'POST',
      headers: this.getAuthHeaders(token),
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Failed to create skill' }));
      throw new Error(err.message || 'Failed to create skill.');
    }
    return await res.json();
  },

  async getCandidateSkills(candidateId: number, token: string): Promise<CandidateSkillDto[]> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/skills`, {
      headers: this.getAuthHeaders(token),
    });
    if (!res.ok) throw new Error('Failed to load skills.');
    return await res.json();
  },

  async addCandidateSkill(
    candidateId: number,
    data: AddCandidateSkillDto,
    token: string
  ): Promise<CandidateSkillDto> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/skills`, {
      method: 'POST',
      headers: this.getAuthHeaders(token),
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Failed to add skill' }));
      throw new Error(err.message || 'Failed to add skill.');
    }
    return await res.json();
  },

  async removeCandidateSkill(candidateId: number, skillId: number, token: string): Promise<void> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/skills/${skillId}`, {
      method: 'DELETE',
      headers: this.getAuthHeaders(token),
    });
    if (!res.ok) throw new Error('Failed to remove skill.');
  },

  // ---- Education ----
  async getEducations(candidateId: number, token: string): Promise<EducationDto[]> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/education`, {
      headers: this.getAuthHeaders(token),
    });
    if (!res.ok) throw new Error('Failed to load education records.');
    return await res.json();
  },

  async addEducation(candidateId: number, data: CreateEducationDto, token: string): Promise<EducationDto> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/education`, {
      method: 'POST',
      headers: this.getAuthHeaders(token),
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => null);
      let errorMsg = 'Failed to add education.';
      if (err) {
        if (err.errors && typeof err.errors === 'object') {
          errorMsg = Object.values(err.errors).flat().join(' ');
        } else if (err.message) {
          errorMsg = err.message;
        } else if (err.title) {
          errorMsg = err.title;
        }
      }
      throw new Error(errorMsg);
    }
    return await res.json();
  },

  async updateEducation(
    candidateId: number,
    eduId: number,
    data: CreateEducationDto,
    token: string
  ): Promise<EducationDto> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/education/${eduId}`, {
      method: 'PUT',
      headers: this.getAuthHeaders(token),
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => null);
      let errorMsg = 'Failed to update education.';
      if (err) {
        if (err.errors && typeof err.errors === 'object') {
          errorMsg = Object.values(err.errors).flat().join(' ');
        } else if (err.message) {
          errorMsg = err.message;
        } else if (err.title) {
          errorMsg = err.title;
        }
      }
      throw new Error(errorMsg);
    }
    return await res.json();
  },

  async deleteEducation(candidateId: number, eduId: number, token: string): Promise<void> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/education/${eduId}`, {
      method: 'DELETE',
      headers: this.getAuthHeaders(token),
    });
    if (!res.ok) throw new Error('Failed to delete education.');
  },

  // ---- Experience ----
  async getExperiences(candidateId: number, token: string): Promise<ExperienceDto[]> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/experience`, {
      headers: this.getAuthHeaders(token),
    });
    if (!res.ok) throw new Error('Failed to load experience records.');
    return await res.json();
  },

  async addExperience(candidateId: number, data: CreateExperienceDto, token: string): Promise<ExperienceDto> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/experience`, {
      method: 'POST',
      headers: this.getAuthHeaders(token),
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Failed to add experience' }));
      throw new Error(err.message || 'Failed to add experience.');
    }
    return await res.json();
  },

  async updateExperience(
    candidateId: number,
    expId: number,
    data: CreateExperienceDto,
    token: string
  ): Promise<ExperienceDto> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/experience/${expId}`, {
      method: 'PUT',
      headers: this.getAuthHeaders(token),
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error('Failed to update experience.');
    return await res.json();
  },

  async deleteExperience(candidateId: number, expId: number, token: string): Promise<void> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/experience/${expId}`, {
      method: 'DELETE',
      headers: this.getAuthHeaders(token),
    });
    if (!res.ok) throw new Error('Failed to delete experience.');
  },

  // ---- Preferences ----
  async getPreferences(candidateId: number, token: string): Promise<CandidatePreferenceDto | null> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/preferences`, {
      headers: this.getAuthHeaders(token),
    });
    if (res.status === 404) return null;
    if (!res.ok) throw new Error('Failed to load preferences.');
    return await res.json();
  },

  async updatePreferences(
    candidateId: number,
    data: UpdateCandidatePreferenceDto,
    token: string
  ): Promise<CandidatePreferenceDto> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/preferences`, {
      method: 'PUT',
      headers: this.getAuthHeaders(token),
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error('Failed to update preferences.');
    return await res.json();
  },

  // ---- CV ----
  async uploadCV(candidateId: number, file: File, token: string): Promise<CVDocumentDto> {
    const form = new FormData();
    form.append('file', file);
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/cv`, {
      method: 'POST',
      headers: this.getAuthHeadersMultipart(token),
      body: form,
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Upload failed' }));
      throw new Error(err.message || 'CV upload failed.');
    }
    return await res.json();
  },

  async getCVDocument(candidateId: number, token: string): Promise<CVDocumentDto | null> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/cv`, {
      headers: this.getAuthHeaders(token),
    });
    if (res.status === 404) return null;
    if (!res.ok) throw new Error('Failed to load CV info.');
    return await res.json();
  },

  // ---- Certificates ----
  async getCertificates(candidateId: number, token: string): Promise<CertificateDto[]> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/certificates`, {
      headers: this.getAuthHeaders(token),
    });
    if (!res.ok) throw new Error('Failed to load certificates.');
    return await res.json();
  },

  async addCertificate(candidateId: number, data: CreateCertificateDto, token: string): Promise<CertificateDto> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/certificates`, {
      method: 'POST',
      headers: this.getAuthHeaders(token),
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Failed to add certificate' }));
      throw new Error(err.message || 'Failed to add certificate.');
    }
    return await res.json();
  },

  async deleteCertificate(candidateId: number, certId: number, token: string): Promise<void> {
    const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/certificates/${certId}`, {
      method: 'DELETE',
      headers: this.getAuthHeaders(token),
    });
    if (!res.ok) throw new Error('Failed to delete certificate.');
  },

  // ---- Profile Completeness ----
  async getProfileCompleteness(candidateId: number, token: string): Promise<ProfileCompletenessDto> {
    try {
      const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/completeness`, {
        headers: this.getAuthHeaders(token),
      });
      if (res.ok) {
        const data = await res.json();
        const completionPercentage = data.completionPercentage ?? data.profileScorePercentage ?? 0;
        const isComplete = data.isComplete ?? data.isProfileComplete ?? (completionPercentage === 100);
        return {
          candidateId: data.candidateId ?? candidateId,
          isComplete,
          completionPercentage,
          missingFields: data.missingFields ?? [],
          completedFields: data.completedFields ?? [],
          evaluatedAt: data.evaluatedAt,
          isProfileComplete: isComplete,
          profileScorePercentage: completionPercentage,
          isEligibleToApply: isComplete,
        };
      }
    } catch (e) {
      console.error('Completeness error:', e);
    }
    throw new Error('Unable to calculate profile completeness. Please retry.');
  },

  async analyzeProfileCompleteness(candidateId: number, token?: string) {
    try {
      const headers: Record<string, string> = token ? { 'Authorization': `Bearer ${token}` } : {};
      const res = await fetch(`${API_BASE_URL}/candidates/${candidateId}/analyze-profile`, {
        method: 'POST',
        headers,
      });
      if (res.ok) return await res.json();
    } catch (e) {
      console.error('API Error:', e);
    }
    throw new Error('Profile analysis is unavailable. Please retry.');
  },

  // Candidate IDs are resolved by the backend from the bearer token.
  async applyToVacancy(vacancyId: number, token: string): Promise<Application> {
    return recruitmentRequest(`/vacancies/${vacancyId}/apply`, token, 'POST');
  },

  async evaluateApplicationMatch(appId: number, token: string): Promise<{ applicationId: number; status: string; matchScore: number }> {
    return recruitmentRequest(`/applications/${appId}/evaluate-match`, token, 'POST');
  },

  async getVacancies(token: string): Promise<Vacancy[]> {
    const result = await recruitmentRequest<PaginatedVacancies>('/vacancies', token);
    return result.items;
  },

  async getMyApplications(token: string): Promise<Application[]> {
    return recruitmentRequest('/applications/me', token);
  },

  async getInterviews(token: string): Promise<InterviewItem[]> {
    return recruitmentRequest('/interviews', token);
  },

  async getAIWorkflow(id: number, token: string): Promise<Record<string, unknown>> {
    return recruitmentRequest(`/ai-workflows/${id}`, token);
  },

  async getAnalytics(token: string): Promise<RecruitmentAnalytics> {
    try {
      const res = await fetch(`${API_BASE_URL}/reports/recruitment-summary`, { headers: this.getAuthHeaders(token) });
      if (res.ok) return await res.json();
    } catch (e) {
      console.warn('Analytics fetch error');
    }
    return {
      totalVacancies: 0,
      totalApplications: 0,
      pendingApprovals: 0,
      approvedApplications: 0,
      rejectedApplications: 0,
      revisionRequested: 0,
      inAiMatching: 0,
      averageMatchScore: 0,
      aiWorkflowSuccessRate: '100%',
      totalAiWorkflowsRun: 0,
      totalAuditActions: 0,
    };
  },

  async getPendingApprovals(token: string): Promise<PendingApproval[]> {
    try {
      const res = await fetch(`${API_BASE_URL}/applications/pending-approval`, { headers: this.getAuthHeaders(token) });
      if (res.ok) return await res.json();
    } catch (e) {
      console.warn('Pending approvals fetch error');
    }
    return [];
  },

  async getShortlists(token: string, mine = false): Promise<ShortlistResponse[]> {
    try {
      const res = await fetch(`${API_BASE_URL}/shortlists${mine ? "/me" : ""}`, { headers: this.getAuthHeaders(token) });
      if (res.ok) return await res.json();
    } catch (e) {
      console.warn('Shortlists fetch error');
    }
    return [];
  },

  async getAuditLogs(token: string, page = 1, pageSize = 20): Promise<{ total: number; logs: AuditLogEntry[] }> {
    try {
      const res = await fetch(`${API_BASE_URL}/audit-logs?page=${page}&pageSize=${pageSize}`, { headers: this.getAuthHeaders(token) });
      if (res.ok) return await res.json();
    } catch (e) {
      console.warn('Audit log fetch error');
    }
    return { total: 0, logs: [] };
  },

  async approveApplication(
    appId: number,
    token: string,
    comments = 'Approved by recruiter'
  ): Promise<boolean> {
    const res = await fetch(
      `${API_BASE_URL}/shortlists/${appId}/approve?comments=${encodeURIComponent(comments)}`,
      { method: 'POST', headers: this.getAuthHeaders(token) }
    );
    return res.ok;
  },

  async rejectApplication(
    appId: number,
    token: string,
    comments = 'Rejected by recruiter'
  ): Promise<boolean> {
    const res = await fetch(
      `${API_BASE_URL}/shortlists/${appId}/reject?comments=${encodeURIComponent(comments)}`,
      { method: 'POST', headers: this.getAuthHeaders(token) }
    );
    return res.ok;
  },

  async requestRevision(
    appId: number,
    token: string,
    comments = 'Revision requested'
  ): Promise<boolean> {
    const res = await fetch(
      `${API_BASE_URL}/shortlists/${appId}/request-revision?comments=${encodeURIComponent(comments)}`,
      { method: 'POST', headers: this.getAuthHeaders(token) }
    );
    return res.ok;
  },
  async getVacanciesAdvanced(params: {
    searchQuery?: string;
    location?: string;
    employmentType?: string;
    companyId?: number;
    isActive?: boolean;
    sortBy?: string;
    page?: number;
    pageSize?: number;
  }, token: string): Promise<PaginatedVacancies> {
    const query = new URLSearchParams();
    for (const [key, value] of Object.entries(params)) {
      if (value !== undefined && value !== null && value !== '') query.set(key, String(value));
    }
    return recruitmentRequest(`/vacancies?${query.toString()}`, token);
  },
  async getVacancyDetails(id: number, token: string): Promise<Vacancy | null> {
    try {
      const res = await fetch(`${API_BASE_URL}/vacancies/${id}`, { headers: this.getAuthHeaders(token) });
      if (res.ok) return await res.json();
    } catch (e) { console.error('Get vacancy error', e); }
    return null;
  },
  async createVacancy(data: {
    title: string;
    description: string;
    location: string;
    employmentType: string;
    companyId: number;
    applicationDeadline?: string;
    skills: Array<{ skillId?: number; skillName: string; isMandatory: boolean }>;
    requirements: Array<{ requirementText: string; isNonNegotiable: boolean }>;
  }, token: string): Promise<Vacancy> {
    const res = await fetch(`${API_BASE_URL}/vacancies`, {
      method: 'POST',
      headers: this.getAuthHeaders(token),
      body: JSON.stringify(data)
    });
    if (!res.ok) throw new Error('Failed to create vacancy');
    return await res.json();
  },
  async updateVacancy(id: number, data: {
    title: string;
    description: string;
    location: string;
    employmentType: string;
    isActive: boolean;
    applicationDeadline?: string;
    skills: Array<{ skillId?: number; skillName: string; isMandatory: boolean }>;
    requirements: Array<{ requirementText: string; isNonNegotiable: boolean }>;
  }, token: string): Promise<void> {
    const res = await fetch(`${API_BASE_URL}/vacancies/${id}`, {
      method: 'PUT',
      headers: this.getAuthHeaders(token),
      body: JSON.stringify(data)
    });
    if (!res.ok) throw new Error('Failed to update vacancy');
  },
  async toggleVacancyStatus(id: number, token: string): Promise<void> {
    const res = await fetch(`${API_BASE_URL}/vacancies/${id}`, { method: 'DELETE', headers: this.getAuthHeaders(token) });
    if (!res.ok) throw new Error('Failed to toggle vacancy status');
  },
  async saveVacancy(vacancyId: number, token: string): Promise<void> {
    const res = await fetch(`${API_BASE_URL}/vacancies/${vacancyId}/save`, { method: 'POST', headers: this.getAuthHeaders(token) });
    if (!res.ok) throw new Error('Failed to save vacancy');
  },
  async unsaveVacancy(vacancyId: number, token: string): Promise<void> {
    const res = await fetch(`${API_BASE_URL}/vacancies/${vacancyId}/save`, { method: 'DELETE', headers: this.getAuthHeaders(token) });
    if (!res.ok) throw new Error('Failed to unsave vacancy');
  },
  async getSavedVacancies(token: string): Promise<SavedVacancy[]> {
    return recruitmentRequest('/vacancies/saved/me', token);
  },
  async getCandidateApplications(candidateId: number, token: string): Promise<Application[]> {
    try {
      const res = await fetch(`${API_BASE_URL}/applications/candidate/${candidateId}`, { headers: this.getAuthHeaders(token) });
      if (res.ok) return await res.json();
    } catch (e) { console.error('Candidate applications error', e); }
    return [];
  },
  async getVacancyApplications(vacancyId: number, token: string): Promise<Application[]> {
    try {
      const res = await fetch(`${API_BASE_URL}/applications/vacancy/${vacancyId}`, { headers: this.getAuthHeaders(token) });
      if (res.ok) return await res.json();
    } catch (e) { console.error('Vacancy applications error', e); }
    return [];
  },
  async withdrawApplication(appId: number, reason = 'Withdrawn by candidate', token: string): Promise<void> {
    const res = await fetch(`${API_BASE_URL}/applications/${appId}/withdraw?reason=${encodeURIComponent(reason)}`, { method: 'POST', headers: this.getAuthHeaders(token) });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Failed to withdraw application' }));
      throw new Error(err.message || 'Failed to withdraw application.');
    }
  },
  async performEligibilityCheck(appId: number, token: string): Promise<EligibilityResult> {
    const res = await fetch(`${API_BASE_URL}/applications/${appId}/eligibility-check`, { method: 'POST', headers: this.getAuthHeaders(token) });
    if (!res.ok) throw new Error('Eligibility check failed');
    return await res.json();
  },
  async getCompanies(token: string): Promise<Company[]> {
    try {
      const res = await fetch(`${API_BASE_URL}/companies`, { headers: this.getAuthHeaders(token) });
      if (res.ok) return await res.json();
    } catch (e) { console.error('Get companies error', e); }
    return [];
  },
  async createCompany(data: { name: string; industry: string; location: string; website: string }, token: string): Promise<Company> {
    const res = await fetch(`${API_BASE_URL}/companies`, {
      method: 'POST',
      headers: this.getAuthHeaders(token),
      body: JSON.stringify(data)
    });
    if (!res.ok) throw new Error('Failed to create company');
    return await res.json();
  },
  async getInterview(id: number, token: string): Promise<InterviewItem | null> {
    try {
      const res = await fetch(`${API_BASE_URL}/interviews/${id}`, { headers: this.getAuthHeaders(token) });
      if (res.ok) return await res.json();
    } catch (e) {
      console.warn('Interview detail fetch error:', e);
    }
    return null;
  },
  async scheduleInterview(data: Partial<InterviewItem>, token: string): Promise<InterviewItem | null> {
    try {
      const res = await fetch(`${API_BASE_URL}/interviews`, {
        method: 'POST',
        headers: this.getAuthHeaders(token),
        body: JSON.stringify(data)
      });
      if (res.ok) return await res.json();
    } catch (e) {
      console.warn('Schedule interview error:', e);
    }
    return null;
  },
  async rescheduleInterview(id: number, newTime: string, token: string): Promise<boolean> {
    try {
      const res = await fetch(`${API_BASE_URL}/interviews/${id}/reschedule?newTime=${encodeURIComponent(newTime)}`, {
        method: 'POST', headers: this.getAuthHeaders(token)
      });
      return res.ok;
    } catch (e) {
      console.warn('Reschedule interview error:', e);
      return false;
    }
  },
  async cancelInterview(id: number, reason = 'Cancelled by recruiter', token: string): Promise<boolean> {
    try {
      const res = await fetch(`${API_BASE_URL}/interviews/${id}/cancel`, {
        method: 'POST',
        headers: this.getAuthHeaders(token),
        body: JSON.stringify({ reason })
      });
      return res.ok;
    } catch (e) {
      console.warn('Cancel interview error:', e);
      return false;
    }
  },
  async getAvailableInterviewSlots(token: string): Promise<InterviewSlot[]> {
    try {
      const res = await fetch(`${API_BASE_URL}/interviews/available-slots`, { headers: this.getAuthHeaders(token) });
      if (res.ok) return await res.json();
    } catch (e) {
      console.warn('Available slots fetch error:', e);
    }
    return [];
  },
  async suggestConflictFreeSlot(interviewId: number, token: string): Promise<{ interviewId: number; suggestedStartTime: string; durationMinutes: number; hasConflict: boolean; recommendationNote: string } | null> {
    try {
      const res = await fetch(`${API_BASE_URL}/interviews/${interviewId}/suggest-slot`, {
        method: 'POST', headers: this.getAuthHeaders(token)
      });
      if (res.ok) return await res.json();
    } catch (e) {
      console.warn('Suggest slot error:', e);
    }
    return null;
  },
  async addInterviewScore(interviewId: number, metricName: string, score: number, token: string): Promise<boolean> {
    try {
      const res = await fetch(`${API_BASE_URL}/interviews/${interviewId}/scores`, {
        method: 'POST',
        headers: this.getAuthHeaders(token),
        body: JSON.stringify({ metricName, score })
      });
      return res.ok;
    } catch (e) {
      console.warn('Add score error:', e);
      return false;
    }
  },
  async addInterviewFeedback(interviewId: number, comments: string, outcomeRecommendation: string, token: string): Promise<boolean> {
    try {
      const res = await fetch(`${API_BASE_URL}/interviews/${interviewId}/feedback`, {
        method: 'POST',
        headers: this.getAuthHeaders(token),
        body: JSON.stringify({ comments, outcomeRecommendation })
      });
      return res.ok;
    } catch (e) {
      console.warn('Add feedback error:', e);
      return false;
    }
  },
};
