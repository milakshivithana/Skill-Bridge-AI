using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using SkillBridge.Api.Services;
using Microsoft.EntityFrameworkCore;
using SkillBridge.Api.Data;
using SkillBridge.Api.DTOs;
using SkillBridge.Api.Models;

namespace SkillBridge.Api.Controllers
{
    [ApiController]
    [Authorize(Roles = "Candidate,Recruiter,Administrator")]
    [Route("api/[controller]")]
    public class ApplicationsController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public ApplicationsController(ApplicationDbContext db)
        {
            _db = db;
        }

        /// <summary>
        /// Get detailed information about a single application, including status history.
        /// </summary>
        [HttpGet("{id:int}")]
        public IActionResult GetApplication(int id)
        {
            var app = RecruitmentAccess.Applications(_db, User)
                .Include(a => a.Candidate).ThenInclude(c => c!.User)
                .Include(a => a.Vacancy).ThenInclude(v => v!.Company)
                .Include(a => a.StatusHistories)
                .FirstOrDefault(a => a.Id == id);

            if (app == null) return NotFound(new { message = "Application not found." });

            var dto = new ApplicationResponseDto
            {
                Id = app.Id,
                CandidateId = app.CandidateId,
                CandidateName = app.Candidate?.User?.FullName ?? $"Candidate {app.CandidateId}",
                CandidateEmail = app.Candidate?.User?.Email ?? string.Empty,
                VacancyId = app.VacancyId,
                VacancyTitle = app.Vacancy?.Title ?? string.Empty,
                CompanyName = app.Vacancy?.Company?.Name ?? "Independent",
                Status = app.Status,
                MatchScore = app.MatchScore,
                EligibilityPassed = app.EligibilityPassed,
                AppliedAt = app.AppliedAt,
                UpdatedAt = app.UpdatedAt,
                StatusHistories = app.StatusHistories.Select(sh => new ApplicationStatusHistoryDto
                {
                    Id = sh.Id,
                    Status = sh.Status,
                    Notes = sh.Notes,
                    ChangedAt = sh.ChangedAt
                }).OrderBy(sh => sh.ChangedAt).ToList()
            };

            AttachEvaluations(new[] { dto });
            return Ok(dto);
        }

        /// <summary>
        /// Get all applications submitted by a specific candidate.
        /// </summary>
        [HttpGet("me")]
        [HttpGet("/api/vacancies/my-applications")]
        [Authorize(Roles = "Candidate")]
        public IActionResult GetMyApplications()
        {
            var candidateId = RecruitmentAccess.CandidateId(_db, User);
            return candidateId == null ? Ok(Array.Empty<ApplicationResponseDto>()) : GetCandidateApplications(candidateId.Value);
        }

        [HttpGet("candidate/{candidateId}")]
        public IActionResult GetCandidateApplications(int candidateId)
        {
            if (!RecruitmentAccess.IsStaff(User) && RecruitmentAccess.CandidateId(_db, User) != candidateId) return NotFound();
            var apps = RecruitmentAccess.Applications(_db, User)
                .Include(a => a.Candidate).ThenInclude(c => c!.User)
                .Include(a => a.Vacancy).ThenInclude(v => v!.Company)
                .Include(a => a.StatusHistories)
                .Where(a => a.CandidateId == candidateId)
                .OrderByDescending(a => a.AppliedAt)
                .ToList();

            var dtos = apps.Select(app => new ApplicationResponseDto
            {
                Id = app.Id,
                CandidateId = app.CandidateId,
                CandidateName = app.Candidate?.User?.FullName ?? $"Candidate {app.CandidateId}",
                CandidateEmail = app.Candidate?.User?.Email ?? string.Empty,
                VacancyId = app.VacancyId,
                VacancyTitle = app.Vacancy?.Title ?? string.Empty,
                CompanyName = app.Vacancy?.Company?.Name ?? "Independent",
                Status = app.Status,
                MatchScore = app.MatchScore,
                EligibilityPassed = app.EligibilityPassed,
                AppliedAt = app.AppliedAt,
                UpdatedAt = app.UpdatedAt,
                StatusHistories = app.StatusHistories.Select(sh => new ApplicationStatusHistoryDto
                {
                    Id = sh.Id,
                    Status = sh.Status,
                    Notes = sh.Notes,
                    ChangedAt = sh.ChangedAt
                }).OrderBy(sh => sh.ChangedAt).ToList()
            }).ToList();

            AttachEvaluations(dtos);
            return Ok(dtos);
        }

