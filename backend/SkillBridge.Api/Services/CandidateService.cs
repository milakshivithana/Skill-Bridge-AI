using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SkillBridge.Api.Data;
using SkillBridge.Api.DTOs;
using SkillBridge.Api.Models;

namespace SkillBridge.Api.Services
{
    public class CandidateService : ICandidateService
    {
        private readonly ApplicationDbContext _db;
        private readonly IWebHostEnvironment _env;
        private readonly ILogger<CandidateService> _logger;
        private readonly IProfileCompletenessEvaluator _evaluator;

        private static readonly string[] AllowedCvExtensions = { ".pdf", ".doc", ".docx" };
        private const long MaxCvFileSizeBytes = 5 * 1024 * 1024; // 5 MB

        public CandidateService(
            ApplicationDbContext db, 
            IWebHostEnvironment env, 
            ILogger<CandidateService> logger,
            IProfileCompletenessEvaluator evaluator)
        {
            _db = db;
            _env = env;
            _logger = logger;
            _evaluator = evaluator;
        }

        // ==========================================
        // PROFILE CRUD
        // ==========================================

        public async Task<CandidateProfileDto?> GetProfileAsync(int candidateId)
        {
            var candidate = await _db.Candidates
                .Include(c => c.User)
                .Include(c => c.CandidateSkills).ThenInclude(cs => cs.Skill)
                .Include(c => c.Educations)
                .Include(c => c.Experiences)
                .Include(c => c.Certificates)
                .Include(c => c.CVDocuments)
                .Include(c => c.Preference)
                .FirstOrDefaultAsync(c => c.Id == candidateId);

            return candidate == null ? null : MapToProfileDto(candidate);
        }

        public async Task<CandidateProfileDto?> GetProfileByUserIdAsync(int userId)
        {
            var candidate = await _db.Candidates
                .Include(c => c.User)
                .Include(c => c.CandidateSkills).ThenInclude(cs => cs.Skill)
                .Include(c => c.Educations)
                .Include(c => c.Experiences)
                .Include(c => c.Certificates)
                .Include(c => c.CVDocuments)
                .Include(c => c.Preference)
                .FirstOrDefaultAsync(c => c.UserId == userId);

            return candidate == null ? null : MapToProfileDto(candidate);
        }

        public async Task<CandidateProfileDto?> UpdateProfileAsync(int candidateId, UpdateCandidateProfileDto dto)
        {
            var candidate = await _db.Candidates
                .Include(c => c.User)
                .Include(c => c.CandidateSkills).ThenInclude(cs => cs.Skill)
                .Include(c => c.Educations)
                .Include(c => c.Experiences)
                .Include(c => c.Certificates)
                .Include(c => c.CVDocuments)
                .Include(c => c.Preference)
                .FirstOrDefaultAsync(c => c.Id == candidateId);

            if (candidate == null) return null;

            candidate.Phone = dto.Phone?.Trim() ?? string.Empty;
            candidate.City = dto.City?.Trim() ?? string.Empty;
            candidate.Bio = dto.Bio?.Trim() ?? string.Empty;
            candidate.LinkedInUrl = dto.LinkedInUrl?.Trim();
            candidate.PortfolioUrl = dto.PortfolioUrl?.Trim();
            candidate.UpdatedAt = DateTime.UtcNow;

            // Re-evaluate profile completeness
            var completeness = EvaluateCompleteness(candidate);
            candidate.IsProfileComplete = completeness.IsComplete;

            await _db.SaveChangesAsync();
            return MapToProfileDto(candidate);
        }

        public async Task<PagedResultDto<CandidateSummaryDto>> SearchCandidatesAsync(string? query, string? skill, string? city, int page, int pageSize)
        {
            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 10;
            if (pageSize > 100) pageSize = 100;

            var baseQuery = _db.Candidates
                .Include(c => c.User)
                .Include(c => c.CandidateSkills).ThenInclude(cs => cs.Skill)
                .Include(c => c.Educations)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(query))
            {
                var q = query.Trim().ToLower();
                baseQuery = baseQuery.Where(c =>
                    (c.User != null && c.User.FullName.ToLower().Contains(q)) ||
                    (c.User != null && c.User.Email.ToLower().Contains(q)) ||
                    c.Bio.ToLower().Contains(q));
            }

