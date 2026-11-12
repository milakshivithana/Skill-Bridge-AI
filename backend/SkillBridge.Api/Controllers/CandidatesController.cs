using System;
using System.Linq;
using System.Net.Http;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using SkillBridge.Api.DTOs;
using SkillBridge.Api.Services;

namespace SkillBridge.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CandidatesController : ControllerBase
    {
        private readonly ICandidateService _candidateService;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _config;

        public CandidatesController(
            ICandidateService candidateService,
            IHttpClientFactory httpClientFactory,
            IConfiguration config)
        {
            _candidateService = candidateService;
            _httpClientFactory = httpClientFactory;
            _config = config;
        }

        private int? GetCurrentUserId()
        {
            var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return int.TryParse(claim, out var id) ? id : null;
        }

        private bool IsStaffOrAdmin()
        {
            return User.IsInRole("Recruiter") || User.IsInRole("Administrator");
        }

        private async Task<bool> CanAccessCandidateAsync(int candidateId)
        {
            if (IsStaffOrAdmin()) return true;
            var currentUserId = GetCurrentUserId();
            if (currentUserId == null) return false;
            return await _candidateService.VerifyCandidateOwnershipAsync(candidateId, currentUserId.Value);
        }

        // ==========================================
        // CANDIDATE PROFILE ENDPOINTS
        // ==========================================

        /// <summary>
        /// Get current authenticated candidate's profile.
        /// </summary>
        [HttpGet("me")]
        public async Task<IActionResult> GetMyProfile()
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized(new { message = "Invalid token." });

            var profile = await _candidateService.GetProfileByUserIdAsync(userId.Value);
            if (profile == null) return NotFound(new { message = "Candidate profile not found for this user." });

            return Ok(profile);
        }

        /// <summary>
        /// Get candidate profile by ID (Owner or Staff only).
        /// </summary>
        [HttpGet("{id}")]
        public async Task<IActionResult> GetCandidate(int id)
        {
            if (!await CanAccessCandidateAsync(id))
            {
                return Forbid();
            }

            var candidate = await _candidateService.GetProfileAsync(id);
            if (candidate == null) return NotFound(new { message = "Candidate not found." });

            return Ok(candidate);
        }

        /// <summary>
        /// Update candidate personal profile details (Owner or Admin only).
        /// </summary>
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateCandidate(int id, [FromBody] UpdateCandidateProfileDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            if (!await CanAccessCandidateAsync(id))
            {
                return Forbid();
            }

            var updated = await _candidateService.UpdateProfileAsync(id, dto);
            if (updated == null) return NotFound(new { message = "Candidate not found." });

            return Ok(updated);
        }

        /// <summary>
        /// Search and filter candidates with pagination (Recruiter or Admin only).
        /// </summary>
        [HttpGet]
        [Authorize(Roles = "Recruiter,Administrator")]
        public async Task<IActionResult> SearchCandidates(
            [FromQuery] string? query,
            [FromQuery] string? skill,
            [FromQuery] string? city,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var result = await _candidateService.SearchCandidatesAsync(query, skill, city, page, pageSize);
            return Ok(result);
        }

        // ==========================================
        // CANDIDATE SKILLS ENDPOINTS
        // ==========================================

        /// <summary>
        /// Get skills for a candidate.
        /// </summary>
        [HttpGet("{id}/skills")]
        public async Task<IActionResult> GetSkills(int id)
        {
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var skills = await _candidateService.GetSkillsAsync(id);
            return Ok(skills);
        }

        /// <summary>
        /// Add a skill to the candidate profile (prevents duplicates).
        /// </summary>
        [HttpPost("{id}/skills")]
        public async Task<IActionResult> AddSkill(int id, [FromBody] AddCandidateSkillDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var skill = await _candidateService.AddSkillAsync(id, dto);
            if (skill == null) return BadRequest(new { message = "Failed to add skill. Ensure candidate and skill exist." });

            return Ok(skill);
        }

        /// <summary>
        /// Remove a skill from candidate profile.
        /// </summary>
        [HttpDelete("{id}/skills/{skillId}")]
        public async Task<IActionResult> RemoveSkill(int id, int skillId)
        {
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var removed = await _candidateService.RemoveSkillAsync(id, skillId);
            if (!removed) return NotFound(new { message = "Skill not found on candidate profile." });

            return Ok(new { message = "Skill removed successfully." });
        }

        // ==========================================
        // EDUCATION CRUD ENDPOINTS
        // ==========================================

        /// <summary>
        /// List education records for candidate.
        /// </summary>
        [HttpGet("{id}/education")]
        public async Task<IActionResult> GetEducations(int id)
        {
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var educations = await _candidateService.GetEducationsAsync(id);
            return Ok(educations);
        }

        /// <summary>
        /// Add an education record.
        /// </summary>
        [HttpPost("{id}/education")]
        public async Task<IActionResult> AddEducation(int id, [FromBody] CreateEducationDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var created = await _candidateService.AddEducationAsync(id, dto);
            return CreatedAtAction(nameof(GetEducations), new { id }, created);
        }

        /// <summary>
        /// Update an education record.
        /// </summary>
        [HttpPut("{id}/education/{educationId}")]
        public async Task<IActionResult> UpdateEducation(int id, int educationId, [FromBody] UpdateEducationDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var updated = await _candidateService.UpdateEducationAsync(id, educationId, dto);
            if (updated == null) return NotFound(new { message = "Education record not found." });

            return Ok(updated);
        }

        /// <summary>
        /// Delete an education record.
        /// </summary>
        [HttpDelete("{id}/education/{educationId}")]
        public async Task<IActionResult> DeleteEducation(int id, int educationId)
        {
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var deleted = await _candidateService.DeleteEducationAsync(id, educationId);
            if (!deleted) return NotFound(new { message = "Education record not found." });

            return Ok(new { message = "Education record deleted." });
        }

        // ==========================================
        // EXPERIENCE CRUD ENDPOINTS
        // ==========================================

        /// <summary>
        /// List experience records for candidate.
        /// </summary>
        [HttpGet("{id}/experience")]
        public async Task<IActionResult> GetExperiences(int id)
        {
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var experiences = await _candidateService.GetExperiencesAsync(id);
            return Ok(experiences);
        }

        /// <summary>
        /// Add experience record.
        /// </summary>
        [HttpPost("{id}/experience")]
        public async Task<IActionResult> AddExperience(int id, [FromBody] CreateExperienceDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var created = await _candidateService.AddExperienceAsync(id, dto);
            return CreatedAtAction(nameof(GetExperiences), new { id }, created);
        }

        /// <summary>
        /// Update experience record.
        /// </summary>
        [HttpPut("{id}/experience/{experienceId}")]
        public async Task<IActionResult> UpdateExperience(int id, int experienceId, [FromBody] UpdateExperienceDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var updated = await _candidateService.UpdateExperienceAsync(id, experienceId, dto);
            if (updated == null) return NotFound(new { message = "Experience record not found." });

            return Ok(updated);
        }

        /// <summary>
        /// Delete experience record.
        /// </summary>
        [HttpDelete("{id}/experience/{experienceId}")]
        public async Task<IActionResult> DeleteExperience(int id, int experienceId)
        {
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var deleted = await _candidateService.DeleteExperienceAsync(id, experienceId);
            if (!deleted) return NotFound(new { message = "Experience record not found." });

            return Ok(new { message = "Experience record deleted." });
        }

        // ==========================================
        // PREFERENCES ENDPOINTS
        // ==========================================

        /// <summary>
        /// Get candidate career preferences.
        /// </summary>
        [HttpGet("{id}/preferences")]
        public async Task<IActionResult> GetPreferences(int id)
        {
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var pref = await _candidateService.GetPreferencesAsync(id);
            if (pref == null) return Ok(new CandidatePreferenceDto { CandidateId = id });

            return Ok(pref);
        }

        /// <summary>
        /// Update candidate career preferences.
        /// </summary>
        [HttpPut("{id}/preferences")]
        public async Task<IActionResult> UpdatePreferences(int id, [FromBody] UpdateCandidatePreferenceDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var updated = await _candidateService.UpdatePreferencesAsync(id, dto);
            return Ok(updated);
        }

        // ==========================================
        // CV UPLOAD & DOCUMENT MANAGEMENT
        // ==========================================

        /// <summary>
        /// Upload CV document (PDF, DOC, DOCX up to 5MB).
        /// </summary>
        [HttpPost("{id}/cv")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadCV(int id, IFormFile file)
        {
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            try
            {
                var doc = await _candidateService.UploadCVAsync(id, file);
                return Ok(doc);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new { message = "File upload failed: " + ex.Message });
            }
        }

        /// <summary>
        /// Get latest uploaded CV metadata.
        /// </summary>
        [HttpGet("{id}/cv")]
        public async Task<IActionResult> GetLatestCV(int id)
        {
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var cv = await _candidateService.GetLatestCVAsync(id);
            if (cv == null) return NotFound(new { message = "No CV document found." });

            return Ok(cv);
        }

        /// <summary>
        /// Backward compatibility for JSON document upload.
        /// </summary>
        [HttpPost("{id}/documents")]
        public async Task<IActionResult> UploadDocumentLegacy(int id, [FromBody] Models.CVDocument doc)
        {
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            doc.CandidateId = id;
            doc.UploadedAt = DateTime.UtcNow;
            return Ok(doc);
        }

        // ==========================================
        // CERTIFICATE ENDPOINTS
        // ==========================================

        /// <summary>
        /// List candidate certificates.
        /// </summary>
        [HttpGet("{id}/certificates")]
        public async Task<IActionResult> GetCertificates(int id)
        {
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var certs = await _candidateService.GetCertificatesAsync(id);
            return Ok(certs);
        }

        /// <summary>
        /// Add a certificate.
        /// </summary>
        [HttpPost("{id}/certificates")]
        public async Task<IActionResult> AddCertificate(int id, [FromBody] CreateCertificateDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var cert = await _candidateService.AddCertificateAsync(id, dto);
            return Ok(cert);
        }

        /// <summary>
        /// Delete a certificate.
        /// </summary>
        [HttpDelete("{id}/certificates/{certificateId}")]
        public async Task<IActionResult> DeleteCertificate(int id, int certificateId)
        {
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var deleted = await _candidateService.DeleteCertificateAsync(id, certificateId);
            if (!deleted) return NotFound(new { message = "Certificate not found." });

            return Ok(new { message = "Certificate deleted." });
        }

        // ==========================================
        // PROFILE COMPLETENESS (DETERMINISTIC BUSINESS LOGIC)
        // ==========================================

        /// <summary>
        /// Deterministically evaluate profile completeness score and missing required fields.
        /// </summary>
        [HttpGet("{id}/completeness")]
        public async Task<IActionResult> GetProfileCompleteness(int id)
        {
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var completeness = await _candidateService.CalculateProfileCompletenessAsync(id);
            return Ok(completeness);
        }

        /// <summary>
        /// Analyzes candidate profile by orchestrating with the internal Python Agentic AI microservice
        /// (Candidate Profile Analysis Agent - Role 2) and deterministic completeness rules.
        /// </summary>
        [HttpPost("{id}/analyze-profile")]
        public async Task<IActionResult> AnalyzeProfile(int id)
        {
            if (!await CanAccessCandidateAsync(id)) return Forbid();

            var completeness = await _candidateService.CalculateProfileCompletenessAsync(id);
            var profile = await _candidateService.GetProfileAsync(id);

            object? aiSummary = null;
            string aiServiceStatus = "UNAVAILABLE";

            try
            {
                var aiServiceUrl = _config["AgenticAiService:BaseUrl"] ?? "http://localhost:8000";
                var client = _httpClientFactory.CreateClient();
                client.Timeout = TimeSpan.FromSeconds(5);

                var payload = new
                {
                    candidate_id = id,
                    profile_data = profile != null ? new
                    {
                        fullName = profile.FullName,
                        city = profile.City,
                        bio = profile.Bio,
                        skills = profile.Skills?.Select(s => new { skillName = s.SkillName, proficiency = s.ProficiencyLevel }).ToList(),
                        educations = profile.Educations?.Select(e => new { degree = e.Degree, institution = e.Institution, fieldOfStudy = e.FieldOfStudy, startYear = e.StartYear, endYear = e.EndYear }).ToList(),
                        experiences = profile.Experiences?.Select(e => new { company = e.CompanyName, title = e.JobTitle, durationMonths = e.DurationMonths, description = e.Description }).ToList(),
                        locationPreference = profile.Preference?.PreferredLocation,
                        cvDocuments = profile.CVDocuments?.Select(c => new { fileName = c.FileName }).ToList()
                    } : null
                };

                var jsonContent = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");
                var response = await client.PostAsync($"{aiServiceUrl}/api/ai/candidate/analyze", jsonContent);

                if (response.IsSuccessStatusCode)
                {
                    var responseJson = await response.Content.ReadAsStringAsync();
                    aiSummary = JsonSerializer.Deserialize<object>(responseJson);
                    aiServiceStatus = "CONNECTED";
                }
                else
                {
                    aiServiceStatus = $"ERROR_{response.StatusCode}";
                }
            }
            catch (Exception)
            {
                // Fallback gracefully: if AI service is offline, return deterministic response without failing
                aiServiceStatus = "OFFLINE_FALLBACK";
            }

            return Ok(new
            {
                candidateId = id,
                isEligibleToApply = completeness.IsComplete,
                missingFields = completeness.MissingFields,
                profileScorePercentage = completeness.CompletionPercentage,
                aiStatus = aiServiceStatus,
                aiAnalysis = aiSummary
            });
        }
    }
}
