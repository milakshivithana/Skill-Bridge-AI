using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace SkillBridge.Api.DTOs
{
    public class CreateVacancyDto
    {
        [Required, MaxLength(150)]
        public string Title { get; set; } = string.Empty;

        [Required, MaxLength(1000)]
        public string Description { get; set; } = string.Empty;

        [MaxLength(100)]
        public string Location { get; set; } = "Colombo";

        [MaxLength(50)]
        public string EmploymentType { get; set; } = "Internship";

        public int CompanyId { get; set; }

        public DateTime ApplicationDeadline { get; set; } = DateTime.UtcNow.AddDays(30);

        public List<VacancySkillInputDto> Skills { get; set; } = new();
        public List<VacancyRequirementInputDto> Requirements { get; set; } = new();
    }

    public class UpdateVacancyDto
    {
        [Required, MaxLength(150)]
        public string Title { get; set; } = string.Empty;

        [Required, MaxLength(1000)]
        public string Description { get; set; } = string.Empty;

        [MaxLength(100)]
        public string Location { get; set; } = "Colombo";

        [MaxLength(50)]
        public string EmploymentType { get; set; } = "Internship";

        public bool IsActive { get; set; } = true;
        public DateTime ApplicationDeadline { get; set; } = DateTime.UtcNow.AddDays(30);

        public List<VacancySkillInputDto> Skills { get; set; } = new();
        public List<VacancyRequirementInputDto> Requirements { get; set; } = new();
    }

    public class VacancySkillInputDto
    {
        public int SkillId { get; set; }
        public string SkillName { get; set; } = string.Empty;
        public bool IsMandatory { get; set; } = true;
    }

    public class VacancyRequirementInputDto
    {
        [Required, MaxLength(255)]
        public string RequirementText { get; set; } = string.Empty;
        public bool IsNonNegotiable { get; set; } = true;
    }

    public class VacancyFilterDto
    {
        public string? SearchQuery { get; set; }
        public string? Location { get; set; }
        public string? EmploymentType { get; set; }
        public int? CompanyId { get; set; }
        public bool? IsActive { get; set; } = true;
        public string SortBy { get; set; } = "date_desc"; // date_desc, date_asc, title_asc, title_desc
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }

    public class VacancyResponseDto
    {
        public int Id { get; set; }
        public int CompanyId { get; set; }
        public string CompanyName { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public string EmploymentType { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public DateTime ApplicationDeadline { get; set; }
        public DateTime CreatedAt { get; set; }
        public int ApplicationCount { get; set; }
        public bool HasApplied { get; set; }
        // Withdrawal is terminal: retain history and expose its state separately.
        public string? CurrentApplicationStatus { get; set; }
        public List<VacancySkillDto> Skills { get; set; } = new();
        public List<VacancyRequirementDto> Requirements { get; set; } = new();
    }

    public class VacancySkillDto
    {
        public int SkillId { get; set; }
        public string SkillName { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public bool IsMandatory { get; set; }
    }

    public class VacancyRequirementDto
    {
        public int Id { get; set; }
        public string RequirementText { get; set; } = string.Empty;
        public bool IsNonNegotiable { get; set; }
    }

    public class CompanyDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Industry { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public string Website { get; set; } = string.Empty;
        public int ActiveVacanciesCount { get; set; }
    }

    public class CreateCompanyDto
    {
        [Required, MaxLength(150)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(200)]
        public string Industry { get; set; } = string.Empty;

        [MaxLength(100)]
        public string Location { get; set; } = string.Empty;

        [MaxLength(500)]
        public string Website { get; set; } = string.Empty;
    }

    public class ApplicationSubmissionDto
    {
        [Required]
        public int CandidateId { get; set; }

        [Required]
        public int VacancyId { get; set; }
    }

    public class ApplicationEvaluationDto
    {
        public int WorkflowId { get; set; }
        public DateTime EvaluatedAt { get; set; }
        public double MatchScore { get; set; }
        public System.Text.Json.JsonElement? Evidence { get; set; }
    }

    public class ApplicationResponseDto
    {
        public ApplicationEvaluationDto? Evaluation { get; set; }
        public int Id { get; set; }
        public int CandidateId { get; set; }
        public string CandidateName { get; set; } = string.Empty;
        public string CandidateEmail { get; set; } = string.Empty;
        public int VacancyId { get; set; }
        public string VacancyTitle { get; set; } = string.Empty;
        public string CompanyName { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public double MatchScore { get; set; }
        public bool EligibilityPassed { get; set; }
        public DateTime AppliedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public List<ApplicationStatusHistoryDto> StatusHistories { get; set; } = new();
    }

    public class ApplicationStatusHistoryDto
    {
        public int Id { get; set; }
        public string Status { get; set; } = string.Empty;
        public string Notes { get; set; } = string.Empty;
        public DateTime ChangedAt { get; set; }
    }

    public class EligibilityCheckResultDto
    {
        public int CandidateId { get; set; }
        public int VacancyId { get; set; }
        public bool IsEligible { get; set; }
        public List<string> PassedRequirements { get; set; } = new();
        public List<string> FailedRequirements { get; set; } = new();
        public List<string> MatchedSkills { get; set; } = new();
        public List<string> MissingMandatorySkills { get; set; } = new();
        public string SummaryNotes { get; set; } = string.Empty;
    }

    public class SavedVacancyDto
    {
        public int Id { get; set; }
        public int CandidateId { get; set; }
        public int VacancyId { get; set; }
        public string VacancyTitle { get; set; } = string.Empty;
        public string CompanyName { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public string EmploymentType { get; set; } = string.Empty;
        public DateTime SavedAt { get; set; }
    }

    public class PaginatedListDto<T>
    {
        public List<T> Items { get; set; } = new();
        public int TotalCount { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
        public int TotalPages { get; set; }
    }
}