            if (!string.IsNullOrWhiteSpace(city))
            {
                var cCity = city.Trim().ToLower();
                baseQuery = baseQuery.Where(c => c.City.ToLower().Contains(cCity));
            }

            if (!string.IsNullOrWhiteSpace(skill))
            {
                var sSkill = skill.Trim().ToLower();
                baseQuery = baseQuery.Where(c => c.CandidateSkills.Any(cs => cs.Skill != null && cs.Skill.Name.ToLower().Contains(sSkill)));
            }

            var totalCount = await baseQuery.CountAsync();

            var items = await baseQuery
                .OrderByDescending(c => c.UpdatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(c => new CandidateSummaryDto
                {
                    Id = c.Id,
                    UserId = c.UserId,
                    FullName = c.User != null ? c.User.FullName : "Unknown",
                    Email = c.User != null ? c.User.Email : string.Empty,
                    Phone = c.Phone,
                    City = c.City,
                    IsProfileComplete = c.IsProfileComplete,
                    Skills = c.CandidateSkills.Where(cs => cs.Skill != null).Select(cs => cs.Skill!.Name).ToList(),
                    LatestQualification = c.Educations.OrderByDescending(e => e.EndYear).Select(e => e.Degree).FirstOrDefault(),
                    LatestInstitution = c.Educations.OrderByDescending(e => e.EndYear).Select(e => e.Institution).FirstOrDefault()
                })
                .ToListAsync();

            return new PagedResultDto<CandidateSummaryDto>
            {
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                Items = items
            };
        }

        // ==========================================
        // SKILLS MANAGEMENT
        // ==========================================

        public async Task<List<CandidateSkillDto>> GetSkillsAsync(int candidateId)
        {
            return await _db.CandidateSkills
                .Where(cs => cs.CandidateId == candidateId)
                .Include(cs => cs.Skill)
                .OrderByDescending(cs => cs.CreatedAt)
                .Select(cs => new CandidateSkillDto
                {
                    Id = cs.Id,
                    SkillId = cs.SkillId,
                    SkillName = cs.Skill != null ? cs.Skill.Name : string.Empty,
                    Category = cs.Skill != null ? cs.Skill.Category : string.Empty,
                    ProficiencyLevel = cs.ProficiencyLevel,
                    CreatedAt = cs.CreatedAt
                })
                .ToListAsync();
        }

