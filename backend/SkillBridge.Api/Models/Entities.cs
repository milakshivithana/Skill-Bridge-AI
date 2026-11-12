using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SkillBridge.Api.Models
{
    // ==========================================
    // SHARED USER & IDENTITY ENTITIES
    // ==========================================
    public class User
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(100)]
        public string FullName { get; set; } = string.Empty;

        [Required, MaxLength(150)]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string PasswordHash { get; set; } = string.Empty;

        [Required, MaxLength(50)]
        public string Role { get; set; } = "Candidate"; // Candidate, Recruiter, Interviewer, Administrator

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation
        public Candidate? CandidateProfile { get; set; }
        public Interviewer? InterviewerProfile { get; set; }
    }

    // ==========================================
    // COMPONENT A: CANDIDATE PROFILE & SKILL MANAGEMENT
    // ==========================================
    public class Candidate
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("User")]
        public int UserId { get; set; }
        public User? User { get; set; }

        [MaxLength(20)]
        public string Phone { get; set; } = string.Empty;

        [MaxLength(100)]
        public string City { get; set; } = string.Empty;

        [MaxLength(2000)]
        public string Bio { get; set; } = string.Empty;

        [MaxLength(255)]
        public string? LinkedInUrl { get; set; }

        [MaxLength(255)]
        public string? PortfolioUrl { get; set; }

        public bool IsProfileComplete { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigations
        public List<CandidateSkill> CandidateSkills { get; set; } = new();
        public List<Education> Educations { get; set; } = new();
        public List<Experience> Experiences { get; set; } = new();
        public List<Certificate> Certificates { get; set; } = new();
        public List<CVDocument> CVDocuments { get; set; } = new();
        public CandidatePreference? Preference { get; set; }
        public List<Application> Applications { get; set; } = new();
    }

    public class Skill
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(50)]
        public string Category { get; set; } = "General"; // Programming, SoftSkill, Tool, Framework
    }

    public class CandidateSkill
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Candidate")]
        public int CandidateId { get; set; }
        public Candidate? Candidate { get; set; }

        [ForeignKey("Skill")]
        public int SkillId { get; set; }
        public Skill? Skill { get; set; }

        [MaxLength(50)]
        public string ProficiencyLevel { get; set; } = "Intermediate"; // Beginner, Intermediate, Expert

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    public class Education
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Candidate")]
        public int CandidateId { get; set; }
        public Candidate? Candidate { get; set; }

        [Required, MaxLength(150)]
        public string Institution { get; set; } = string.Empty;

        [Required, MaxLength(150)]
        public string Degree { get; set; } = string.Empty;

        [MaxLength(100)]
        public string FieldOfStudy { get; set; } = string.Empty;

        public int StartYear { get; set; }
        public int EndYear { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }

    public class Experience
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Candidate")]
        public int CandidateId { get; set; }
        public Candidate? Candidate { get; set; }

        [Required, MaxLength(150)]
        public string CompanyName { get; set; } = string.Empty;

        [Required, MaxLength(100)]
        public string JobTitle { get; set; } = string.Empty;

        [MaxLength(500)]
        public string Description { get; set; } = string.Empty;

        public int DurationMonths { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }

    public class Certificate
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Candidate")]
        public int CandidateId { get; set; }
        public Candidate? Candidate { get; set; }

        [Required, MaxLength(150)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(150)]
        public string IssuingOrganization { get; set; } = string.Empty;

        public DateTime IssueDate { get; set; }

        [MaxLength(500)]
        public string CertificateUrl { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }

    public class CVDocument
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Candidate")]
        public int CandidateId { get; set; }
        public Candidate? Candidate { get; set; }

        [Required, MaxLength(255)]
        public string FileName { get; set; } = string.Empty;

        [Required, MaxLength(500)]
        public string FilePath { get; set; } = string.Empty;

        public long FileSizeBytes { get; set; } = 0;

        [MaxLength(100)]
        public string ContentType { get; set; } = "application/pdf";

        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    }

    public class CandidatePreference
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Candidate")]
        public int CandidateId { get; set; }
        public Candidate? Candidate { get; set; }

        [MaxLength(100)]
        public string PreferredLocation { get; set; } = "Colombo";

        [MaxLength(50)]
        public string PreferredWorkType { get; set; } = "FullTime"; // FullTime, PartTime, Remote, Internship

        public decimal ExpectedStipend { get; set; } = 0;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }

    // ==========================================
    // COMPONENT B: VACANCY & APPLICATION MANAGEMENT
    // ==========================================
    public class Company
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(150)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(200)]
        public string Industry { get; set; } = string.Empty;

        [MaxLength(100)]
        public string Location { get; set; } = string.Empty;

        [MaxLength(500)]
        public string Website { get; set; } = string.Empty;

        public List<Vacancy> Vacancies { get; set; } = new();
    }

    public class Vacancy
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Company")]
        public int CompanyId { get; set; }
        public Company? Company { get; set; }

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

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public List<VacancySkill> VacancySkills { get; set; } = new();
        public List<VacancyRequirement> VacancyRequirements { get; set; } = new();
        public List<Application> Applications { get; set; } = new();
    }

    public class VacancySkill
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Vacancy")]
        public int VacancyId { get; set; }
        public Vacancy? Vacancy { get; set; }

        [ForeignKey("Skill")]
        public int SkillId { get; set; }
        public Skill? Skill { get; set; }

        public bool IsMandatory { get; set; } = true;
    }

    public class VacancyRequirement
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Vacancy")]
        public int VacancyId { get; set; }

        [Required, MaxLength(255)]
        public string RequirementText { get; set; } = string.Empty;

        public bool IsNonNegotiable { get; set; } = true;
    }

    public class Application
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Candidate")]
        public int CandidateId { get; set; }
        public Candidate? Candidate { get; set; }

        [ForeignKey("Vacancy")]
        public int VacancyId { get; set; }
        public Vacancy? Vacancy { get; set; }

        [Required, MaxLength(50)]
        public string Status { get; set; } = "SUBMITTED"; // SUBMITTED, IN_AI_MATCHING, PENDING_RECRUITER_APPROVAL, APPROVED, REJECTED, REVISION_REQUESTED

        public double MatchScore { get; set; } = 0.0;
        public bool EligibilityPassed { get; set; } = false;

        public DateTime AppliedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public List<ApplicationStatusHistory> StatusHistories { get; set; } = new();
        public List<Interview> Interviews { get; set; } = new();
    }

    public class ApplicationStatusHistory
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Application")]
        public int ApplicationId { get; set; }

        [Required, MaxLength(50)]
        public string Status { get; set; } = string.Empty;

        [MaxLength(255)]
        public string Notes { get; set; } = string.Empty;

        public DateTime ChangedAt { get; set; } = DateTime.UtcNow;
    }

    public class SavedVacancy
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Candidate")]
        public int CandidateId { get; set; }

        [ForeignKey("Vacancy")]
        public int VacancyId { get; set; }

        public DateTime SavedAt { get; set; } = DateTime.UtcNow;
    }

    // ==========================================
    // COMPONENT C: INTERVIEW & SCHEDULING MANAGEMENT
    // ==========================================
    public class Interviewer
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("User")]
        public int UserId { get; set; }
        public User? User { get; set; }

        [MaxLength(100)]
        public string Department { get; set; } = "Engineering";

        public List<Availability> Availabilities { get; set; } = new();
    }

    public class Interview
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Application")]
        public int ApplicationId { get; set; }
        public Application? Application { get; set; }

        [ForeignKey("Interviewer")]
        public int? InterviewerId { get; set; }
        public Interviewer? Interviewer { get; set; }

        public DateTime ScheduledTime { get; set; }
        public int DurationMinutes { get; set; } = 45;

        [Required, MaxLength(50)]
        public string Status { get; set; } = "SCHEDULED"; // SCHEDULED, CONFIRMED, COMPLETED, RESCHEDULED, CANCELLED

        [MaxLength(500)]
        public string MeetingLinkOrLocation { get; set; } = "Online Teams Meeting";

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public List<InterviewScore> Scores { get; set; } = new();
        public List<InterviewFeedback> Feedbacks { get; set; } = new();
    }

    public class InterviewSlot
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Interviewer")]
        public int InterviewerId { get; set; }

        public DateTime SlotStartTime { get; set; }
        public DateTime SlotEndTime { get; set; }
        public bool IsBooked { get; set; } = false;
    }

    public class Availability
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Interviewer")]
        public int InterviewerId { get; set; }

        [MaxLength(20)]
        public string DayOfWeek { get; set; } = "Monday";

        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
    }

    public class InterviewScore
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Interview")]
        public int InterviewId { get; set; }

        [Required, MaxLength(100)]
        public string MetricName { get; set; } = "Technical Competency";

        public int Score { get; set; } // 1 to 5 scale
    }

    public class InterviewFeedback
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Interview")]
        public int InterviewId { get; set; }

        [Required, MaxLength(1000)]
        public string Comments { get; set; } = string.Empty;

        [Required, MaxLength(50)]
        public string OutcomeRecommendation { get; set; } = "RECOMMEND_HIRE"; // RECOMMEND_HIRE, REJECT, SECOND_ROUND
    }

    // ==========================================
    // COMPONENT D: SHORTLISTING, APPROVAL & ANALYTICS
    // ==========================================
    public class Shortlist
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Vacancy")]
        public int VacancyId { get; set; }
        public Vacancy? Vacancy { get; set; }

        [Required, MaxLength(100)]
        public string Title { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public List<Recommendation> Recommendations { get; set; } = new();
    }

    public class Recommendation
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Shortlist")]
        public int ShortlistId { get; set; }

        [ForeignKey("Application")]
        public int ApplicationId { get; set; }
        public Application? Application { get; set; }

        public double CalculatedScore { get; set; }

        [Required, MaxLength(500)]
        public string AIJustification { get; set; } = string.Empty;
    }

    public class AIWorkflow
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(100)]
        public string WorkflowId { get; set; } = string.Empty;

        [Required, MaxLength(255)]
        public string Objective { get; set; } = string.Empty;

        public int ApplicationId { get; set; }

        [Required, MaxLength(50)]
        public string Status { get; set; } = "IN_PROGRESS"; // IN_PROGRESS, PENDING_RECRUITER_APPROVAL, APPROVED, REJECTED, REVISION_REQUESTED

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public List<AIWorkflowStep> Steps { get; set; } = new();
        public List<AIToolExecution> ToolExecutions { get; set; } = new();
        public List<AIValidationResult> ValidationResults { get; set; } = new();
        public List<Approval> Approvals { get; set; } = new();
    }

    public class AIWorkflowStep
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("AIWorkflow")]
        public int AIWorkflowId { get; set; }

        [Required, MaxLength(100)]
        public string AgentName { get; set; } = string.Empty;

        [Required, MaxLength(100)]
        public string StepName { get; set; } = string.Empty;

        [Required, MaxLength(50)]
        public string Status { get; set; } = "COMPLETED";

        public string StructuredInput { get; set; } = "{}";
        public string StructuredOutput { get; set; } = "{}";

        public DateTime StartedAt { get; set; } = DateTime.UtcNow;
        public DateTime CompletedAt { get; set; } = DateTime.UtcNow;
    }

    public class AIToolExecution
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("AIWorkflow")]
        public int AIWorkflowId { get; set; }

        [Required, MaxLength(100)]
        public string ToolName { get; set; } = string.Empty;

        public string InputJson { get; set; } = "{}";
        public string OutputJson { get; set; } = "{}";

        public long ExecutionTimeMs { get; set; }
    }

    public class AIValidationResult
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("AIWorkflow")]
        public int AIWorkflowId { get; set; }

        [Required, MaxLength(100)]
        public string ValidationType { get; set; } = "AllowedAttributeCheck"; // AllowedAttributeCheck, MandatoryEligibility, SchemaCheck

        public bool IsValid { get; set; } = true;
        public string Errors { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    public class Approval
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("AIWorkflow")]
        public int AIWorkflowId { get; set; }
        public AIWorkflow? AIWorkflow { get; set; }

        public int ApproverUserId { get; set; }

        [Required, MaxLength(50)]
        public string Decision { get; set; } = "APPROVED"; // APPROVED, REJECTED, REVISION_REQUESTED

        [MaxLength(500)]
        public string Comments { get; set; } = string.Empty;

        public DateTime DecisionAt { get; set; } = DateTime.UtcNow;
    }

    public class AuditLog
    {
        [Key]
        public int Id { get; set; }

        public int UserId { get; set; }

        [Required, MaxLength(100)]
        public string Action { get; set; } = string.Empty;

        [Required, MaxLength(100)]
        public string EntityType { get; set; } = string.Empty;

        public int EntityId { get; set; }

        public DateTime Timestamp { get; set; } = DateTime.UtcNow;

        [MaxLength(500)]
        public string Summary { get; set; } = string.Empty;
    }
}
