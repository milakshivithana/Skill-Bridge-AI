using System.Collections.Generic;
using SkillBridge.Api.Models;
using SkillBridge.Api.Services;
using Xunit;

namespace SkillBridge.Tests
{
    /// <summary>
    /// Deterministic Unit Tests for Candidate Profile Completeness Business Logic.
    /// Covers 100% complete, partial, empty, whitespace-only, and entity-level evaluations.
    /// </summary>
    public class ProfileCompletenessTests
    {
        private readonly ProfileCompletenessEvaluator _evaluator = new();

        [Fact]
        public void EmptyOrMalformedRecordsDoNotCompleteAProfile()
        {
            var candidate = new Candidate
            {
                Phone = "123", City = "Colombo", Bio = "Student",
                CandidateSkills = new() { new CandidateSkill() },
                Educations = new() { new Education { Institution = " ", Degree = "MBBS" } },
                CVDocuments = new() { new CVDocument { FileName = "cv.pdf" } }
            };
            var result = _evaluator.Evaluate(candidate);
            Assert.Equal(50, result.CompletionPercentage);
            Assert.Equal(new[] { "Skills", "Education", "CV" }, result.MissingFields);
            Assert.False(result.IsComplete);
        }

        [Fact]
        public void Test_CompleteProfile_Returns100PercentAndIsCompleteTrue()
        {
            // Arrange: All 6 mandatory fields satisfied
            string phone = "+94771234567";
            string city = "Colombo";
            string bio = "Software engineering student with strong background in C# and React.";
            int skillCount = 3;
            int educationCount = 1;
            int cvCount = 1;

            // Act
            var result = _evaluator.Evaluate(phone, city, bio, skillCount, educationCount, cvCount, candidateId: 101);

            // Assert
            Assert.True(result.IsComplete);
            Assert.Equal(100, result.CompletionPercentage);
            Assert.Empty(result.MissingFields);
            Assert.Equal(6, result.CompletedFields.Count);
            Assert.Contains(ProfileCompletenessEvaluator.FieldPhone, result.CompletedFields);
            Assert.Contains(ProfileCompletenessEvaluator.FieldCity, result.CompletedFields);
            Assert.Contains(ProfileCompletenessEvaluator.FieldBio, result.CompletedFields);
            Assert.Contains(ProfileCompletenessEvaluator.FieldSkills, result.CompletedFields);
            Assert.Contains(ProfileCompletenessEvaluator.FieldEducation, result.CompletedFields);
            Assert.Contains(ProfileCompletenessEvaluator.FieldCV, result.CompletedFields);
        }

        [Fact]
        public void Test_MissingCV_Returns83PercentAndFlagsCV()
        {
            // Arrange: 5 out of 6 satisfied (missing CV)
            string phone = "+94771234567";
            string city = "Kandy";
            string bio = "Computer Science undergraduate.";
            int skillCount = 4;
            int educationCount = 1;
            int cvCount = 0; // Missing CV

            // Act
            var result = _evaluator.Evaluate(phone, city, bio, skillCount, educationCount, cvCount);

            // Assert
            Assert.False(result.IsComplete);
            Assert.Equal(83, result.CompletionPercentage); // 5/6 = 83.33% -> 83%
            Assert.Single(result.MissingFields);
            Assert.Contains(ProfileCompletenessEvaluator.FieldCV, result.MissingFields);
        }

        [Fact]
        public void Test_MissingEducationAndCV_Returns67PercentAndFlagsBoth()
        {
            // Arrange: 4 out of 6 satisfied (missing Education and CV)
            string phone = "+94771234567";
            string city = "Galle";
            string bio = "Self-taught developer.";
            int skillCount = 2;
            int educationCount = 0; // Missing Education
            int cvCount = 0;        // Missing CV

            // Act
            var result = _evaluator.Evaluate(phone, city, bio, skillCount, educationCount, cvCount);

            // Assert
            Assert.False(result.IsComplete);
            Assert.Equal(67, result.CompletionPercentage); // 4/6 = 66.67% -> 67%
            Assert.Equal(2, result.MissingFields.Count);
            Assert.Contains(ProfileCompletenessEvaluator.FieldEducation, result.MissingFields);
            Assert.Contains(ProfileCompletenessEvaluator.FieldCV, result.MissingFields);
        }

