using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using SkillBridge.Api.Controllers;
using SkillBridge.Api.DTOs;
using SkillBridge.Api.Services;
using Xunit;

namespace SkillBridge.Tests
{
    public class FakeCandidateService : ICandidateService
    {
        public bool OwnershipAllowed { get; set; } = true;
        public ProfileCompletenessDto CompletenessResult { get; set; } = new()
        {
            CandidateId = 1,
            IsComplete = true,
            CompletionPercentage = 100,
            MissingFields = new List<string>(),
            CompletedFields = new List<string> { "Phone", "City", "Bio", "Skills", "Education", "CV" }
        };

        public CandidateProfileDto? ProfileResult { get; set; } = new()
        {
            Id = 1,
            UserId = 10,
            FullName = "Test Candidate",
            City = "Colombo",
            Phone = "+94770000000",
            Bio = "Test Bio",
            IsProfileComplete = true,
            Skills = new List<CandidateSkillDto>
            {
                new() { SkillId = 1, SkillName = "React", ProficiencyLevel = "Expert" }
            },
            Educations = new List<EducationDto>
            {
                new() { Degree = "BSc", Institution = "University", FieldOfStudy = "IT" }
            },
            Experiences = new List<ExperienceDto>
            {
                new() { CompanyName = "Company", JobTitle = "Engineer", DurationMonths = 12 }
            }
        };

        public Task<bool> VerifyCandidateOwnershipAsync(int candidateId, int userId)
        {
            return Task.FromResult(OwnershipAllowed);
        }

        public Task<ProfileCompletenessDto> CalculateProfileCompletenessAsync(int candidateId)
        {
            return Task.FromResult(CompletenessResult);
        }

        public Task<CandidateProfileDto?> GetProfileAsync(int candidateId)
        {
            return Task.FromResult(ProfileResult);
        }

        // Interface stubs
        public Task<CandidateProfileDto?> GetProfileByUserIdAsync(int userId) => Task.FromResult<CandidateProfileDto?>(null);
        public Task<CandidateProfileDto?> UpdateProfileAsync(int candidateId, UpdateCandidateProfileDto dto) => Task.FromResult<CandidateProfileDto?>(null);
        public Task<PagedResultDto<CandidateSummaryDto>> SearchCandidatesAsync(string? query, string? skill, string? city, int page, int pageSize) => Task.FromResult(new PagedResultDto<CandidateSummaryDto>());
        public Task<List<CandidateSkillDto>> GetSkillsAsync(int candidateId) => Task.FromResult(new List<CandidateSkillDto>());
        public Task<CandidateSkillDto?> AddSkillAsync(int candidateId, AddCandidateSkillDto dto) => Task.FromResult<CandidateSkillDto?>(null);
        public Task<bool> RemoveSkillAsync(int candidateId, int skillId) => Task.FromResult(true);
        public Task<List<SkillDto>> GetAllTaxonomySkillsAsync() => Task.FromResult(new List<SkillDto>());
        public Task<SkillDto> CreateTaxonomySkillAsync(CreateSkillDto dto) => Task.FromResult(new SkillDto());
        public Task<List<EducationDto>> GetEducationsAsync(int candidateId) => Task.FromResult(new List<EducationDto>());
        public Task<EducationDto?> GetEducationByIdAsync(int candidateId, int educationId) => Task.FromResult<EducationDto?>(null);
        public Task<EducationDto> AddEducationAsync(int candidateId, CreateEducationDto dto) => Task.FromResult(new EducationDto());
        public Task<EducationDto?> UpdateEducationAsync(int candidateId, int educationId, UpdateEducationDto dto) => Task.FromResult<EducationDto?>(null);
        public Task<bool> DeleteEducationAsync(int candidateId, int educationId) => Task.FromResult(true);
        public Task<List<ExperienceDto>> GetExperiencesAsync(int candidateId) => Task.FromResult(new List<ExperienceDto>());
        public Task<ExperienceDto?> GetExperienceByIdAsync(int candidateId, int experienceId) => Task.FromResult<ExperienceDto?>(null);
        public Task<ExperienceDto> AddExperienceAsync(int candidateId, CreateExperienceDto dto) => Task.FromResult(new ExperienceDto());
        public Task<ExperienceDto?> UpdateExperienceAsync(int candidateId, int experienceId, UpdateExperienceDto dto) => Task.FromResult<ExperienceDto?>(null);
        public Task<bool> DeleteExperienceAsync(int candidateId, int experienceId) => Task.FromResult(true);
        public Task<CandidatePreferenceDto?> GetPreferencesAsync(int candidateId) => Task.FromResult<CandidatePreferenceDto?>(null);
        public Task<CandidatePreferenceDto> UpdatePreferencesAsync(int candidateId, UpdateCandidatePreferenceDto dto) => Task.FromResult(new CandidatePreferenceDto());
        public Task<CVDocumentDto> UploadCVAsync(int candidateId, IFormFile file) => Task.FromResult(new CVDocumentDto());
        public Task<CVDocumentDto?> GetLatestCVAsync(int candidateId) => Task.FromResult<CVDocumentDto?>(null);
        public Task<CVDocumentDto?> GetCVByIdAsync(int candidateId, int cvId) => Task.FromResult<CVDocumentDto?>(null);
        public Task<List<CertificateDto>> GetCertificatesAsync(int candidateId) => Task.FromResult(new List<CertificateDto>());
        public Task<CertificateDto> AddCertificateAsync(int candidateId, CreateCertificateDto dto) => Task.FromResult(new CertificateDto());
        public Task<bool> DeleteCertificateAsync(int candidateId, int certificateId) => Task.FromResult(true);
    }