        public async Task<CandidateSkillDto?> AddSkillAsync(int candidateId, AddCandidateSkillDto dto)
        {
            var candidateExists = await _db.Candidates.AnyAsync(c => c.Id == candidateId);
            if (!candidateExists) return null;

            Skill? skill;

            if (dto.SkillId.HasValue)
            {
                // Path A: existing taxonomy skill selected by ID
                skill = await _db.Skills.FindAsync(dto.SkillId.Value);
                if (skill == null) return null;
            }
            else
            {
                // Path B: candidate-created custom skill — resolve by name (case-insensitive, whitespace-normalized)
                var rawName = dto.SkillName?.Trim() ?? string.Empty;
                if (string.IsNullOrWhiteSpace(rawName)) return null; // reject empty names

                var normalizedName = rawName.Trim();
                skill = await _db.Skills
                    .FirstOrDefaultAsync(s => s.Name.ToLower() == normalizedName.ToLower());

                if (skill == null)
                {
                    // Create the new skill in the global taxonomy
                    var category = string.IsNullOrWhiteSpace(dto.Category) ? "General" : dto.Category.Trim();
                    skill = new Skill
                    {
                        Name = normalizedName,
                        Category = category
                    };
                    _db.Skills.Add(skill);
                    await _db.SaveChangesAsync(); // get the new Id
                }
            }

            // Prevent the same candidate attaching the same skill twice
            var existing = await _db.CandidateSkills
                .FirstOrDefaultAsync(cs => cs.CandidateId == candidateId && cs.SkillId == skill.Id);

            if (existing != null)
            {
                // Update proficiency level if already present
                existing.ProficiencyLevel = dto.ProficiencyLevel;
                await _db.SaveChangesAsync();
                return new CandidateSkillDto
                {
                    Id = existing.Id,
                    SkillId = skill.Id,
                    SkillName = skill.Name,
                    Category = skill.Category,
                    ProficiencyLevel = existing.ProficiencyLevel,
                    CreatedAt = existing.CreatedAt
                };
            }

            var candidateSkill = new CandidateSkill
            {
                CandidateId = candidateId,
                SkillId = skill.Id,
                ProficiencyLevel = dto.ProficiencyLevel,
                CreatedAt = DateTime.UtcNow
            };

            _db.CandidateSkills.Add(candidateSkill);
            await _db.SaveChangesAsync();

            // Refresh candidate completeness
            await RefreshProfileCompletenessAsync(candidateId);

            return new CandidateSkillDto
            {
                Id = candidateSkill.Id,
                SkillId = skill.Id,
                SkillName = skill.Name,
                Category = skill.Category,
                ProficiencyLevel = candidateSkill.ProficiencyLevel,
                CreatedAt = candidateSkill.CreatedAt
            };
        }

        public async Task<bool> RemoveSkillAsync(int candidateId, int skillId)
        {
            var item = await _db.CandidateSkills
                .FirstOrDefaultAsync(cs => cs.CandidateId == candidateId && (cs.SkillId == skillId || cs.Id == skillId));

            if (item == null) return false;

            _db.CandidateSkills.Remove(item);
            await _db.SaveChangesAsync();

            await RefreshProfileCompletenessAsync(candidateId);
            return true;
        }

        public async Task<List<SkillDto>> GetAllTaxonomySkillsAsync()
        {
            return await _db.Skills
                .OrderBy(s => s.Category)
                .ThenBy(s => s.Name)
                .Select(s => new SkillDto
                {
                    Id = s.Id,
                    Name = s.Name,
                    Category = s.Category
                })
                .ToListAsync();
        }

        public async Task<SkillDto> CreateTaxonomySkillAsync(CreateSkillDto dto)
        {
            var normalizedName = dto.Name.Trim();
            var existing = await _db.Skills.FirstOrDefaultAsync(s => s.Name.ToLower() == normalizedName.ToLower());
            if (existing != null)
            {
                return new SkillDto { Id = existing.Id, Name = existing.Name, Category = existing.Category };
            }

            var skill = new Skill
            {
                Name = normalizedName,
                Category = string.IsNullOrWhiteSpace(dto.Category) ? "General" : dto.Category.Trim()
            };

            _db.Skills.Add(skill);
            await _db.SaveChangesAsync();

            return new SkillDto { Id = skill.Id, Name = skill.Name, Category = skill.Category };
        }

        // ==========================================
        // EDUCATION MANAGEMENT
        // ==========================================

        public async Task<List<EducationDto>> GetEducationsAsync(int candidateId)
        {
            return await _db.Educations
                .Where(e => e.CandidateId == candidateId)
                .OrderByDescending(e => e.EndYear)
                .Select(e => MapToEducationDto(e))
                .ToListAsync();
        }

        public async Task<EducationDto?> GetEducationByIdAsync(int candidateId, int educationId)
        {
            var edu = await _db.Educations.FirstOrDefaultAsync(e => e.Id == educationId && e.CandidateId == candidateId);
            return edu == null ? null : MapToEducationDto(edu);
        }