        [Fact]
        public void Test_MissingSkills_Returns83PercentAndFlagsSkills()
        {
            // Arrange: No skills declared
            string phone = "+94771234567";
            string city = "Colombo";
            string bio = "Recent graduate.";
            int skillCount = 0; // Missing Skills
            int educationCount = 1;
            int cvCount = 1;

            // Act
            var result = _evaluator.Evaluate(phone, city, bio, skillCount, educationCount, cvCount);

            // Assert
            Assert.False(result.IsComplete);
            Assert.Equal(83, result.CompletionPercentage);
            Assert.Contains(ProfileCompletenessEvaluator.FieldSkills, result.MissingFields);
        }

        [Fact]
        public void Test_EmptyCandidateProfile_Returns0PercentAndAllMissing()
        {
            // Arrange: Nothing filled
            string? phone = null;
            string? city = "";
            string? bio = "";
            int skillCount = 0;
            int educationCount = 0;
            int cvCount = 0;

            // Act
            var result = _evaluator.Evaluate(phone, city, bio, skillCount, educationCount, cvCount);

            // Assert
            Assert.False(result.IsComplete);
            Assert.Equal(0, result.CompletionPercentage);
            Assert.Equal(6, result.MissingFields.Count);
            Assert.Empty(result.CompletedFields);
        }

        [Fact]
        public void Test_WhitespaceOnlyFields_TreatedAsMissing()
        {
            // Arrange: Fields with only whitespace
            string phone = "   ";
            string city = "\t";
            string bio = "  \n  ";
            int skillCount = 1;
            int educationCount = 1;
            int cvCount = 1;

            // Act
            var result = _evaluator.Evaluate(phone, city, bio, skillCount, educationCount, cvCount);

            // Assert
            Assert.False(result.IsComplete);
            Assert.Equal(50, result.CompletionPercentage); // 3 of 6 fields completed
            Assert.Contains(ProfileCompletenessEvaluator.FieldPhone, result.MissingFields);
            Assert.Contains(ProfileCompletenessEvaluator.FieldCity, result.MissingFields);
            Assert.Contains(ProfileCompletenessEvaluator.FieldBio, result.MissingFields);
        }

        [Fact]
        public void Test_CandidateEntityEvaluation_MatchesDirectEvaluation()
        {
            // Arrange: Entity model with navigations populated
            var candidate = new Candidate
            {
                Id = 42,
                Phone = "+94719876543",
                City = "Negombo",
                Bio = "Full-stack developer interested in backend and AI pipelines.",
                CandidateSkills = new List<CandidateSkill>
                {
                    new() { SkillId = 1, ProficiencyLevel = "Expert" },
                    new() { SkillId = 2, ProficiencyLevel = "Intermediate" }
                },
                Educations = new List<Education>
                {
                    new() { Institution = "SLIIT", Degree = "BSc in SE", StartYear = 2023, EndYear = 2026 }
                },
                CVDocuments = new List<CVDocument>
                {
                    new() { FileName = "resume.pdf", FilePath = "cv_42_abc.pdf" }
                }
            };

            // Act
            var result = _evaluator.Evaluate(candidate);

            // Assert
            Assert.True(result.IsComplete);
            Assert.Equal(100, result.CompletionPercentage);
            Assert.Equal(42, result.CandidateId);
            Assert.Empty(result.MissingFields);
        }

        [Fact]
        public void Test_NullCandidate_ReturnsSafeZeroScoreWithoutThrowing()
        {
            // Act
            var result = _evaluator.Evaluate((Candidate)null!);

            // Assert
            Assert.NotNull(result);
            Assert.False(result.IsComplete);
            Assert.Equal(0, result.CompletionPercentage);
            Assert.Equal(6, result.MissingFields.Count);
        }
    }
}
