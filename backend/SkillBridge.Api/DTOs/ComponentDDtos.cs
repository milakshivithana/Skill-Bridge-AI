using System;
using System.Collections.Generic;

namespace SkillBridge.Api.DTOs
{
    // ==========================================
    // COMPONENT D DTOs: Shortlisting, Approval & Analytics
    // ==========================================

    public class PendingApprovalDto
    {
        public int ApplicationId { get; set; }
        public string CandidateName { get; set; } = string.Empty;
        public string CandidateEmail { get; set; } = string.Empty;
        public string VacancyTitle { get; set; } = string.Empty;
        public string CompanyName { get; set; } = string.Empty;
        public double MatchScore { get; set; }
        public bool EligibilityPassed { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime AppliedAt { get; set; }
        public int? AIWorkflowId { get; set; }
        public string AIJustification { get; set; } = "AI matching complete. Awaiting recruiter approval.";
        public List<string> MatchedSkills { get; set; } = new();
        public string ProposedInterviewSlot { get; set; } = string.Empty;
    }

    public class ApprovalDecisionDto
    {
        public string Decision { get; set; } = string.Empty; // APPROVED, REJECTED, REVISION_REQUESTED
        public string Comments { get; set; } = string.Empty;
    }

    public class AuditLogDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Action { get; set; } = string.Empty;
        public string EntityType { get; set; } = string.Empty;
        public int EntityId { get; set; }
        public DateTime Timestamp { get; set; }
        public string Summary { get; set; } = string.Empty;
    }

    public class ShortlistResponseDto
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string VacancyTitle { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public List<RecommendationDto> Recommendations { get; set; } = new();
    }

    public class RecommendationDto
    {
        public int Id { get; set; }
        public int ApplicationId { get; set; }
        public int CandidateId { get; set; }
        public string CandidateName { get; set; } = string.Empty;
        public string CandidateEmail { get; set; } = string.Empty;
        public double CalculatedScore { get; set; }
        public string AIJustification { get; set; } = string.Empty;
        public string ApplicationStatus { get; set; } = string.Empty;
    }

    public class RecruitmentAnalyticsDto
    {
        public int TotalVacancies { get; set; }
        public int TotalApplications { get; set; }
        public int PendingApprovals { get; set; }
        public int ApprovedApplications { get; set; }
        public int RejectedApplications { get; set; }
        public int RevisionRequested { get; set; }
        public int InAiMatching { get; set; }
        public double AverageMatchScore { get; set; }
        public string AiWorkflowSuccessRate { get; set; } = "100%";
        public int TotalAiWorkflowsRun { get; set; }
        public int TotalAuditActions { get; set; }
    }
}
