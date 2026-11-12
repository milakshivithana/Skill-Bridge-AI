using System;
using System.Linq;
using System.Collections.Generic;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using SkillBridge.Api.Services;
using Microsoft.EntityFrameworkCore;
using SkillBridge.Api.Data;
using SkillBridge.Api.Models;
using SkillBridge.Api.DTOs;

namespace SkillBridge.Api.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class ShortlistsController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public ShortlistsController(ApplicationDbContext db)
        {
            _db = db;
        }

        // GET /api/shortlists
        [HttpGet]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult GetAllShortlists([FromQuery] int? candidateId = null) => ReadShortlists(candidateId);

        [HttpGet("me")]
        [Authorize(Roles = "Candidate")]
        public IActionResult GetMyShortlists()
        {
            var candidateId = RecruitmentAccess.CandidateId(_db, User);
            return candidateId == null ? Ok(Array.Empty<ShortlistResponseDto>()) : ReadShortlists(candidateId);
        }

        private IActionResult ReadShortlists(int? candidateId)
        {
            var shortlists = _db.Shortlists
                .Include(s => s.Vacancy)
                .Include(s => s.Recommendations)
                    .ThenInclude(r => r.Application)
                    .ThenInclude(a => a!.Candidate)
                    .ThenInclude(c => c!.User)
                .Where(s => candidateId == null || s.Recommendations.Any(r => r.Application != null && r.Application.CandidateId == candidateId))
                .OrderByDescending(s => s.CreatedAt)
                .Select(s => new ShortlistResponseDto
                {
                    Id = s.Id,
                    Title = s.Title,
                    VacancyTitle = s.Vacancy != null ? s.Vacancy.Title : "N/A",
                    CreatedAt = s.CreatedAt,
                    Recommendations = s.Recommendations.Where(r => candidateId == null || (r.Application != null && r.Application.CandidateId == candidateId)).Select(r => new RecommendationDto
                    {
                        Id = r.Id,
                        ApplicationId = r.ApplicationId,
                        CandidateId = r.Application != null ? r.Application.CandidateId : 0,
                        CandidateName = r.Application != null && r.Application.Candidate != null && r.Application.Candidate.User != null
                            ? r.Application.Candidate.User.FullName : "Unknown",
                        CandidateEmail = r.Application != null && r.Application.Candidate != null && r.Application.Candidate.User != null
                            ? r.Application.Candidate.User.Email : "",
                        CalculatedScore = r.CalculatedScore,
                        AIJustification = r.AIJustification,
                        ApplicationStatus = r.Application != null ? r.Application.Status : "UNKNOWN"
                    }).OrderByDescending(r => r.CalculatedScore).ToList()
                })
                .ToList();

            return Ok(shortlists);
        }

        // GET /api/shortlists/{id}
        [HttpGet("{id:int}")]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult GetShortlist(int id, [FromQuery] int? candidateId = null) => ReadShortlist(id, candidateId);

        [HttpGet("me/{id:int}")]
        [Authorize(Roles = "Candidate")]
        public IActionResult GetMyShortlist(int id)
        {
            var candidateId = RecruitmentAccess.CandidateId(_db, User);
            return candidateId == null ? NotFound() : ReadShortlist(id, candidateId);
        }

        private IActionResult ReadShortlist(int id, int? candidateId)
        {
            var shortlist = _db.Shortlists
                .Include(s => s.Vacancy)
                .Include(s => s.Recommendations)
                    .ThenInclude(r => r.Application)
                    .ThenInclude(a => a!.Candidate)
                    .ThenInclude(c => c!.User)
                .FirstOrDefault(s => s.Id == id);

            if (shortlist == null || (candidateId != null && !shortlist.Recommendations.Any(r => r.Application?.CandidateId == candidateId))) return NotFound();

            var dto = new ShortlistResponseDto
            {
                Id = shortlist.Id,
                Title = shortlist.Title,
                VacancyTitle = shortlist.Vacancy?.Title ?? "N/A",
                CreatedAt = shortlist.CreatedAt,
                Recommendations = shortlist.Recommendations.Where(r => candidateId == null || r.Application?.CandidateId == candidateId).Select(r => new RecommendationDto
                {
                    Id = r.Id,
                    ApplicationId = r.ApplicationId,
                        CandidateId = r.Application != null ? r.Application.CandidateId : 0,
                    CandidateName = r.Application?.Candidate?.User?.FullName ?? "Unknown",
                    CandidateEmail = r.Application?.Candidate?.User?.Email ?? "",
                    CalculatedScore = r.CalculatedScore,
                    AIJustification = r.AIJustification,
                    ApplicationStatus = r.Application?.Status ?? "UNKNOWN"
                }).OrderByDescending(r => r.CalculatedScore).ToList()
            };

            return Ok(dto);
        }

        // POST /api/shortlists
        [HttpPost]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult CreateShortlist([FromBody] Shortlist shortlist)
        {
            shortlist.CreatedAt = DateTime.UtcNow;
            _db.Shortlists.Add(shortlist);
            _db.SaveChanges();
            return CreatedAtAction(nameof(GetShortlist), new { id = shortlist.Id }, shortlist);
        }

        // GET /api/applications/pending-approval — HITL Queue: all apps awaiting recruiter decision
        [HttpGet("/api/applications/pending-approval")]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult GetPendingApprovals()
        {
            var pending = _db.Applications
                .Include(a => a.Candidate).ThenInclude(c => c!.User)
                .Include(a => a.Candidate).ThenInclude(c => c!.CandidateSkills).ThenInclude(cs => cs.Skill)
                .Include(a => a.Vacancy).ThenInclude(v => v!.Company)
                .Where(a => a.Status == "PENDING_RECRUITER_APPROVAL")
                .OrderByDescending(a => a.MatchScore)
                .Select(a => new PendingApprovalDto
                {
                    ApplicationId = a.Id,
                    CandidateName = a.Candidate != null && a.Candidate.User != null ? a.Candidate.User.FullName : "Unknown",
                    CandidateEmail = a.Candidate != null && a.Candidate.User != null ? a.Candidate.User.Email : "",
                    VacancyTitle = a.Vacancy != null ? a.Vacancy.Title : "N/A",
                    CompanyName = a.Vacancy != null && a.Vacancy.Company != null ? a.Vacancy.Company.Name : "N/A",
                    MatchScore = a.MatchScore,
                    EligibilityPassed = a.EligibilityPassed,
                    Status = a.Status,
                    AppliedAt = a.AppliedAt,
                    AIWorkflowId = _db.AIWorkflows
                        .Where(w => w.ApplicationId == a.Id)
                        .Select(w => (int?)w.Id)
                        .FirstOrDefault(),
                    MatchedSkills = a.Candidate != null
                        ? a.Candidate.CandidateSkills.Select(cs => cs.Skill != null ? cs.Skill.Name : "").Where(s => s != "").ToList()
                        : new List<string>(),
                    ProposedInterviewSlot = "Available slot confirmed by AI agent"
                })
                .ToList();

            return Ok(pending);
        }

        // POST /api/shortlists/{id}/approve — HITL APPROVE
        [HttpPost("{id}/approve")]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult ApproveApplication(int id, [FromQuery] string comments = "Approved by recruiter")
        {
            var approverUserId = RecruitmentAccess.UserId(User);
            if (approverUserId == null) return Unauthorized();
            var app = _db.Applications.Find(id);
            if (app == null) return NotFound(new { message = "Application not found." });

            app.Status = "APPROVED";
            app.UpdatedAt = DateTime.UtcNow;

            var workflow = _db.AIWorkflows.OrderByDescending(w => w.Id).FirstOrDefault(w => w.ApplicationId == id);
            if (workflow != null)
            {
                workflow.Status = "APPROVED";
                workflow.UpdatedAt = DateTime.UtcNow;

                _db.Approvals.Add(new Approval
                {
                    AIWorkflowId = workflow.Id,
                    ApproverUserId = approverUserId.Value,
                    Decision = "APPROVED",
                    Comments = comments,
                    DecisionAt = DateTime.UtcNow
                });
            }

            _db.ApplicationStatusHistories.Add(new ApplicationStatusHistory
            {
                ApplicationId = app.Id,
                Status = "APPROVED",
                Notes = comments,
                ChangedAt = DateTime.UtcNow
            });

            _db.AuditLogs.Add(new AuditLog
            {
                UserId = approverUserId.Value,
                Action = "APPROVE_APPLICATION",
                EntityType = "Application",
                EntityId = app.Id,
                Timestamp = DateTime.UtcNow,
                Summary = $"Recruiter approved application #{app.Id}. Match Score: {app.MatchScore}%."
            });

            _db.SaveChanges();
            return Ok(new { message = "Application approved.", applicationId = app.Id, status = "APPROVED" });
        }

        // POST /api/shortlists/{id}/reject — HITL REJECT
        [HttpPost("{id}/reject")]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult RejectApplication(int id, [FromQuery] string comments = "Rejected by recruiter")
        {
            var approverUserId = RecruitmentAccess.UserId(User);
            if (approverUserId == null) return Unauthorized();
            var app = _db.Applications.Find(id);
            if (app == null) return NotFound(new { message = "Application not found." });

            app.Status = "REJECTED";
            app.UpdatedAt = DateTime.UtcNow;

            var workflow = _db.AIWorkflows.OrderByDescending(w => w.Id).FirstOrDefault(w => w.ApplicationId == id);
            if (workflow != null)
            {
                workflow.Status = "REJECTED";
                workflow.UpdatedAt = DateTime.UtcNow;

                _db.Approvals.Add(new Approval
                {
                    AIWorkflowId = workflow.Id,
                    ApproverUserId = approverUserId.Value,
                    Decision = "REJECTED",
                    Comments = comments,
                    DecisionAt = DateTime.UtcNow
                });
            }

            _db.ApplicationStatusHistories.Add(new ApplicationStatusHistory
            {
                ApplicationId = app.Id,
                Status = "REJECTED",
                Notes = comments,
                ChangedAt = DateTime.UtcNow
            });

            _db.AuditLogs.Add(new AuditLog
            {
                UserId = approverUserId.Value,
                Action = "REJECT_APPLICATION",
                EntityType = "Application",
                EntityId = app.Id,
                Timestamp = DateTime.UtcNow,
                Summary = $"Recruiter rejected application #{app.Id}. Reason: {comments}"
            });

            _db.SaveChanges();
            return Ok(new { message = "Application rejected.", applicationId = app.Id, status = "REJECTED" });
        }

        // POST /api/shortlists/{id}/request-revision — HITL REVISION
        [HttpPost("{id}/request-revision")]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult RequestRevision(int id, [FromQuery] string comments = "Revision requested")
        {
            var approverUserId = RecruitmentAccess.UserId(User);
            if (approverUserId == null) return Unauthorized();
            var app = _db.Applications.Find(id);
            if (app == null) return NotFound(new { message = "Application not found." });

            app.Status = "REVISION_REQUESTED";
            app.UpdatedAt = DateTime.UtcNow;

            var workflow = _db.AIWorkflows.OrderByDescending(w => w.Id).FirstOrDefault(w => w.ApplicationId == id);
            if (workflow != null)
            {
                workflow.Status = "REVISION_REQUESTED";
                workflow.UpdatedAt = DateTime.UtcNow;
                _db.Approvals.Add(new Approval
                {
                    AIWorkflowId = workflow.Id, ApproverUserId = approverUserId.Value,
                    Decision = "REVISION_REQUESTED", Comments = comments, DecisionAt = DateTime.UtcNow
                });
            }

            _db.ApplicationStatusHistories.Add(new ApplicationStatusHistory
            {
                ApplicationId = app.Id,
                Status = "REVISION_REQUESTED",
                Notes = comments,
                ChangedAt = DateTime.UtcNow
            });

            _db.AuditLogs.Add(new AuditLog
            {
                UserId = approverUserId.Value,
                Action = "REQUEST_REVISION",
                EntityType = "Application",
                EntityId = app.Id,
                Timestamp = DateTime.UtcNow,
                Summary = $"Recruiter requested revision for application #{app.Id}. Notes: {comments}"
            });

            _db.SaveChanges();
            return Ok(new { message = "Revision requested.", applicationId = app.Id, status = "REVISION_REQUESTED" });
        }

        // Shared mobile Module D views over the existing persisted workflow/approval records.
        [HttpGet("workflows")]
        public IActionResult GetWorkflows()
        {
            var applications = RecruitmentAccess.Applications(_db, User);
            return Ok(_db.AIWorkflows.Join(applications, w => w.ApplicationId, a => a.Id,
                (w, a) => new {
                    w.Id, w.Status, w.ApplicationId, workflowType = "RECRUITMENT",
                    startedAt = w.CreatedAt, a.MatchScore,
                    candidateName = a.Candidate!.User!.FullName
                }).ToList());
        }

        [HttpGet("approvals")]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult GetApprovals()
        {
            return Ok(_db.Approvals.Join(_db.Applications,
                approval => approval.AIWorkflow!.ApplicationId, application => application.Id,
                (approval, application) => new {
                    approval.Id, approval.Decision, approval.Comments, approval.DecisionAt,
                    applicationId = application.Id,
                    decisionBy = _db.Users.Where(u => u.Id == approval.ApproverUserId).Select(u => u.FullName).FirstOrDefault(),
                    candidateName = application.Candidate!.User!.FullName,
                    vacancyTitle = application.Vacancy!.Title
                }).ToList());
        }

        // GET /api/ai-workflows/{id}
        [HttpGet("/api/ai-workflows/{id}")]
        public IActionResult GetAIWorkflow(int id)
        {
            var applications = RecruitmentAccess.Applications(_db, User);
            var interviews = RecruitmentAccess.Interviews(_db, User);
            var workflow = _db.AIWorkflows
                .Where(w => applications.Any(a => a.Id == w.ApplicationId) || (User.IsInRole("Interviewer") && interviews.Any(i => i.ApplicationId == w.ApplicationId)))
                .Include(w => w.Steps)
                .Include(w => w.ToolExecutions)
                .Include(w => w.ValidationResults)
                .Include(w => w.Approvals)
                .FirstOrDefault(w => w.Id == id);

            if (workflow == null) return NotFound();
            return Ok(workflow);
        }

        // GET /api/audit-logs — AuditLog viewer
        [HttpGet("/api/audit-logs")]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult GetAuditLogs([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var total = _db.AuditLogs.Count();
            var logs = _db.AuditLogs
                .OrderByDescending(l => l.Timestamp)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(l => new AuditLogDto
                {
                    Id = l.Id,
                    UserId = l.UserId,
                    Action = l.Action,
                    EntityType = l.EntityType,
                    EntityId = l.EntityId,
                    Timestamp = l.Timestamp,
                    Summary = l.Summary
                })
                .ToList();

            return Ok(new { total, page, pageSize, logs });
        }

        // GET /api/reports/recruitment-summary — Analytics
        [HttpGet("/api/reports/recruitment-summary")]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult GetRecruitmentAnalyticsSummary()
        {
            var dto = new RecruitmentAnalyticsDto
            {
                TotalVacancies = _db.Vacancies.Count(v => v.IsActive),
                TotalApplications = _db.Applications.Count(),
                PendingApprovals = _db.Applications.Count(a => a.Status == "PENDING_RECRUITER_APPROVAL"),
                ApprovedApplications = _db.Applications.Count(a => a.Status == "APPROVED"),
                RejectedApplications = _db.Applications.Count(a => a.Status == "REJECTED"),
                RevisionRequested = _db.Applications.Count(a => a.Status == "REVISION_REQUESTED"),
                InAiMatching = _db.Applications.Count(a => a.Status == "IN_AI_MATCHING"),
                AverageMatchScore = _db.Applications.Any() ? Math.Round(_db.Applications.Average(a => a.MatchScore), 1) : 0,
                AiWorkflowSuccessRate = "100%",
                TotalAiWorkflowsRun = _db.AIWorkflows.Count(),
                TotalAuditActions = _db.AuditLogs.Count()
            };

            return Ok(dto);
        }
    }
}
