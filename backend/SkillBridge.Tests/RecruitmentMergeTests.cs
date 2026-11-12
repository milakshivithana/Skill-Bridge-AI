using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using SkillBridge.Api.Controllers;
using SkillBridge.Api.Data;
using SkillBridge.Api.DTOs;
using SkillBridge.Api.Models;

namespace SkillBridge.Tests;

public class RecruitmentMergeTests
{
    private static ApplicationDbContext Database() => new(new DbContextOptionsBuilder<ApplicationDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static T AsUser<T>(T controller, int userId, string role = "Candidate") where T : ControllerBase
    {
        controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                User = new ClaimsPrincipal(new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
                    new Claim(ClaimTypes.Role, role)
                }, "Test"))
            }
        };
        return controller;
    }

    private static VacanciesController Vacancies(ApplicationDbContext db, int userId) =>
        AsUser(new VacanciesController(db, new UnusedHttpFactory(), new ConfigurationBuilder().Build()), userId);

    private static T Body<T>(IActionResult result) => Assert.IsType<T>(Assert.IsType<OkObjectResult>(result).Value);

    [Fact]
    public async Task CandidateSessionsRemainIsolatedAcrossMergedRecruitmentEndpoints()
    {
        using var db = Database();
        db.Users.AddRange(
            new User { Id = 11, FullName = "Candidate A" },
            new User { Id = 22, FullName = "Candidate B" },
            new User { Id = 33, FullName = "Candidate C" });
        // User IDs deliberately differ from candidate IDs.
        db.Candidates.AddRange(
            new Candidate { Id = 101, UserId = 11, IsProfileComplete = true },
            new Candidate { Id = 102, UserId = 22, IsProfileComplete = true },
            new Candidate { Id = 103, UserId = 33, IsProfileComplete = true });
        db.Vacancies.Add(new Vacancy { Id = 7, Title = "Vacancy X", Company = new Company { Name = "Company X" } });
        db.SaveChanges();

        var a = Vacancies(db, 11);
        var b = Vacancies(db, 22);
        Assert.IsType<OkObjectResult>(a.ApplyToVacancy(7));
        var application = Assert.Single(db.Applications);
        Assert.Equal(101, application.CandidateId);
        Assert.True(Assert.Single(Body<PaginatedListDto<VacancyResponseDto>>(a.GetVacancies()).Items).HasApplied);
        Assert.False(Assert.Single(Body<PaginatedListDto<VacancyResponseDto>>(b.GetVacancies()).Items).HasApplied);
        Assert.IsType<BadRequestObjectResult>(a.ApplyToVacancy(7));

        var aApps = AsUser(new ApplicationsController(db), 11);
        var bApps = AsUser(new ApplicationsController(db), 22);
        Assert.Single(Body<List<ApplicationResponseDto>>(aApps.GetMyApplications()));
        Assert.Empty(Body<List<ApplicationResponseDto>>(bApps.GetMyApplications()));
        Assert.IsType<NotFoundObjectResult>(bApps.GetApplication(application.Id));
        Assert.IsType<NotFoundResult>(bApps.GetCandidateApplications(101));
        Assert.IsType<NotFoundObjectResult>(bApps.WithdrawApplication(application.Id));
        Assert.IsType<NotFoundObjectResult>(await b.EvaluateApplicationMatch(application.Id));

        db.Interviews.Add(new Interview { Id = 19, ApplicationId = application.Id, ScheduledTime = DateTime.UtcNow.AddDays(1) });
        db.SaveChanges();
        var aInterviews = AsUser(new InterviewsController(db), 11);
        var bInterviews = AsUser(new InterviewsController(db), 22);
        using var aJson = JsonDocument.Parse(Assert.IsType<ContentResult>(aInterviews.GetInterviews()).Content!);
        using var bJson = JsonDocument.Parse(Assert.IsType<ContentResult>(bInterviews.GetInterviews()).Content!);
        Assert.Equal(1, aJson.RootElement.GetArrayLength());
        Assert.Equal(0, bJson.RootElement.GetArrayLength());
        Assert.IsType<NotFoundResult>(bInterviews.GetInterview(19));

        var c = Vacancies(db, 33);
        Assert.False(Assert.Single(Body<PaginatedListDto<VacancyResponseDto>>(c.GetVacancies()).Items).HasApplied);
        Assert.Empty(Body<List<ApplicationResponseDto>>(AsUser(new ApplicationsController(db), 33).GetMyApplications()));
        Assert.IsType<OkObjectResult>(c.ApplyToVacancy(7));
        Assert.True(Assert.Single(Body<PaginatedListDto<VacancyResponseDto>>(c.GetVacancies()).Items).HasApplied);
        using var cJson = JsonDocument.Parse(Assert.IsType<ContentResult>(AsUser(new InterviewsController(db), 33).GetInterviews()).Content!);
        Assert.Equal(0, cJson.RootElement.GetArrayLength());
        Assert.Equal(103, Body<List<ApplicationResponseDto>>(AsUser(new ApplicationsController(db), 33).GetMyApplications()).Single().CandidateId);

        Assert.IsType<OkObjectResult>(AsUser(new ApplicationsController(db), 44, "Recruiter").GetApplication(application.Id));
        Assert.IsType<ContentResult>(AsUser(new InterviewsController(db), 44, "Administrator").GetInterview(19));
    }

    [Fact]
    public void InterviewResponseRetainsSharedUiFieldsWithoutLeakingUserCredentials()
    {
        using var db = Database();
        db.Users.Add(new User { Id = 11, FullName = "Candidate A", Email = "private@example.test", PasswordHash = "secret-hash" });
        db.Candidates.Add(new Candidate { Id = 101, UserId = 11 });
        db.Vacancies.Add(new Vacancy { Id = 7, Title = "Vacancy X", Company = new Company { Name = "Company X" } });
        db.Applications.Add(new Application { Id = 8, CandidateId = 101, VacancyId = 7 });
        db.Interviews.Add(new Interview { Id = 19, ApplicationId = 8 });
        db.SaveChanges();
        var json = Assert.IsType<ContentResult>(AsUser(new InterviewsController(db), 11).GetInterview(19)).Content!;
        Assert.Contains("Candidate A", json);
        Assert.Contains("Vacancy X", json);
        Assert.DoesNotContain("secret-hash", json);
        Assert.DoesNotContain("passwordHash", json);
        Assert.DoesNotContain("private@example.test", json);
    }

    private sealed class UnusedHttpFactory : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => throw new InvalidOperationException("Unauthorized requests must not invoke AI.");
    }
}