        public async Task<EducationDto> AddEducationAsync(int candidateId, CreateEducationDto dto)
        {
            var education = new Education
            {
                CandidateId = candidateId,
                Institution = dto.Institution.Trim(),
                Degree = dto.Degree.Trim(),
                FieldOfStudy = dto.FieldOfStudy?.Trim() ?? string.Empty,
                StartYear = dto.StartYear,
                EndYear = dto.EndYear,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _db.Educations.Add(education);
            await _db.SaveChangesAsync();

            await RefreshProfileCompletenessAsync(candidateId);
            return MapToEducationDto(education);
        }

        public async Task<EducationDto?> UpdateEducationAsync(int candidateId, int educationId, UpdateEducationDto dto)
        {
            var edu = await _db.Educations.FirstOrDefaultAsync(e => e.Id == educationId && e.CandidateId == candidateId);
            if (edu == null) return null;

            edu.Institution = dto.Institution.Trim();
            edu.Degree = dto.Degree.Trim();
            edu.FieldOfStudy = dto.FieldOfStudy?.Trim() ?? string.Empty;
            edu.StartYear = dto.StartYear;
            edu.EndYear = dto.EndYear;
            edu.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();
            await RefreshProfileCompletenessAsync(candidateId);
            return MapToEducationDto(edu);
        }

        public async Task<bool> DeleteEducationAsync(int candidateId, int educationId)
        {
            var edu = await _db.Educations.FirstOrDefaultAsync(e => e.Id == educationId && e.CandidateId == candidateId);
            if (edu == null) return false;

            _db.Educations.Remove(edu);
            await _db.SaveChangesAsync();

            await RefreshProfileCompletenessAsync(candidateId);
            return true;
        }

        // ==========================================
        // EXPERIENCE MANAGEMENT
        // ==========================================

        public async Task<List<ExperienceDto>> GetExperiencesAsync(int candidateId)
        {
            return await _db.Experiences
                .Where(exp => exp.CandidateId == candidateId)
                .OrderByDescending(exp => exp.CreatedAt)
                .Select(exp => MapToExperienceDto(exp))
                .ToListAsync();
        }

        public async Task<ExperienceDto?> GetExperienceByIdAsync(int candidateId, int experienceId)
        {
            var exp = await _db.Experiences.FirstOrDefaultAsync(e => e.Id == experienceId && e.CandidateId == candidateId);
            return exp == null ? null : MapToExperienceDto(exp);
        }

        public async Task<ExperienceDto> AddExperienceAsync(int candidateId, CreateExperienceDto dto)
        {
            var experience = new Experience
            {
                CandidateId = candidateId,
                CompanyName = dto.CompanyName.Trim(),
                JobTitle = dto.JobTitle.Trim(),
                Description = dto.Description?.Trim() ?? string.Empty,
                DurationMonths = dto.DurationMonths,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _db.Experiences.Add(experience);
            await _db.SaveChangesAsync();

            return MapToExperienceDto(experience);
        }

        public async Task<ExperienceDto?> UpdateExperienceAsync(int candidateId, int experienceId, UpdateExperienceDto dto)
        {
            var exp = await _db.Experiences.FirstOrDefaultAsync(e => e.Id == experienceId && e.CandidateId == candidateId);
            if (exp == null) return null;

            exp.CompanyName = dto.CompanyName.Trim();
            exp.JobTitle = dto.JobTitle.Trim();
            exp.Description = dto.Description?.Trim() ?? string.Empty;
            exp.DurationMonths = dto.DurationMonths;
            exp.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();
            return MapToExperienceDto(exp);
        }

        public async Task<bool> DeleteExperienceAsync(int candidateId, int experienceId)
        {
            var exp = await _db.Experiences.FirstOrDefaultAsync(e => e.Id == experienceId && e.CandidateId == candidateId);
            if (exp == null) return false;

            _db.Experiences.Remove(exp);
            await _db.SaveChangesAsync();

            return true;
        }

        // ==========================================
        // PREFERENCES MANAGEMENT
        // ==========================================

        public async Task<CandidatePreferenceDto?> GetPreferencesAsync(int candidateId)
        {
            var pref = await _db.CandidatePreferences.FirstOrDefaultAsync(p => p.CandidateId == candidateId);
            return pref == null ? null : MapToPreferenceDto(pref);
        }

        public async Task<CandidatePreferenceDto> UpdatePreferencesAsync(int candidateId, UpdateCandidatePreferenceDto dto)
        {
            var pref = await _db.CandidatePreferences.FirstOrDefaultAsync(p => p.CandidateId == candidateId);
            if (pref == null)
            {
                pref = new CandidatePreference
                {
                    CandidateId = candidateId,
                    PreferredLocation = dto.PreferredLocation?.Trim() ?? "Colombo",
                    PreferredWorkType = dto.PreferredWorkType ?? "FullTime",
                    ExpectedStipend = dto.ExpectedStipend,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                _db.CandidatePreferences.Add(pref);
            }
            else
            {
                pref.PreferredLocation = dto.PreferredLocation?.Trim() ?? pref.PreferredLocation;
                pref.PreferredWorkType = dto.PreferredWorkType ?? pref.PreferredWorkType;
                pref.ExpectedStipend = dto.ExpectedStipend;
                pref.UpdatedAt = DateTime.UtcNow;
            }

            await _db.SaveChangesAsync();
            return MapToPreferenceDto(pref);
        }

        // ==========================================
        // CV UPLOAD & DOCUMENT MANAGEMENT
        // ==========================================

        public async Task<CVDocumentDto> UploadCVAsync(int candidateId, IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                throw new ArgumentException("No file was uploaded.");
            }

            if (file.Length > MaxCvFileSizeBytes)
            {
                throw new ArgumentException($"File size exceeds maximum allowed limit of {MaxCvFileSizeBytes / (1024 * 1024)} MB.");
            }

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!AllowedCvExtensions.Contains(extension))
            {
                throw new ArgumentException("Invalid file format. Only .pdf, .doc, and .docx are permitted.");
            }

            // Create storage directory under uploads/cvs
            var uploadsDir = Path.Combine(_env.ContentRootPath, "uploads", "cvs");
            if (!Directory.Exists(uploadsDir))
            {
                Directory.CreateDirectory(uploadsDir);
            }

            var safeUniqueFileName = $"cv_{candidateId}_{Guid.NewGuid():N}{extension}";
            var physicalPath = Path.Combine(uploadsDir, safeUniqueFileName);

            using (var stream = new FileStream(physicalPath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var cvDocument = new CVDocument
            {
                CandidateId = candidateId,
                FileName = Path.GetFileName(file.FileName),
                FilePath = safeUniqueFileName,
                FileSizeBytes = file.Length,
                ContentType = file.ContentType ?? "application/octet-stream",
                UploadedAt = DateTime.UtcNow
            };

            _db.CVDocuments.Add(cvDocument);
            await _db.SaveChangesAsync();

            await RefreshProfileCompletenessAsync(candidateId);

            return new CVDocumentDto
            {
                Id = cvDocument.Id,
                CandidateId = cvDocument.CandidateId,
                FileName = cvDocument.FileName,
                FilePath = cvDocument.FilePath,
                FileSizeBytes = cvDocument.FileSizeBytes,
                ContentType = cvDocument.ContentType,
                UploadedAt = cvDocument.UploadedAt
            };
        }

        public async Task<CVDocumentDto?> GetLatestCVAsync(int candidateId)
        {
            var cv = await _db.CVDocuments
                .Where(d => d.CandidateId == candidateId)
                .OrderByDescending(d => d.UploadedAt)
                .FirstOrDefaultAsync();

            return cv == null ? null : new CVDocumentDto
            {
                Id = cv.Id,
                CandidateId = cv.CandidateId,
                FileName = cv.FileName,
                FilePath = cv.FilePath,
                FileSizeBytes = cv.FileSizeBytes,
                ContentType = cv.ContentType,
                UploadedAt = cv.UploadedAt
            };
        }

        public async Task<CVDocumentDto?> GetCVByIdAsync(int candidateId, int cvId)
        {
            var cv = await _db.CVDocuments
                .FirstOrDefaultAsync(d => d.Id == cvId && d.CandidateId == candidateId);

            return cv == null ? null : new CVDocumentDto
            {
                Id = cv.Id,
                CandidateId = cv.CandidateId,
                FileName = cv.FileName,
                FilePath = cv.FilePath,
                FileSizeBytes = cv.FileSizeBytes,
                ContentType = cv.ContentType,
                UploadedAt = cv.UploadedAt
            };
        }

        // ==========================================
        // CERTIFICATE MANAGEMENT
        // ==========================================

        public async Task<List<CertificateDto>> GetCertificatesAsync(int candidateId)
        {
            return await _db.Certificates
                .Where(c => c.CandidateId == candidateId)
                .OrderByDescending(c => c.IssueDate)
                .Select(c => new CertificateDto
                {
                    Id = c.Id,
                    CandidateId = c.CandidateId,
                    Title = c.Title,
                    IssuingOrganization = c.IssuingOrganization,
                    IssueDate = c.IssueDate,
                    CertificateUrl = c.CertificateUrl,
                    CreatedAt = c.CreatedAt,
                    UpdatedAt = c.UpdatedAt
                })
                .ToListAsync();
        }

        public async Task<CertificateDto> AddCertificateAsync(int candidateId, CreateCertificateDto dto)
        {
            var cert = new Certificate
            {
                CandidateId = candidateId,
                Title = dto.Title.Trim(),
                IssuingOrganization = dto.IssuingOrganization?.Trim() ?? string.Empty,
                IssueDate = dto.IssueDate,
                CertificateUrl = dto.CertificateUrl?.Trim() ?? string.Empty,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _db.Certificates.Add(cert);
            await _db.SaveChangesAsync();

            return new CertificateDto
            {
                Id = cert.Id,
                CandidateId = cert.CandidateId,
                Title = cert.Title,
                IssuingOrganization = cert.IssuingOrganization,
                IssueDate = cert.IssueDate,
                CertificateUrl = cert.CertificateUrl,
                CreatedAt = cert.CreatedAt,
                UpdatedAt = cert.UpdatedAt
            };
        }

        public async Task<bool> DeleteCertificateAsync(int candidateId, int certificateId)
        {
            var cert = await _db.Certificates.FirstOrDefaultAsync(c => c.Id == certificateId && c.CandidateId == candidateId);
            if (cert == null) return false;

            _db.Certificates.Remove(cert);
            await _db.SaveChangesAsync();
            return true;
        }

        // ==========================================
        // SECURITY & OWNERSHIP
        // ==========================================

        public async Task<bool> VerifyCandidateOwnershipAsync(int candidateId, int userId)
        {
            return await _db.Candidates.AnyAsync(c => c.Id == candidateId && c.UserId == userId);
        }

        // ==========================================
        // PROFILE COMPLETENESS BUSINESS LOGIC
        // ==========================================

        public async Task<ProfileCompletenessDto> CalculateProfileCompletenessAsync(int candidateId)
        {
            var candidate = await _db.Candidates
                .Include(c => c.CandidateSkills)
                .Include(c => c.Educations)
                .Include(c => c.CVDocuments)
                .FirstOrDefaultAsync(c => c.Id == candidateId);

            if (candidate == null)
            {
                return new ProfileCompletenessDto
                {
                    CandidateId = candidateId,
                    IsComplete = false,
                    CompletionPercentage = 0,
                    MissingFields = new List<string> { "Candidate record not found" }
                };
            }

            return EvaluateCompleteness(candidate);
        }

        private async Task RefreshProfileCompletenessAsync(int candidateId)
        {
            var candidate = await _db.Candidates
                .Include(c => c.CandidateSkills)
                .Include(c => c.Educations)
                .Include(c => c.CVDocuments)
                .FirstOrDefaultAsync(c => c.Id == candidateId);

            if (candidate != null)
            {
                var result = EvaluateCompleteness(candidate);
                if (candidate.IsProfileComplete != result.IsComplete)
                {
                    candidate.IsProfileComplete = result.IsComplete;
                    candidate.UpdatedAt = DateTime.UtcNow;
                    await _db.SaveChangesAsync();
                }
            }
        }

        private ProfileCompletenessDto EvaluateCompleteness(Candidate candidate)
        {
            return _evaluator.Evaluate(candidate);
        }

        // ==========================================
        // PRIVATE MAPPERS
        // ==========================================

        private static CandidateProfileDto MapToProfileDto(Candidate c)
        {
            return new CandidateProfileDto
            {
                Id = c.Id,
                UserId = c.UserId,
                FullName = c.User?.FullName ?? string.Empty,
                Email = c.User?.Email ?? string.Empty,
                Phone = c.Phone,
                City = c.City,
                Bio = c.Bio,
                LinkedInUrl = c.LinkedInUrl,
                PortfolioUrl = c.PortfolioUrl,
                IsProfileComplete = c.IsProfileComplete,
                CreatedAt = c.CreatedAt,
                UpdatedAt = c.UpdatedAt,
                Skills = c.CandidateSkills.Select(cs => new CandidateSkillDto
                {
                    Id = cs.Id,
                    SkillId = cs.SkillId,
                    SkillName = cs.Skill?.Name ?? string.Empty,
                    Category = cs.Skill?.Category ?? string.Empty,
                    ProficiencyLevel = cs.ProficiencyLevel,
                    CreatedAt = cs.CreatedAt
                }).ToList(),
                Educations = c.Educations.Select(e => MapToEducationDto(e)).ToList(),
                Experiences = c.Experiences.Select(exp => MapToExperienceDto(exp)).ToList(),
                Certificates = c.Certificates.Select(cert => new CertificateDto
                {
                    Id = cert.Id,
                    CandidateId = cert.CandidateId,
                    Title = cert.Title,
                    IssuingOrganization = cert.IssuingOrganization,
                    IssueDate = cert.IssueDate,
                    CertificateUrl = cert.CertificateUrl,
                    CreatedAt = cert.CreatedAt,
                    UpdatedAt = cert.UpdatedAt
                }).ToList(),
                CVDocuments = c.CVDocuments.Select(d => new CVDocumentDto
                {
                    Id = d.Id,
                    CandidateId = d.CandidateId,
                    FileName = d.FileName,
                    FilePath = d.FilePath,
                    FileSizeBytes = d.FileSizeBytes,
                    ContentType = d.ContentType,
                    UploadedAt = d.UploadedAt
                }).ToList(),
                Preference = c.Preference == null ? null : MapToPreferenceDto(c.Preference)
            };
        }

        private static EducationDto MapToEducationDto(Education e) => new()
        {
            Id = e.Id,
            CandidateId = e.CandidateId,
            Institution = e.Institution,
            Degree = e.Degree,
            FieldOfStudy = e.FieldOfStudy,
            StartYear = e.StartYear,
            EndYear = e.EndYear,
            CreatedAt = e.CreatedAt,
            UpdatedAt = e.UpdatedAt
        };

        private static ExperienceDto MapToExperienceDto(Experience exp) => new()
        {
            Id = exp.Id,
            CandidateId = exp.CandidateId,
            CompanyName = exp.CompanyName,
            JobTitle = exp.JobTitle,
            Description = exp.Description,
            DurationMonths = exp.DurationMonths,
            CreatedAt = exp.CreatedAt,
            UpdatedAt = exp.UpdatedAt
        };

        private static CandidatePreferenceDto MapToPreferenceDto(CandidatePreference p) => new()
        {
            Id = p.Id,
            CandidateId = p.CandidateId,
            PreferredLocation = p.PreferredLocation,
            PreferredWorkType = p.PreferredWorkType,
            ExpectedStipend = p.ExpectedStipend,
            CreatedAt = p.CreatedAt,
            UpdatedAt = p.UpdatedAt
        };
    }
}