        /// <summary>
        /// Get all applications submitted for a specific vacancy (Recruiter View).
        /// </summary>
        [HttpGet("vacancy/{vacancyId}")]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult GetVacancyApplications(int vacancyId)
        {
            var apps = RecruitmentAccess.Applications(_db, User)
                .Include(a => a.Candidate).ThenInclude(c => c!.User)
                .Include(a => a.Vacancy).ThenInclude(v => v!.Company)
                .Include(a => a.StatusHistories)
                .Where(a => a.VacancyId == vacancyId)
                .OrderByDescending(a => a.AppliedAt)
                .ToList();

            var dtos = apps.Select(app => new ApplicationResponseDto
            {
                Id = app.Id,
                CandidateId = app.CandidateId,
                CandidateName = app.Candidate?.User?.FullName ?? $"Candidate {app.CandidateId}",
                CandidateEmail = app.Candidate?.User?.Email ?? string.Empty,
                VacancyId = app.VacancyId,
                VacancyTitle = app.Vacancy?.Title ?? string.Empty,
                CompanyName = app.Vacancy?.Company?.Name ?? "Independent",
                Status = app.Status,
                MatchScore = app.MatchScore,
                EligibilityPassed = app.EligibilityPassed,
                AppliedAt = app.AppliedAt,
                UpdatedAt = app.UpdatedAt,
                StatusHistories = app.StatusHistories.Select(sh => new ApplicationStatusHistoryDto
                {
                    Id = sh.Id,
                    Status = sh.Status,
                    Notes = sh.Notes,
                    ChangedAt = sh.ChangedAt
                }).OrderBy(sh => sh.ChangedAt).ToList()
            }).ToList();

            AttachEvaluations(dtos);
            return Ok(dtos);
        }

        // Only call with DTOs obtained through RecruitmentAccess ownership filtering.
        private void AttachEvaluations(IEnumerable<ApplicationResponseDto> applications)
        {
            var byId = applications.ToDictionary(a => a.Id);
            var ids = byId.Keys.ToArray();
            var workflows = _db.AIWorkflows.AsNoTracking().Include(w => w.Steps)
                .Where(w => ids.Contains(w.ApplicationId)).OrderByDescending(w => w.Id).ToList();
            foreach (var workflow in workflows.GroupBy(w => w.ApplicationId).Select(g => g.First()))
            {
                var app = byId[workflow.ApplicationId];
                System.Text.Json.JsonElement? evidence = null;
                foreach (var step in workflow.Steps.OrderByDescending(s => s.Id))
                {
                    try
                    {
                        using var json = System.Text.Json.JsonDocument.Parse(step.StructuredOutput);
                        if (json.RootElement.ValueKind == System.Text.Json.JsonValueKind.Object &&
                            json.RootElement.TryGetProperty("match_score", out _))
                        { evidence = json.RootElement.Clone(); break; }
                    }
                    catch (System.Text.Json.JsonException) { /* Legacy evidence may be unavailable. */ }
                }
                app.Evaluation = new ApplicationEvaluationDto
                {
                    WorkflowId = workflow.Id, EvaluatedAt = workflow.CreatedAt,
                    MatchScore = app.MatchScore, Evidence = evidence
                };
            }
        }

        /// <summary>
        /// Candidate action to withdraw an active application.
        /// </summary>
        [HttpPost("{id}/withdraw")]
        public IActionResult WithdrawApplication(int id, [FromQuery] string? reason = "Withdrawn by candidate.")
        {
            var app = RecruitmentAccess.Applications(_db, User).FirstOrDefault(a => a.Id == id);
            if (app == null) return NotFound(new { message = "Application not found." });

            if (app.Status == "WITHDRAWN")
            {
                return BadRequest(new { message = "Application has already been withdrawn." });
            }

            if (app.Status == "REJECTED")
            {
                return BadRequest(new { message = "Cannot withdraw a rejected application." });
            }

            string previousStatus = app.Status;
            app.Status = "WITHDRAWN";
            app.UpdatedAt = DateTime.UtcNow;

            _db.ApplicationStatusHistories.Add(new ApplicationStatusHistory
            {
                ApplicationId = app.Id,
                Status = "WITHDRAWN",
                Notes = string.IsNullOrWhiteSpace(reason) ? $"Withdrawn by candidate (Previous status: {previousStatus})." : reason,
                ChangedAt = DateTime.UtcNow
            });

            _db.AuditLogs.Add(new AuditLog
            {
                UserId = RecruitmentAccess.UserId(User) ?? 0,
                Action = "WITHDRAW_APPLICATION",
                EntityType = "Application",
                EntityId = app.Id,
                Timestamp = DateTime.UtcNow,
                Summary = $"Candidate {app.CandidateId} withdrew application #{app.Id} for vacancy #{app.VacancyId}."
            });

            _db.SaveChanges();

            return Ok(new { message = "Application successfully withdrawn.", applicationId = app.Id, status = app.Status });
        }

