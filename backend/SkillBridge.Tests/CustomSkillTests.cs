using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Logging.Abstractions;
using SkillBridge.Api.Data;
using SkillBridge.Api.DTOs;
using SkillBridge.Api.Models;
using SkillBridge.Api.Services;
using Xunit;

namespace SkillBridge.Tests
{
    public class FakeWebHostEnvironment : IWebHostEnvironment
    {
        public string WebRootPath { get; set; } = string.Empty;
        public IFileProvider WebRootFileProvider { get; set; } = null!;
        public string EnvironmentName { get; set; } = "Testing";
        public string ApplicationName { get; set; } = "SkillBridge.Tests";
        public string ContentRootPath { get; set; } = AppContext.BaseDirectory;
        public IFileProvider ContentRootFileProvider { get; set; } = null!;
    }

    /// <summary>
    /// Unit tests for custom skill creation and attachment in CandidateService.
    /// Covers:
    /// 1. Existing skill can still be attached.
    /// 2. New custom skill can be created and attached.
    /// 3. Duplicate skill name is not created.
    /// 4. Case-insensitive duplicate is handled.
    /// 5. Whitespace is normalized.
    /// 6. Candidate cannot attach the same skill twice.
    /// 7. Empty skill name is rejected.
    /// 8. Removing a custom skill from the candidate still works.
    /// 9. Existing skill taxonomy behaviour remains working.
    /// </summary>
    public class CustomSkillTests : IDisposable
    {
        private readonly ApplicationDbContext _db;
        private readonly CandidateService _service;

        public CustomSkillTests()
        {
            var options = new DbContextOptionsBuilder<ApplicationDbContext>()
                .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
                .Options;
            _db = new ApplicationDbContext(options);

            var user = new User
            {
                Id = 1,
                FullName = "Test Candidate",
                Email = "candidate@test.com",
                PasswordHash = "hash",
                Role = "Candidate"
            };
            _db.Users.Add(user);

            var candidate = new Candidate
            {
                Id = 1,
                UserId = 1
            };
            _db.Candidates.Add(candidate);

            var reactSkill = new Skill
            {
                Id = 1,
                Name = "React",
                Category = "Programming"
            };
            _db.Skills.Add(reactSkill);
            _db.SaveChanges();

            var env = new FakeWebHostEnvironment();
            var logger = NullLogger<CandidateService>.Instance;
            var evaluator = new ProfileCompletenessEvaluator();
            _service = new CandidateService(_db, env, logger, evaluator);
        }

        public void Dispose()
        {
            _db.Dispose();
        }

        [Fact]
        public async Task Test1_ExistingSkill_CanStillBeAttached()
        {
            var dto = new AddCandidateSkillDto
            {
                SkillId = 1,
                ProficiencyLevel = "Expert"
            };

            var result = await _service.AddSkillAsync(1, dto);

            Assert.NotNull(result);
            Assert.Equal("React", result!.SkillName);
            Assert.Equal("Expert", result.ProficiencyLevel);
            Assert.Equal(1, await _db.CandidateSkills.CountAsync());
        }

        [Fact]
        public async Task Test2_NewCustomSkill_CanBeCreatedAndAttached()
        {
            var dto = new AddCandidateSkillDto
            {
                SkillName = "Flutter",
                ProficiencyLevel = "Intermediate"
            };

            var result = await _service.AddSkillAsync(1, dto);

            Assert.NotNull(result);
            Assert.Equal("Flutter", result!.SkillName);
            Assert.Equal("General", result.Category);
            Assert.True(await _db.Skills.AnyAsync(s => s.Name == "Flutter"));
            Assert.Equal(1, await _db.CandidateSkills.CountAsync());
        }

