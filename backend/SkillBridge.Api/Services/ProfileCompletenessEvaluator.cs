using System;
using System.Collections.Generic;
using System.Linq;
using SkillBridge.Api.DTOs;
using SkillBridge.Api.Models;

namespace SkillBridge.Api.Services
{
    public interface IProfileCompletenessEvaluator
    {
        ProfileCompletenessDto Evaluate(Candidate candidate);
        ProfileCompletenessDto Evaluate(string? phone, string? city, string? bio, int skillCount, int educationCount, int cvCount, int candidateId = 0);
    }

    /// <summary>
    /// Deterministic business rules engine for Candidate Profile Completeness.
    /// Evaluates whether a candidate has all mandatory data required before applications can progress.
    /// NOTE: Must NEVER rely on an LLM or probabilistic model to determine completeness.
    /// </summary>
    public class ProfileCompletenessEvaluator : IProfileCompletenessEvaluator
    {
        public const int TotalRequiredFields = 6;
        public const string FieldPhone = "Phone";
        public const string FieldCity = "City";
        public const string FieldBio = "Bio";
        public const string FieldSkills = "Skills";
        public const string FieldEducation = "Education";
        public const string FieldCV = "CV";

        public ProfileCompletenessDto Evaluate(Candidate candidate)
        {
            if (candidate == null)
            {
                return new ProfileCompletenessDto
                {
                    CandidateId = 0,
                    IsComplete = false,
                    CompletionPercentage = 0,
                    MissingFields = new List<string> { FieldPhone, FieldCity, FieldBio, FieldSkills, FieldEducation, FieldCV },
                    CompletedFields = new List<string>(),
                    EvaluatedAt = DateTime.UtcNow
                };
            }

            int skillCount = candidate.CandidateSkills?.Count(s => s.SkillId > 0) ?? 0;
            int educationCount = candidate.Educations?.Count(e => !string.IsNullOrWhiteSpace(e.Institution) && !string.IsNullOrWhiteSpace(e.Degree) && e.StartYear >= 1950 && e.EndYear >= e.StartYear && e.EndYear <= 2100) ?? 0;
            int cvCount = candidate.CVDocuments?.Count(c => !string.IsNullOrWhiteSpace(c.FileName) && !string.IsNullOrWhiteSpace(c.FilePath)) ?? 0;

            return Evaluate(candidate.Phone, candidate.City, candidate.Bio, skillCount, educationCount, cvCount, candidate.Id);
        }

        public ProfileCompletenessDto Evaluate(string? phone, string? city, string? bio, int skillCount, int educationCount, int cvCount, int candidateId = 0)
        {
            var missing = new List<string>();
            var completed = new List<string>();

            // 1. Phone Number (Mandatory: non-empty, non-whitespace)
            if (string.IsNullOrWhiteSpace(phone))
                missing.Add(FieldPhone);
            else
                completed.Add(FieldPhone);

            // 2. City / Location (Mandatory: non-empty, non-whitespace)
            if (string.IsNullOrWhiteSpace(city))
                missing.Add(FieldCity);
            else
                completed.Add(FieldCity);

            // 3. Bio / Professional Summary (Mandatory: non-empty, non-whitespace)
            if (string.IsNullOrWhiteSpace(bio))
                missing.Add(FieldBio);
            else
                completed.Add(FieldBio);

            // 4. Skills Taxonomy (Mandatory: at least 1 declared skill)
            if (skillCount <= 0)
                missing.Add(FieldSkills);
            else
                completed.Add(FieldSkills);

            // 5. Education (Mandatory: at least 1 qualification / degree)
            if (educationCount <= 0)
                missing.Add(FieldEducation);
            else
                completed.Add(FieldEducation);

            // 6. CV Document (Mandatory: at least 1 uploaded CV file)
            if (cvCount <= 0)
                missing.Add(FieldCV);
            else
                completed.Add(FieldCV);

            int percentage = (int)Math.Round((double)completed.Count / TotalRequiredFields * 100);

            return new ProfileCompletenessDto
            {
                CandidateId = candidateId,
                IsComplete = missing.Count == 0,
                CompletionPercentage = percentage,
                MissingFields = missing,
                CompletedFields = completed,
                EvaluatedAt = DateTime.UtcNow
            };
        }
    }
}