    public class FakeHttpClientFactory : IHttpClientFactory
    {
        public HttpClient CreateClient(string name)
        {
            return new HttpClient(new FakeHttpMessageHandler());
        }
    }

    public class FakeHttpMessageHandler : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            // Simulate offline AI service failure
            throw new HttpRequestException("AI Microservice unreachable in test environment");
        }
    }

    public class CandidateAnalysisTests
    {
        [Fact]
        public async Task AnalyzeProfile_WhenAuthorizedAndAIOffline_ReturnsFallbackGracefully()
        {
            // Arrange
            var fakeService = new FakeCandidateService();
            var fakeClientFactory = new FakeHttpClientFactory();
            var configValues = new Dictionary<string, string?>
            {
                { "AgenticAiService:BaseUrl", "http://localhost:8000" }
            };
            var config = new ConfigurationBuilder().AddInMemoryCollection(configValues).Build();

            var controller = new CandidatesController(fakeService, fakeClientFactory, config);

            var user = new ClaimsPrincipal(new ClaimsIdentity(new[]
            {
                new Claim(ClaimTypes.NameIdentifier, "10"),
                new Claim(ClaimTypes.Role, "Candidate")
            }, "TestAuth"));

            controller.ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = user }
            };

            // Act
            var result = await controller.AnalyzeProfile(1);

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(result);
            Assert.NotNull(okResult.Value);

            var json = System.Text.Json.JsonSerializer.Serialize(okResult.Value);
            using var doc = System.Text.Json.JsonDocument.Parse(json);
            var root = doc.RootElement;

            Assert.Equal(1, root.GetProperty("candidateId").GetInt32());
            Assert.True(root.GetProperty("isEligibleToApply").GetBoolean());
            Assert.Equal(100, root.GetProperty("profileScorePercentage").GetInt32());
            Assert.Equal("OFFLINE_FALLBACK", root.GetProperty("aiStatus").GetString());
        }

        [Fact]
        public async Task AnalyzeProfile_WhenNotAuthorized_ReturnsForbid()
        {
            // Arrange
            var fakeService = new FakeCandidateService { OwnershipAllowed = false };
            var fakeClientFactory = new FakeHttpClientFactory();
            var config = new ConfigurationBuilder().Build();

            var controller = new CandidatesController(fakeService, fakeClientFactory, config);

            var user = new ClaimsPrincipal(new ClaimsIdentity(new[]
            {
                new Claim(ClaimTypes.NameIdentifier, "99"), // Different user
                new Claim(ClaimTypes.Role, "Candidate")
            }, "TestAuth"));

            controller.ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = user }
            };

            // Act
            var result = await controller.AnalyzeProfile(1);

            // Assert
            Assert.IsType<ForbidResult>(result);
        }
    }
}