        [Fact]
        public async Task Test3_DuplicateSkillName_IsNotCreatedAcrossCandidates()
        {
            var dto1 = new AddCandidateSkillDto { SkillName = "Docker", ProficiencyLevel = "Beginner" };
            await _service.AddSkillAsync(1, dto1);
            int skillCountAfterFirst = await _db.Skills.CountAsync();

            var user2 = new User
            {
                Id = 2,
                FullName = "Candidate Two",
                Email = "candidate2@test.com",
                PasswordHash = "hash",
                Role = "Candidate"
            };
            _db.Users.Add(user2);
            _db.Candidates.Add(new Candidate { Id = 2, UserId = 2 });
            await _db.SaveChangesAsync();

            var dto2 = new AddCandidateSkillDto { SkillName = "Docker", ProficiencyLevel = "Expert" };
            await _service.AddSkillAsync(2, dto2);

            Assert.Equal(skillCountAfterFirst, await _db.Skills.CountAsync());
            Assert.Equal(2, await _db.CandidateSkills.CountAsync());
        }

        [Fact]
        public async Task Test4_CaseInsensitiveDuplicate_IsReusedNotDuplicated()
        {
            var dto = new AddCandidateSkillDto { SkillName = "REACT", ProficiencyLevel = "Intermediate" };

            var result = await _service.AddSkillAsync(1, dto);

            Assert.NotNull(result);
            Assert.Equal("React", result!.SkillName);
            Assert.Equal(1, result.SkillId);
            Assert.Equal(1, await _db.Skills.CountAsync());
        }

        [Fact]
        public async Task Test5_Whitespace_IsNormalized()
        {
            var dto = new AddCandidateSkillDto { SkillName = "  react  ", ProficiencyLevel = "Beginner" };

            var result = await _service.AddSkillAsync(1, dto);

            Assert.NotNull(result);
            Assert.Equal("React", result!.SkillName);
            Assert.Equal(1, await _db.Skills.CountAsync());
        }

        [Fact]
        public async Task Test6_CandidateCannotAttachSameSkillTwice_UpdatesInstead()
        {
            var dto1 = new AddCandidateSkillDto { SkillId = 1, ProficiencyLevel = "Beginner" };
            await _service.AddSkillAsync(1, dto1);

            var dto2 = new AddCandidateSkillDto { SkillId = 1, ProficiencyLevel = "Expert" };
            var result = await _service.AddSkillAsync(1, dto2);

            Assert.NotNull(result);
            Assert.Equal("Expert", result!.ProficiencyLevel);
            Assert.Equal(1, await _db.CandidateSkills.CountAsync());
        }

        [Fact]
        public async Task Test7_EmptySkillName_IsRejected()
        {
            var dto = new AddCandidateSkillDto { SkillName = "   ", ProficiencyLevel = "Intermediate" };

            var result = await _service.AddSkillAsync(1, dto);

            Assert.Null(result);
            Assert.Equal(0, await _db.CandidateSkills.CountAsync());
        }

        [Fact]
        public async Task Test8_RemovingCustomSkill_RemovesFromCandidateKeepsGlobalSkill()
        {
            var dto = new AddCandidateSkillDto { SkillName = "Kubernetes", ProficiencyLevel = "Expert" };
            var added = await _service.AddSkillAsync(1, dto);
            Assert.NotNull(added);

            var removed = await _service.RemoveSkillAsync(1, added!.SkillId);

            Assert.True(removed);
            Assert.Equal(0, await _db.CandidateSkills.CountAsync());
            Assert.True(await _db.Skills.AnyAsync(s => s.Name == "Kubernetes"));
        }

        [Fact]
        public async Task Test9_ExistingSkillTaxonomy_RemainsWorking()
        {
            var skills = await _service.GetAllTaxonomySkillsAsync();

            Assert.NotEmpty(skills);
            Assert.Contains(skills, s => s.Name == "React");

            var newSkill = await _service.CreateTaxonomySkillAsync(new CreateSkillDto { Name = "TypeScript", Category = "Language" });
            Assert.NotNull(newSkill);
            Assert.Equal("TypeScript", newSkill.Name);
            Assert.Equal("Language", newSkill.Category);

            var duplicate = await _service.CreateTaxonomySkillAsync(new CreateSkillDto { Name = "typescript" });
            Assert.Equal(newSkill.Id, duplicate.Id);
        }
    }
}