        /// <summary>
        /// MEMBER 2 BUSINESS-SPECIFIC OPERATION:
        /// Evaluates mandatory non-negotiable vacancy requirements and mandatory skill match
        /// against candidate profile before allowing application progression.
        /// </summary>
        [HttpPost("{id}/eligibility-check")]
        public IActionResult PerformEligibilityCheck(int id)
        {
            var app = RecruitmentAccess.Applications(_db, User)
                .Include(a => a.Candidate).ThenInclude(c => c!.CandidateSkills).ThenInclude(cs => cs.Skill)
                .Include(a => a.Vacancy).ThenInclude(v => v!.VacancySkills).ThenInclude(vs => vs.Skill)
                .Include(a => a.Vacancy).ThenInclude(v => v!.VacancyRequirements)
                .FirstOrDefault(a => a.Id == id);

            if (app == null) return NotFound(new { message = "Application not found." });

            var candidateSkills = app.Candidate?.CandidateSkills
                .Where(cs => cs.Skill != null)
                .Select(cs => cs.Skill!.Name.Trim().ToLower())
                .ToHashSet() ?? new HashSet<string>();

            var vacancySkills = app.Vacancy?.VacancySkills ?? new List<VacancySkill>();
            var mandatorySkills = vacancySkills
                .Where(vs => vs.IsMandatory && vs.Skill != null)
                .Select(vs => vs.Skill!.Name)
                .ToList();

            var matchedSkills = new List<string>();
            var missingMandatorySkills = new List<string>();

            foreach (var reqSkill in mandatorySkills)
            {
                if (candidateSkills.Contains(reqSkill.Trim().ToLower()))
                {
                    matchedSkills.Add(reqSkill);
                }
                else
                {
                    missingMandatorySkills.Add(reqSkill);
                }
            }

            var requirements = app.Vacancy?.VacancyRequirements ?? new List<VacancyRequirement>();
            var nonNegotiables = requirements.Where(r => r.IsNonNegotiable).ToList();

            var passedRequirements = new List<string>();
            var failedRequirements = new List<string>();

            // Evaluate deterministic rules: candidate profile complete & mandatory skills met
            bool profileComplete = app.Candidate?.IsProfileComplete ?? true;
            if (!profileComplete)
            {
                failedRequirements.Add("Candidate profile must be 100% complete with CV and skills.");
            }
            else
            {
                passedRequirements.Add("Candidate profile completeness verified.");
            }

            foreach (var nn in nonNegotiables)
            {
                // Verify requirement keyword matching against candidate skills
                string text = nn.RequirementText;
                bool isPassed = true;

                if (missingMandatorySkills.Any() && (text.ToLower().Contains("skill") || text.ToLower().Contains("proficienc")))
                {
                    isPassed = false;
                }

                if (isPassed)
                {
                    passedRequirements.Add(text);
                }
                else
                {
                    failedRequirements.Add(text);
                }
            }

            bool isEligible = !missingMandatorySkills.Any() && !failedRequirements.Any();

            app.EligibilityPassed = isEligible;
            app.UpdatedAt = DateTime.UtcNow;

            string summaryNotes = isEligible
                ? $"Candidate meets all {mandatorySkills.Count} mandatory skills and non-negotiable vacancy requirements."
                : $"Eligibility check failed. Missing mandatory skills: [{string.Join(", ", missingMandatorySkills)}]. Failed rules: [{string.Join(", ", failedRequirements)}].";

            _db.ApplicationStatusHistories.Add(new ApplicationStatusHistory
            {
                ApplicationId = app.Id,
                Status = app.Status,
                Notes = $"Eligibility Check: {(isEligible ? "PASSED" : "FAILED")}. {summaryNotes}",
                ChangedAt = DateTime.UtcNow
            });

            _db.SaveChanges();

            return Ok(new EligibilityCheckResultDto
            {
                CandidateId = app.CandidateId,
                VacancyId = app.VacancyId,
                IsEligible = isEligible,
                PassedRequirements = passedRequirements,
                FailedRequirements = failedRequirements,
                MatchedSkills = matchedSkills,
                MissingMandatorySkills = missingMandatorySkills,
                SummaryNotes = summaryNotes
            });
        }
    }
}
