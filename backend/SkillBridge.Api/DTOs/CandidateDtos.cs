using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace SkillBridge.Api.DTOs
{
    // ==========================================
    // CANDIDATE PROFILE DTOS
    // ==========================================

    public class CandidateProfileDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string City { get; set; } = string.Empty;
        public string Bio { get; set; } = string.Empty;
        public string? LinkedInUrl { get; set; }
        public string? PortfolioUrl { get; set; }
        public bool IsProfileComplete { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        public List<CandidateSkillDto> Skills { get; set; } = new();
        public List<EducationDto> Educations { get; set; } = new();
        public List<ExperienceDto> Experiences { get; set; } = new();
        public List<CertificateDto> Certificates { get; set; } = new();
        public List<CVDocumentDto> CVDocuments { get; set; } = new();
        public CandidatePreferenceDto? Preference { get; set; }
    }

    public class UpdateCandidateProfileDto
    {
        [MaxLength(20, ErrorMessage = "Phone number cannot exceed 20 characters.")]
        public string Phone { get; set; } = string.Empty;

        [MaxLength(100, ErrorMessage = "City cannot exceed 100 characters.")]
        public string City { get; set; } = string.Empty;

        [MaxLength(2000, ErrorMessage = "Bio cannot exceed 2000 characters.")]
        public string Bio { get; set; } = string.Empty;

        [MaxLength(255)]
        public string? LinkedInUrl { get; set; }

        [MaxLength(255)]
        public string? PortfolioUrl { get; set; }
    }

    public class CandidateSummaryDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string City { get; set; } = string.Empty;
        public bool IsProfileComplete { get; set; }
        public List<string> Skills { get; set; } = new();
        public string? LatestQualification { get; set; }
        public string? LatestInstitution { get; set; }
    }

    public class PagedResultDto<T>
    {
        public int TotalCount { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
        public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);
        public List<T> Items { get; set; } = new();
    }

    // ==========================================
    // SKILL DTOS
    // ==========================================

    public class CandidateSkillDto
    {
        public int Id { get; set; }
        public int SkillId { get; set; }
        public string SkillName { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string ProficiencyLevel { get; set; } = "Intermediate";
        public DateTime CreatedAt { get; set; }
    }

    public class AddCandidateSkillDto
    {
        public int? SkillId { get; set; }

        [MaxLength(100, ErrorMessage = "Skill name cannot exceed 100 characters.")]
        public string? SkillName { get; set; }

        [MaxLength(50, ErrorMessage = "Category cannot exceed 50 characters.")]
        public string? Category { get; set; } = "General";

        [MaxLength(50)]
        [RegularExpression("^(Beginner|Intermediate|Expert)$", ErrorMessage = "Proficiency level must be 'Beginner', 'Intermediate', or 'Expert'.")]
        public string ProficiencyLevel { get; set; } = "Intermediate";
    }

    public class SkillDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Category { get; set; } = "General";
    }

    public class CreateSkillDto
    {
        [Required(ErrorMessage = "Skill name is required."), MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(50)]
        public string Category { get; set; } = "General";
    }

    // ==========================================
    // EDUCATION DTOS
    // ==========================================

    public class EducationDto
    {
        public int Id { get; set; }
        public int CandidateId { get; set; }
        public string Institution { get; set; } = string.Empty;
        public string Degree { get; set; } = string.Empty;
        public string FieldOfStudy { get; set; } = string.Empty;
        public int StartYear { get; set; }
        public int EndYear { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class CreateEducationDto
    {
        [Required(ErrorMessage = "Institution is required."), MaxLength(150)]
        public string Institution { get; set; } = string.Empty;

        [Required(ErrorMessage = "Degree/Qualification is required."), MaxLength(150)]
        public string Degree { get; set; } = string.Empty;

        [MaxLength(100)]
        public string FieldOfStudy { get; set; } = string.Empty;

        [Range(1950, 2100, ErrorMessage = "Start year must be a valid year.")]
        public int StartYear { get; set; }

        [Range(1950, 2100, ErrorMessage = "End year must be a valid year.")]
        public int EndYear { get; set; }
    }

    public class UpdateEducationDto : CreateEducationDto
    {
    }

    // ==========================================
    // EXPERIENCE DTOS
    // ==========================================

    public class ExperienceDto
    {
        public int Id { get; set; }
        public int CandidateId { get; set; }
        public string CompanyName { get; set; } = string.Empty;
        public string JobTitle { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int DurationMonths { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class CreateExperienceDto
    {
        [Required(ErrorMessage = "Company name is required."), MaxLength(150)]
        public string CompanyName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Job title is required."), MaxLength(100)]
        public string JobTitle { get; set; } = string.Empty;

        [MaxLength(500)]
        public string Description { get; set; } = string.Empty;

        [Range(0, 600, ErrorMessage = "Duration in months must be between 0 and 600.")]
        public int DurationMonths { get; set; }
    }

    public class UpdateExperienceDto : CreateExperienceDto
    {
    }

    // ==========================================
    // CERTIFICATE DTOS
    // ==========================================

    public class CertificateDto
    {
        public int Id { get; set; }
        public int CandidateId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string IssuingOrganization { get; set; } = string.Empty;
        public DateTime IssueDate { get; set; }
        public string CertificateUrl { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class CreateCertificateDto
    {
        [Required(ErrorMessage = "Certificate title is required."), MaxLength(150)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(150)]
        public string IssuingOrganization { get; set; } = string.Empty;

        public DateTime IssueDate { get; set; } = DateTime.UtcNow;

        [MaxLength(500)]
        [Url(ErrorMessage = "CertificateUrl must be a valid URL.")]
        public string CertificateUrl { get; set; } = string.Empty;
    }

    // ==========================================
    // CV & DOCUMENT DTOS
    // ==========================================

    public class CVDocumentDto
    {
        public int Id { get; set; }
        public int CandidateId { get; set; }
        public string FileName { get; set; } = string.Empty;
        public string FilePath { get; set; } = string.Empty;
        public long FileSizeBytes { get; set; }
        public string ContentType { get; set; } = string.Empty;
        public DateTime UploadedAt { get; set; }
    }

    // ==========================================
    // CAREER PREFERENCES DTOS
    // ==========================================

    public class CandidatePreferenceDto
    {
        public int Id { get; set; }
        public int CandidateId { get; set; }
        public string PreferredLocation { get; set; } = "Colombo";
        public string PreferredWorkType { get; set; } = "FullTime";
        public decimal ExpectedStipend { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class UpdateCandidatePreferenceDto
    {
        [MaxLength(100)]
        public string PreferredLocation { get; set; } = "Colombo";

        [MaxLength(50)]
        [RegularExpression("^(FullTime|PartTime|Remote|Internship)$", ErrorMessage = "PreferredWorkType must be 'FullTime', 'PartTime', 'Remote', or 'Internship'.")]
        public string PreferredWorkType { get; set; } = "FullTime";

        [Range(0, 1000000, ErrorMessage = "Expected stipend must be non-negative.")]
        public decimal ExpectedStipend { get; set; } = 0;
    }

    // ==========================================
    // PROFILE COMPLETENESS DTOS
    // ==========================================

    public class ProfileCompletenessDto
    {
        public int CandidateId { get; set; }
        public bool IsComplete { get; set; }
        public int CompletionPercentage { get; set; }
        public List<string> MissingFields { get; set; } = new();
        public List<string> CompletedFields { get; set; } = new();
        public DateTime EvaluatedAt { get; set; } = DateTime.UtcNow;
    }
}
