using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using SkillBridge.Api.DTOs;

namespace SkillBridge.Api.Services
{
    public interface ICandidateService
    {
        // Profile Operations
        Task<CandidateProfileDto?> GetProfileAsync(int candidateId);
        Task<CandidateProfileDto?> GetProfileByUserIdAsync(int userId);
        Task<CandidateProfileDto?> UpdateProfileAsync(int candidateId, UpdateCandidateProfileDto dto);
        Task<PagedResultDto<CandidateSummaryDto>> SearchCandidatesAsync(string? query, string? skill, string? city, int page, int pageSize);

        // Skill Operations
        Task<List<CandidateSkillDto>> GetSkillsAsync(int candidateId);
        Task<CandidateSkillDto?> AddSkillAsync(int candidateId, AddCandidateSkillDto dto);
        Task<bool> RemoveSkillAsync(int candidateId, int skillId);
        Task<List<SkillDto>> GetAllTaxonomySkillsAsync();
        Task<SkillDto> CreateTaxonomySkillAsync(CreateSkillDto dto);

        // Education Operations
        Task<List<EducationDto>> GetEducationsAsync(int candidateId);
        Task<EducationDto?> GetEducationByIdAsync(int candidateId, int educationId);
        Task<EducationDto> AddEducationAsync(int candidateId, CreateEducationDto dto);
        Task<EducationDto?> UpdateEducationAsync(int candidateId, int educationId, UpdateEducationDto dto);
        Task<bool> DeleteEducationAsync(int candidateId, int educationId);

        // Experience Operations
        Task<List<ExperienceDto>> GetExperiencesAsync(int candidateId);
        Task<ExperienceDto?> GetExperienceByIdAsync(int candidateId, int experienceId);
        Task<ExperienceDto> AddExperienceAsync(int candidateId, CreateExperienceDto dto);
        Task<ExperienceDto?> UpdateExperienceAsync(int candidateId, int experienceId, UpdateExperienceDto dto);
        Task<bool> DeleteExperienceAsync(int candidateId, int experienceId);

        // Preference Operations
        Task<CandidatePreferenceDto?> GetPreferencesAsync(int candidateId);
        Task<CandidatePreferenceDto> UpdatePreferencesAsync(int candidateId, UpdateCandidatePreferenceDto dto);

        // CV & Document Operations
        Task<CVDocumentDto> UploadCVAsync(int candidateId, IFormFile file);
        Task<CVDocumentDto?> GetLatestCVAsync(int candidateId);
        Task<CVDocumentDto?> GetCVByIdAsync(int candidateId, int cvId);

        // Certificate Operations
        Task<List<CertificateDto>> GetCertificatesAsync(int candidateId);
        Task<CertificateDto> AddCertificateAsync(int candidateId, CreateCertificateDto dto);
        Task<bool> DeleteCertificateAsync(int candidateId, int certificateId);

        // Security & Verification
        Task<bool> VerifyCandidateOwnershipAsync(int candidateId, int userId);

        // Profile Completeness
        Task<ProfileCompletenessDto> CalculateProfileCompletenessAsync(int candidateId);
    }
}
