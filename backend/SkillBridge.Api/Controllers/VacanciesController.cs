using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using SkillBridge.Api.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using SkillBridge.Api.Data;
using SkillBridge.Api.DTOs;
using SkillBridge.Api.Models;

namespace SkillBridge.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class VacanciesController : ControllerBase
    {
        private readonly ApplicationDbContext _db;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _config;

        public VacanciesController(ApplicationDbContext db, IHttpClientFactory httpClientFactory, IConfiguration config)
        {
            _db = db;
            _httpClientFactory = httpClientFactory;
            _config = config;
        }

        [HttpGet]
        public IActionResult GetVacancies(
            [FromQuery] string? searchQuery = null,
            [FromQuery] string? location = null,
            [FromQuery] string? employmentType = null,
            [FromQuery] int? companyId = null,
            [FromQuery] bool? isActive = true,
            [FromQuery] string sortBy = "date_desc",
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var currentCandidateId = RecruitmentAccess.CandidateId(_db, User);
            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);
            var query = _db.Vacancies
                .Include(v => v.Company)
                .Include(v => v.VacancySkills).ThenInclude(vs => vs.Skill)
                .Include(v => v.VacancyRequirements)
                .Include(v => v.Applications)
                .AsQueryable();

            if (isActive.HasValue)
            {
                query = query.Where(v => v.IsActive == isActive.Value);
            }

            if (!string.IsNullOrWhiteSpace(searchQuery))
            {
                var term = searchQuery.Trim().ToLower();
                query = query.Where(v => v.Title.ToLower().Contains(term) ||
                                         v.Description.ToLower().Contains(term) ||
                                         (v.Company != null && v.Company.Name.ToLower().Contains(term)));
            }

            if (!string.IsNullOrWhiteSpace(location))
            {
                var loc = location.Trim().ToLower();
                query = query.Where(v => v.Location.ToLower().Contains(loc));
            }

            if (!string.IsNullOrWhiteSpace(employmentType))
            {
                var type = employmentType.Trim().ToLower();
                query = query.Where(v => v.EmploymentType.ToLower() == type);
            }

            if (companyId.HasValue)
            {
                query = query.Where(v => v.CompanyId == companyId.Value);
            }

            query = sortBy switch
            {
                "date_asc" => query.OrderBy(v => v.CreatedAt),
                "title_asc" => query.OrderBy(v => v.Title),
                "title_desc" => query.OrderByDescending(v => v.Title),
                _ => query.OrderByDescending(v => v.CreatedAt)
            };

            var totalCount = query.Count();
            var totalPages = (int)Math.Ceiling((double)totalCount / pageSize);

            var items = query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(v => new VacancyResponseDto
                {
                    Id = v.Id,
                    CompanyId = v.CompanyId,
                    CompanyName = v.Company != null ? v.Company.Name : "Independent",
                    Title = v.Title,
                    Description = v.Description,
                    Location = v.Location,
                    EmploymentType = v.EmploymentType,
                    IsActive = v.IsActive,
                    ApplicationDeadline = v.ApplicationDeadline,
                    CreatedAt = v.CreatedAt,
                    ApplicationCount = v.Applications.Count,
                    HasApplied = currentCandidateId != null && v.Applications.Any(a => a.CandidateId == currentCandidateId && a.Status != "WITHDRAWN"),
                    CurrentApplicationStatus = v.Applications.Where(a => a.CandidateId == currentCandidateId).Select(a => a.Status).FirstOrDefault(),
                    Skills = v.VacancySkills.Select(vs => new VacancySkillDto
                    {
                        SkillId = vs.SkillId,
                        SkillName = vs.Skill != null ? vs.Skill.Name : string.Empty,
                        Category = vs.Skill != null ? vs.Skill.Category : string.Empty,
                        IsMandatory = vs.IsMandatory
                    }).ToList(),
                    Requirements = v.VacancyRequirements.Select(vr => new VacancyRequirementDto
                    {
                        Id = vr.Id,
                        RequirementText = vr.RequirementText,
                        IsNonNegotiable = vr.IsNonNegotiable
                    }).ToList()
                })
                .ToList();

            return Ok(new PaginatedListDto<VacancyResponseDto>
            {
                Items = items,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = totalPages
            });
        }

        [HttpGet("{id:int}")]
        public IActionResult GetVacancy(int id)
        {
            var currentCandidateId = RecruitmentAccess.CandidateId(_db, User);
            var v = _db.Vacancies
                .Include(v => v.Company)
                .Include(v => v.VacancySkills).ThenInclude(vs => vs.Skill)
                .Include(v => v.VacancyRequirements)
                .Include(v => v.Applications)
                .FirstOrDefault(v => v.Id == id);

            if (v == null) return NotFound(new { message = "Vacancy not found." });

            var dto = new VacancyResponseDto
            {
                Id = v.Id,
                CompanyId = v.CompanyId,
                CompanyName = v.Company != null ? v.Company.Name : "Independent",
                Title = v.Title,
                Description = v.Description,
                Location = v.Location,
                EmploymentType = v.EmploymentType,
                IsActive = v.IsActive,
                ApplicationDeadline = v.ApplicationDeadline,
                CreatedAt = v.CreatedAt,
                ApplicationCount = v.Applications.Count,
                HasApplied = currentCandidateId != null && v.Applications.Any(a => a.CandidateId == currentCandidateId && a.Status != "WITHDRAWN"),
                CurrentApplicationStatus = v.Applications.Where(a => a.CandidateId == currentCandidateId).Select(a => a.Status).FirstOrDefault(),
                Skills = v.VacancySkills.Select(vs => new VacancySkillDto
                {
                    SkillId = vs.SkillId,
                    SkillName = vs.Skill != null ? vs.Skill.Name : string.Empty,
                    Category = vs.Skill != null ? vs.Skill.Category : string.Empty,
                    IsMandatory = vs.IsMandatory
                }).ToList(),
                Requirements = v.VacancyRequirements.Select(vr => new VacancyRequirementDto
                {
                    Id = vr.Id,
                    RequirementText = vr.RequirementText,
                    IsNonNegotiable = vr.IsNonNegotiable
                }).ToList()
            };

            return Ok(dto);
        }

        [HttpPost]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult CreateVacancy([FromBody] CreateVacancyDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var company = _db.Companies.Find(dto.CompanyId);
            if (company == null)
            {
                // Fallback to default company if provided company doesn't exist
                company = _db.Companies.FirstOrDefault();
                if (company == null)
                {
                    company = new Company
                    {
                        Name = "SkillBridge Partner Corp",
                        Industry = "Software Development",
                        Location = dto.Location,
                        Website = "https://skillbridge.dev"
                    };
                    _db.Companies.Add(company);
                    _db.SaveChanges();
                }
                dto.CompanyId = company.Id;
            }

            var vacancy = new Vacancy
            {
                CompanyId = dto.CompanyId,
                Title = dto.Title,
                Description = dto.Description,
                Location = string.IsNullOrWhiteSpace(dto.Location) ? "Colombo" : dto.Location,
                EmploymentType = string.IsNullOrWhiteSpace(dto.EmploymentType) ? "Internship" : dto.EmploymentType,
                IsActive = true,
                ApplicationDeadline = dto.ApplicationDeadline,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _db.Vacancies.Add(vacancy);
            _db.SaveChanges();

            // Handle Skills
            if (dto.Skills != null && dto.Skills.Any())
            {
                foreach (var skInput in dto.Skills)
                {
                    int skillId = skInput.SkillId;
                    if (skillId <= 0 && !string.IsNullOrWhiteSpace(skInput.SkillName))
                    {
                        var existingSkill = _db.Skills.FirstOrDefault(s => s.Name.ToLower() == skInput.SkillName.Trim().ToLower());
                        if (existingSkill != null)
                        {
                            skillId = existingSkill.Id;
                        }
                        else
                        {
                            var newSkill = new Skill { Name = skInput.SkillName.Trim(), Category = "Technical" };
                            _db.Skills.Add(newSkill);
                            _db.SaveChanges();
                            skillId = newSkill.Id;
                        }
                    }

                    if (skillId > 0)
                    {
                        _db.VacancySkills.Add(new VacancySkill
                        {
                            VacancyId = vacancy.Id,
                            SkillId = skillId,
                            IsMandatory = skInput.IsMandatory
                        });
                    }
                }
            }

            // Handle Requirements
            if (dto.Requirements != null && dto.Requirements.Any())
            {
                foreach (var reqInput in dto.Requirements)
                {
                    if (!string.IsNullOrWhiteSpace(reqInput.RequirementText))
                    {
                        _db.VacancyRequirements.Add(new VacancyRequirement
                        {
                            VacancyId = vacancy.Id,
                            RequirementText = reqInput.RequirementText.Trim(),
                            IsNonNegotiable = reqInput.IsNonNegotiable
                        });
                    }
                }
            }

            _db.SaveChanges();
            return CreatedAtAction(nameof(GetVacancy), new { id = vacancy.Id }, vacancy);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult UpdateVacancy(int id, [FromBody] UpdateVacancyDto dto)
        {
            var vacancy = _db.Vacancies
                .Include(v => v.VacancySkills)
                .Include(v => v.VacancyRequirements)
                .FirstOrDefault(v => v.Id == id);

            if (vacancy == null) return NotFound(new { message = "Vacancy not found." });

            vacancy.Title = dto.Title;
            vacancy.Description = dto.Description;
            vacancy.Location = dto.Location;
            vacancy.EmploymentType = dto.EmploymentType;
            vacancy.IsActive = dto.IsActive;
            vacancy.ApplicationDeadline = dto.ApplicationDeadline;
            vacancy.UpdatedAt = DateTime.UtcNow;

            // Update Vacancy Skills
            _db.VacancySkills.RemoveRange(vacancy.VacancySkills);
            if (dto.Skills != null)
            {
                foreach (var skInput in dto.Skills)
                {
                    int skillId = skInput.SkillId;
                    if (skillId <= 0 && !string.IsNullOrWhiteSpace(skInput.SkillName))
                    {
                        var existingSkill = _db.Skills.FirstOrDefault(s => s.Name.ToLower() == skInput.SkillName.Trim().ToLower());
                        if (existingSkill != null)
                        {
                            skillId = existingSkill.Id;
                        }
                        else
                        {
                            var newSkill = new Skill { Name = skInput.SkillName.Trim(), Category = "Technical" };
                            _db.Skills.Add(newSkill);
                            _db.SaveChanges();
                            skillId = newSkill.Id;
                        }
                    }

                    if (skillId > 0)
                    {
                        _db.VacancySkills.Add(new VacancySkill
                        {
                            VacancyId = vacancy.Id,
                            SkillId = skillId,
                            IsMandatory = skInput.IsMandatory
                        });
                    }
                }
            }

            // Update Vacancy Requirements
            _db.VacancyRequirements.RemoveRange(vacancy.VacancyRequirements);
            if (dto.Requirements != null)
            {
                foreach (var reqInput in dto.Requirements)
                {
                    if (!string.IsNullOrWhiteSpace(reqInput.RequirementText))
                    {
                        _db.VacancyRequirements.Add(new VacancyRequirement
                        {
                            VacancyId = vacancy.Id,
                            RequirementText = reqInput.RequirementText.Trim(),
                            IsNonNegotiable = reqInput.IsNonNegotiable
                        });
                    }
                }
            }

            _db.SaveChanges();
            return Ok(new { message = "Vacancy updated successfully.", id = vacancy.Id });
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult DeleteVacancy(int id)
        {
            var vacancy = _db.Vacancies.Find(id);
            if (vacancy == null) return NotFound(new { message = "Vacancy not found." });

            vacancy.IsActive = !vacancy.IsActive; // Toggle active status
            vacancy.UpdatedAt = DateTime.UtcNow;
            _db.SaveChanges();

            return Ok(new { message = $"Vacancy status toggled to {(vacancy.IsActive ? "Active" : "Inactive")}.", id = vacancy.Id, isActive = vacancy.IsActive });
        }

        // ==========================================
        // SAVED VACANCIES MANAGEMENT
        // ==========================================

        [HttpPost("{id}/save")]
        [Authorize(Roles = "Candidate")]
        public IActionResult SaveVacancy(int id)
        {
            var currentCandidateId = RecruitmentAccess.CandidateId(_db, User);
            if (currentCandidateId == null) return NotFound(new { message = "Candidate profile not found." });
            var candidateId = currentCandidateId.Value;
            var vacancy = _db.Vacancies.Find(id);
            if (vacancy == null) return NotFound(new { message = "Vacancy not found." });

            var existing = _db.SavedVacancies.FirstOrDefault(sv => sv.VacancyId == id && sv.CandidateId == candidateId);
            if (existing != null)
            {
                return Ok(new { message = "Vacancy is already saved.", savedVacancyId = existing.Id });
            }

            var saved = new SavedVacancy
            {
                VacancyId = id,
                CandidateId = candidateId,
                SavedAt = DateTime.UtcNow
            };

            _db.SavedVacancies.Add(saved);
            _db.SaveChanges();

            return Ok(new { message = "Vacancy saved successfully.", savedVacancyId = saved.Id });
        }

        [HttpDelete("{id}/save")]
        [Authorize(Roles = "Candidate")]
        public IActionResult UnsaveVacancy(int id)
        {
            var currentCandidateId = RecruitmentAccess.CandidateId(_db, User);
            if (currentCandidateId == null) return NotFound(new { message = "Candidate profile not found." });
            var candidateId = currentCandidateId.Value;
            var existing = _db.SavedVacancies.FirstOrDefault(sv => sv.VacancyId == id && sv.CandidateId == candidateId);
            if (existing == null)
            {
                return NotFound(new { message = "Saved vacancy record not found." });
            }

            _db.SavedVacancies.Remove(existing);
            _db.SaveChanges();

            return Ok(new { message = "Vacancy removed from saved items." });
        }

        [HttpGet("saved/me")]
        [Authorize(Roles = "Candidate")]
        public IActionResult GetMySavedVacancies()
        {
            var candidateId = RecruitmentAccess.CandidateId(_db, User);
            return candidateId == null ? Ok(Array.Empty<SavedVacancyDto>()) : GetSavedVacancies(candidateId.Value);
        }

        [HttpGet("saved/{candidateId:int}")]
        [Authorize(Roles = "Candidate,Recruiter,Administrator")]
        public IActionResult GetSavedVacancies(int candidateId)
        {
            if (!RecruitmentAccess.IsStaff(User) && RecruitmentAccess.CandidateId(_db, User) != candidateId) return NotFound();
            var savedItems = _db.SavedVacancies
                .Where(sv => sv.CandidateId == candidateId)
                .Join(_db.Vacancies.Include(v => v.Company),
                      sv => sv.VacancyId,
                      v => v.Id,
                      (sv, v) => new SavedVacancyDto
                      {
                          Id = sv.Id,
                          CandidateId = sv.CandidateId,
                          VacancyId = v.Id,
                          VacancyTitle = v.Title,
                          CompanyName = v.Company != null ? v.Company.Name : "Independent",
                          Location = v.Location,
                          EmploymentType = v.EmploymentType,
                          SavedAt = sv.SavedAt
                      })
                .OrderByDescending(sv => sv.SavedAt)
                .ToList();

            return Ok(savedItems);
        }

        // Apply endpoint retained for backward compatibility
        [HttpPost("{id}/apply")]
        [Authorize(Roles = "Candidate")]
        public IActionResult ApplyToVacancy(int id)
        {
            var currentCandidateId = RecruitmentAccess.CandidateId(_db, User);
            if (currentCandidateId == null) return NotFound(new { message = "Candidate profile not found." });
            var candidateId = currentCandidateId.Value;
            var vacancy = _db.Vacancies.Find(id);
            if (vacancy == null) return NotFound(new { message = "Vacancy not found." });

            if (!vacancy.IsActive) return BadRequest(new { message = "Vacancy is not active." });

            var existing = _db.Applications.FirstOrDefault(a => a.VacancyId == id && a.CandidateId == candidateId);
            if (existing != null)
            {
                return BadRequest(new { message = "You have already applied for this vacancy." });
            }

            // Component A Integration: Verify candidate profile completeness before allowing application
            var candidate = _db.Candidates.Find(candidateId);
            if (candidate == null) return NotFound(new { message = "Candidate profile not found." });

            if (!candidate.IsProfileComplete)
            {
                return BadRequest(new 
                { 
                    message = "Candidate profile is incomplete. Mandatory profile fields (Phone, City, Bio, Skills, Education, CV) must be completed before applying.",
                    candidateId = candidateId,
                    isProfileComplete = false
                });
            }

            var app = new Application
            {
                CandidateId = candidateId,
                VacancyId = id,
                Status = "SUBMITTED",
                AppliedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _db.Applications.Add(app);
            _db.SaveChanges();

            _db.ApplicationStatusHistories.Add(new ApplicationStatusHistory
            {
                ApplicationId = app.Id,
                Status = "SUBMITTED",
                Notes = "Application submitted by candidate via mobile/web.",
                ChangedAt = DateTime.UtcNow
            });
            _db.SaveChanges();

            return Ok(new { app.Id, app.CandidateId, app.VacancyId, app.Status, app.AppliedAt });
        }

        // NON-CRUD BUSINESS & AGENTIC AI INTEGRATION OPERATION:
        [HttpPost("/api/applications/{id}/evaluate-match")]
        [Authorize(Roles = "Candidate,Recruiter,Administrator")]
        public async Task<IActionResult> EvaluateApplicationMatch(int id)
        {
            var app = RecruitmentAccess.Applications(_db, User)
                .Include(a => a.Candidate).ThenInclude(c => c!.CandidateSkills).ThenInclude(cs => cs.Skill)
                .Include(a => a.Candidate).ThenInclude(c => c!.Educations)
                .Include(a => a.Candidate).ThenInclude(c => c!.Experiences)
                .Include(a => a.Vacancy).ThenInclude(v => v!.VacancyRequirements)
                .Include(a => a.Vacancy).ThenInclude(v => v!.VacancySkills).ThenInclude(vs => vs.Skill)
                .FirstOrDefault(a => a.Id == id);

            if (app == null) return NotFound(new { message = "Application not found." });

            if (app.Status != "SUBMITTED" && app.Status != "REVISION_REQUESTED")
                return BadRequest(new { message = "Application is not awaiting evaluation." });

            var aiServiceUrl = _config["AgenticAiService:BaseUrl"] ?? "http://localhost:8000";
            var client = _httpClientFactory.CreateClient();

            var payload = new
            {
                objective = $"Evaluate candidate application #{app.Id} for vacancy '{app.Vacancy?.Title}'",
                candidate_id = app.CandidateId,
                vacancy_id = app.VacancyId,
                profile_data = new
                {
                    candidate_id = app.CandidateId,
                    skills = app.Candidate!.CandidateSkills.Select(s => s.Skill!.Name).ToArray(),
                    education = app.Candidate.Educations.Select(e => new { institution = e.Institution, degree = e.Degree, field_of_study = e.FieldOfStudy }).ToArray(),
                    experience = app.Candidate.Experiences.Select(e => new { title = e.JobTitle, company = e.CompanyName, description = e.Description, duration_months = e.DurationMonths }).ToArray()
                },
                vacancy_data = new
                {
                    vacancy_id = app.VacancyId,
                    title = app.Vacancy!.Title,
                    description = app.Vacancy.Description,
                    required_skills = app.Vacancy.VacancySkills.Where(s => s.IsMandatory).Select(s => s.Skill!.Name).ToArray(),
                    preferred_skills = app.Vacancy.VacancySkills.Where(s => !s.IsMandatory).Select(s => s.Skill!.Name).ToArray(),
                    requirements = app.Vacancy.VacancyRequirements.Select(r => new { text = r.RequirementText, non_negotiable = r.IsNonNegotiable }).ToArray()
                }
            };

            var jsonContent = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

            try
            {
                var response = await client.PostAsync($"{aiServiceUrl}/api/ai/workflow/execute", jsonContent);

                if (response.IsSuccessStatusCode)
                {
                    var responseJson = await response.Content.ReadAsStringAsync();
                    using var doc = JsonDocument.Parse(responseJson);
                    var root = doc.RootElement;

                    if (!root.TryGetProperty("match_result", out var matchRes) ||
                        !matchRes.TryGetProperty("match_score", out var scoreEl) ||
                        scoreEl.ValueKind != JsonValueKind.Number ||
                        !scoreEl.TryGetDouble(out var matchScore) ||
                        !double.IsFinite(matchScore) || matchScore < 0 || matchScore > 100)
                        return StatusCode(502, new { message = "AI service returned an invalid match score." });

                    if (!root.TryGetProperty("requires_human_approval", out var requiresReview) || requiresReview.ValueKind != JsonValueKind.True ||
                        (root.TryGetProperty("status", out var aiStatus) && aiStatus.GetString() == "ERROR"))
                        return StatusCode(502, new { message = "AI workflow failed; no evaluation was saved." });

                    string status = "PENDING_RECRUITER_APPROVAL";

                    // Compare-and-set inside a transaction: a late AI response must not
                    // revive a withdrawn application or overwrite another evaluation.
                    await using var transaction = await _db.Database.BeginTransactionAsync();
                    var originalStatus = app.Status;
                    var claimed = await _db.Applications.Where(a => a.Id == app.Id && a.Status == originalStatus)
                        .ExecuteUpdateAsync(setters => setters.SetProperty(a => a.Status, status));
                    if (claimed != 1)
                        return Conflict(new { message = "Application changed while evaluation was running. Refresh to see its current state." });

                    app.MatchScore = matchScore;
                    app.EligibilityPassed = matchRes.TryGetProperty("eligibility_gate_passed", out var eligible) && eligible.ValueKind == JsonValueKind.True;
                    app.Status = status;
                    app.UpdatedAt = DateTime.UtcNow;

                    var workflow = new AIWorkflow
                    {
                        WorkflowId = root.TryGetProperty("workflow_id", out var wfEl) ? wfEl.GetString() ?? $"wf-{app.CandidateId}-{app.VacancyId}" : $"wf-{app.CandidateId}-{app.VacancyId}",
                        Objective = payload.objective,
                        ApplicationId = app.Id,
                        Status = status,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };

                    _db.AIWorkflows.Add(workflow);
                    _db.SaveChanges();

                    if (root.TryGetProperty("plan", out var planEl))
                    {
                        _db.AIWorkflowSteps.Add(new AIWorkflowStep
                        {
                            AIWorkflowId = workflow.Id,
                            AgentName = "Planning Agent",
                            StepName = "Plan Generation",
                            Status = "COMPLETED",
                            StructuredOutput = planEl.ToString()
                        });
                    }

                    _db.AIWorkflowSteps.Add(new AIWorkflowStep
                    {
                        AIWorkflowId = workflow.Id,
                        AgentName = "Job Matching Agent",
                        StepName = "Evidence-based match (advisory)",
                        Status = "COMPLETED",
                        StructuredOutput = matchRes.GetRawText()
                    });

                    _db.AIValidationResults.Add(new AIValidationResult
                    {
                        AIWorkflowId = workflow.Id,
                        ValidationType = "AllowedAttributeCheck",
                        IsValid = root.TryGetProperty("validation_result", out var validation) &&
                            validation.TryGetProperty("gate_results", out var gates) &&
                            gates.EnumerateArray().Any(g => g.GetProperty("gate").GetInt32() == 1 && g.GetProperty("passed").GetBoolean()),
                        CreatedAt = DateTime.UtcNow
                    });

                    _db.ApplicationStatusHistories.Add(new ApplicationStatusHistory
                    {
                        ApplicationId = app.Id,
                        Status = status,
                        Notes = $"Agentic AI evaluation complete. Match score: {matchScore}%. Paused for recruiter approval.",
                        ChangedAt = DateTime.UtcNow
                    });

                    _db.SaveChanges();

                    await transaction.CommitAsync();

                    return Ok(new
                    {
                        applicationId = app.Id,
                        status = status,
                        matchScore = matchScore,
                        aiWorkflowId = workflow.Id,
                        aiResponse = JsonSerializer.Deserialize<object>(responseJson)
                    });
                }
            }
            catch (HttpRequestException)
            {
                return StatusCode(503, new { message = "AI evaluation is unavailable. Please try again later." });
            }
            catch (TaskCanceledException)
            {
                return StatusCode(503, new { message = "AI evaluation timed out. Please try again later." });
            }
            catch (JsonException)
            {
                return StatusCode(502, new { message = "AI service returned an invalid response." });
            }

            return BadRequest(new { message = "Failed to communicate with Agentic AI service." });
        }
    }
}
