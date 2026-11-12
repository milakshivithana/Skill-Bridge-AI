using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using SkillBridge.Api.Data;
using SkillBridge.Api.DTOs;
using SkillBridge.Api.Models;
using SkillBridge.Api.Services;

namespace SkillBridge.Tests;

public class CandidateIsolationTests
{
    [Fact]
    public async Task CandidateAAndB_ApplicationsInterviewsAndEvaluationStayIsolated()
    {
        using var factory = new IsolationApiFactory();
        using var anonymous = factory.CreateClient();
        using var staff = factory.StaffClient();
        var (a, candidateA) = await Register(factory, "A");
        var (b, candidateB) = await Register(factory, "B");
        using var clientA = a;
        using var clientB = b;
        Assert.NotEqual(candidateA.UserId, candidateA.CandidateId);
        factory.CompleteProfile(candidateA.CandidateId!.Value);

        // A browser-supplied candidate ID must have no authority over the application owner.
        var apply = await clientA.PostAsync($"/api/vacancies/{factory.VacancyId}/apply?candidateId={candidateB.CandidateId}", null);
        Assert.Equal(HttpStatusCode.OK, apply.StatusCode);
        var app = await Json(apply);
        int appId = app.GetProperty("id").GetInt32();
        Assert.Equal(candidateA.CandidateId, app.GetProperty("candidateId").GetInt32());
        Assert.Equal(HttpStatusCode.BadRequest, (await clientA.PostAsync($"/api/vacancies/{factory.VacancyId}/apply", null)).StatusCode);
        Assert.True(await HasApplied(clientA, factory.VacancyId));
        Assert.False(await HasApplied(clientB, factory.VacancyId));
        var applicationsA = await Get(clientA, "/api/applications/me");
        Assert.Equal(appId, Assert.Single(applicationsA.EnumerateArray()).GetProperty("id").GetInt32());
        Assert.Empty((await Get(clientB, $"/api/applications/me?candidateId={candidateA.CandidateId}")).EnumerateArray());
        Assert.Empty((await Get(clientB, "/api/vacancies/my-applications")).EnumerateArray());
        Assert.Equal(HttpStatusCode.NotFound, (await clientB.GetAsync($"/api/applications/{appId}")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await clientB.PostAsync($"/api/applications/{appId}/evaluate-match", null)).StatusCode);
        Assert.Empty(factory.Ai.Requests);

        // Legitimate evaluation retains the application's candidate and stops for HITL review.
        var evaluated = await clientA.PostAsync($"/api/applications/{appId}/evaluate-match", null);
        Assert.Equal(HttpStatusCode.OK, evaluated.StatusCode);
        var result = await Json(evaluated);
        Assert.Equal("PENDING_RECRUITER_APPROVAL", result.GetProperty("status").GetString());
        var aiPayload = JsonDocument.Parse(Assert.Single(factory.Ai.Requests)).RootElement;
        Assert.Equal(candidateA.CandidateId, aiPayload.GetProperty("candidate_id").GetInt32());
        Assert.Equal(candidateA.CandidateId, aiPayload.GetProperty("profile_data").GetProperty("candidate_id").GetInt32());
        Assert.Equal(factory.VacancyId, aiPayload.GetProperty("vacancy_data").GetProperty("vacancy_id").GetInt32());
        Assert.Equal($"Cardiology {candidateA.CandidateId}", Assert.Single(aiPayload.GetProperty("profile_data").GetProperty("skills").EnumerateArray()).GetString());
        Assert.Equal("MBBS", Assert.Single(aiPayload.GetProperty("profile_data").GetProperty("education").EnumerateArray()).GetProperty("degree").GetString());
        Assert.Empty((await Get(clientA, "/api/interviews")).EnumerateArray());
        int workflowId = result.GetProperty("aiWorkflowId").GetInt32();
        Assert.Equal(HttpStatusCode.OK, (await clientA.GetAsync($"/api/ai-workflows/{workflowId}")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await clientB.GetAsync($"/api/ai-workflows/{workflowId}")).StatusCode);

        var schedule = new { applicationId = appId, scheduledTime = DateTime.UtcNow.AddDays(3), durationMinutes = 45 };
        Assert.Equal(HttpStatusCode.BadRequest, (await staff.PostAsJsonAsync("/api/interviews", schedule)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await clientB.PostAsJsonAsync("/api/interviews", schedule)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await clientB.PostAsync($"/api/shortlists/{appId}/approve", null)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await staff.PostAsync($"/api/shortlists/{appId}/approve?approverUserId={candidateB.UserId}", null)).StatusCode);
        var interviewResponse = await staff.PostAsJsonAsync("/api/interviews", schedule);
        Assert.Equal(HttpStatusCode.Created, interviewResponse.StatusCode);
        var interview = await Json(interviewResponse);
        int interviewId = interview.GetProperty("id").GetInt32();
        Assert.Equal("SCHEDULED", interview.GetProperty("status").GetString());
        Assert.Equal(interviewId, Assert.Single((await Get(clientA, "/api/interviews")).EnumerateArray()).GetProperty("id").GetInt32());
        Assert.Empty((await Get(clientB, $"/api/interviews?candidateId={candidateA.CandidateId}")).EnumerateArray());
        Assert.Empty((await Get(clientB, "/api/interviews/me")).EnumerateArray());
        Assert.Equal(HttpStatusCode.NotFound, (await clientB.GetAsync($"/api/interviews/{interviewId}")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await clientA.GetAsync($"/api/interviews/{interviewId}")).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await clientB.PostAsync($"/api/interviews/{interviewId}/reschedule?newTime=2027-01-01T12:00:00Z", null)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await clientB.PostAsync($"/api/interviews/{interviewId}/assign-panel?interviewerId=1", null)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await clientB.PostAsync($"/api/interviews/{interviewId}/suggest-slot", null)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await clientB.GetAsync("/api/applications/pending-approval")).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await clientB.GetAsync("/api/shortlists")).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await clientB.GetAsync("/api/audit-logs")).StatusCode);
        Assert.Single((await Get(staff, "/api/interviews")).EnumerateArray());
        Assert.Equal(HttpStatusCode.OK, (await staff.GetAsync($"/api/applications/{appId}")).StatusCode);
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        Assert.Equal(factory.StaffUserId, db.Approvals.Single().ApproverUserId);
        Assert.Equal(factory.StaffUserId, db.AuditLogs.Single().UserId);
        Assert.Single(db.Applications);
        Assert.Single(db.Interviews);
    }

    [Fact]
    public async Task NewlyRegisteredC_IsEmptyUntilOwnApplication_AndHasNoAutomaticInterview()
    {
        using var factory = new IsolationApiFactory();
        using var startup = factory.CreateClient();
        factory.SeedOtherCandidatesInterview();
        var (client, candidate) = await Register(factory, "C");
        using var c = client;
        Assert.False(await HasApplied(c, factory.VacancyId));
        Assert.Empty((await Get(c, "/api/applications/me")).EnumerateArray());
        Assert.Empty((await Get(c, "/api/interviews")).EnumerateArray());
        // Preserve the existing completeness gate rather than bypassing it for new accounts.
        Assert.Equal(HttpStatusCode.BadRequest, (await c.PostAsync($"/api/vacancies/{factory.VacancyId}/apply", null)).StatusCode);
        factory.CompleteProfile(candidate.CandidateId!.Value);
        Assert.Equal(HttpStatusCode.OK, (await c.PostAsync($"/api/vacancies/{factory.VacancyId}/apply", null)).StatusCode);
        Assert.True(await HasApplied(c, factory.VacancyId));
        var app = Assert.Single((await Get(c, "/api/applications/me")).EnumerateArray());
        Assert.Equal(candidate.CandidateId, app.GetProperty("candidateId").GetInt32());
        Assert.Empty((await Get(c, "/api/interviews")).EnumerateArray());
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        Assert.Equal(2, db.Applications.Count());
        Assert.Single(db.Interviews); // Existing other-candidate data is retained, not deleted.
    }

    [Fact]
    public async Task AnonymousRequestsCannotReadOrMutateCandidateResources()
    {
        using var factory = new IsolationApiFactory();
        using var client = factory.CreateClient();
        foreach (var path in new[] { "/api/applications/me", "/api/applications/1", "/api/interviews", "/api/interviews/1", "/api/ai-workflows/1", "/api/applications/pending-approval" })
            Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync(path)).StatusCode);
        foreach (var path in new[] { "/api/vacancies/1/apply?candidateId=1", "/api/applications/1/evaluate-match", "/api/shortlists/1/approve" })
            Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsync(path, null)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/interviews", new { applicationId = 1 })).StatusCode);
    }

    [Fact]
    public async Task StaffRetainBroaderAccess_InterviewersOnlySeeAssignedInterviews()
    {
        using var factory = new IsolationApiFactory();
        using var startup = factory.CreateClient();
        factory.SeedOtherCandidatesInterview();
        using var recruiter = factory.StaffClient();
        using var admin = factory.StaffClient("Administrator");
        using var assigned = factory.InterviewerClient(true);
        using var other = factory.InterviewerClient(false);
        foreach (var client in new[] { recruiter, admin, assigned })
        {
            Assert.Single((await Get(client, "/api/interviews")).EnumerateArray());
            Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/interviews/1")).StatusCode);
        }
        Assert.Empty((await Get(other, "/api/interviews")).EnumerateArray());
        Assert.Equal(HttpStatusCode.NotFound, (await other.GetAsync("/api/interviews/1")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.PostAsync("/api/interviews/1/suggest-slot", null)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await recruiter.GetAsync("/api/applications/pending-approval")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await admin.GetAsync("/api/shortlists")).StatusCode);
    }

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public async Task FailedEvaluationDoesNotFabricateScoreOrAdvanceWorkflow(bool offline)
    {
        using var factory = new IsolationApiFactory();
        factory.Ai.Offline = offline;
        factory.Ai.MissingScore = !offline;
        var (client, candidate) = await Register(factory, "Offline");
        using var c = client;
        factory.CompleteProfile(candidate.CandidateId!.Value);
        var application = await Json(await c.PostAsync($"/api/vacancies/{factory.VacancyId}/apply", null));
        int id = application.GetProperty("id").GetInt32();
        Assert.Equal(offline ? HttpStatusCode.ServiceUnavailable : HttpStatusCode.BadGateway,
            (await c.PostAsync($"/api/applications/{id}/evaluate-match", null)).StatusCode);
        var unchanged = await Get(c, $"/api/applications/{id}");
        Assert.Equal("SUBMITTED", unchanged.GetProperty("status").GetString());
        Assert.Equal(0, unchanged.GetProperty("matchScore").GetDouble());
        Assert.Empty((await Get(c, "/api/interviews")).EnumerateArray());
    }

    [Fact]
    public async Task MissingCandidateProfileFailsClosed_InsteadOfUsingFirstCandidate()
    {
        using var factory = new IsolationApiFactory();
        var (client, candidate) = await Register(factory, "MissingProfile");
        using var c = client;
        factory.SeedOtherCandidatesInterview();
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            db.Candidates.Remove(db.Candidates.Find(candidate.CandidateId) !);
            db.SaveChanges();
        }
        Assert.False(await HasApplied(c, factory.VacancyId));
        Assert.Empty((await Get(c, "/api/applications/me")).EnumerateArray());
        Assert.Empty((await Get(c, "/api/interviews")).EnumerateArray());
        Assert.Equal(HttpStatusCode.NotFound, (await c.PostAsync($"/api/vacancies/{factory.VacancyId}/apply", null)).StatusCode);
    }

    private static async Task<(HttpClient, AuthResponseDto)> Register(IsolationApiFactory factory, string name)
    {
        var client = factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = $"Candidate {name}", email = $"{name}@isolation.test", password = "TestOnly123!", role = "Candidate"
        });
        response.EnsureSuccessStatusCode();
        var candidate = (await response.Content.ReadFromJsonAsync<AuthResponseDto>())!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", candidate.Token);
        return (client, candidate);
    }

    [Fact]
    public async Task WithdrawnApplicationRetainsHistoryButIsNotActive_AndCannotReapply()
    {
        using var factory = new IsolationApiFactory();
        var (a, candidate) = await Register(factory, "withdrawA");
        var (b, _) = await Register(factory, "withdrawB");
        using var clientA = a; using var clientB = b;
        factory.CompleteProfile(candidate.CandidateId!.Value);
        var submitted = await Json(await a.PostAsync($"/api/vacancies/{factory.VacancyId}/apply", null));
        var id = submitted.GetProperty("id").GetInt32();
        Assert.True(await HasApplied(a, factory.VacancyId));
        (await a.PostAsync($"/api/applications/{id}/evaluate-match", null)).EnsureSuccessStatusCode();
        (await a.PostAsync($"/api/applications/{id}/withdraw", null)).EnsureSuccessStatusCode();
        Assert.False(await HasApplied(a, factory.VacancyId));
        Assert.False(await HasApplied(b, factory.VacancyId));
        var detail = await Get(a, $"/api/vacancies/{factory.VacancyId}");
        Assert.Equal("WITHDRAWN", detail.GetProperty("currentApplicationStatus").GetString());
        var listed = Assert.Single((await Get(a, "/api/vacancies")).GetProperty("items").EnumerateArray());
        Assert.Equal("WITHDRAWN", listed.GetProperty("currentApplicationStatus").GetString());
        Assert.False((await Get(b, $"/api/vacancies/{factory.VacancyId}")).TryGetProperty("currentApplicationStatus", out _));
        Assert.Equal(HttpStatusCode.BadRequest, (await a.PostAsync($"/api/vacancies/{factory.VacancyId}/apply", null)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await b.GetAsync($"/api/applications/{id}")).StatusCode);
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var app = Assert.Single(db.Applications);
        Assert.Equal("WITHDRAWN", app.Status);
        Assert.Equal(75, app.MatchScore);
        Assert.Contains(db.ApplicationStatusHistories, h => h.ApplicationId == id && h.Status == "WITHDRAWN");
        Assert.Single(db.AIWorkflows);
    }

    [Fact]
    public async Task CompletenessReadsPersistedRequirements_AndIsIsolated()
    {
        using var factory = new IsolationApiFactory();
        var (a, candidate) = await Register(factory, "profileA");
        var (b, other) = await Register(factory, "profileB");
        using var clientA = a; using var clientB = b;
        var id = candidate.CandidateId!.Value;
        async Task Check(int completed)
        {
            var score = await Get(a, $"/api/candidates/{id}/completeness");
            Assert.Equal((int)Math.Round(completed / 6.0 * 100), score.GetProperty("completionPercentage").GetInt32());
            Assert.Equal(completed == 6, score.GetProperty("isComplete").GetBoolean());
            Assert.Equal(completed, score.GetProperty("completedFields").GetArrayLength());
            Assert.Equal(6 - completed, score.GetProperty("missingFields").GetArrayLength());
        }
        void Change(Action<Candidate> change)
        {
            using var scope = factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var c = db.Candidates.Include(c => c.CandidateSkills).Include(c => c.Educations).Include(c => c.CVDocuments).Single(c => c.Id == id);
            change(c); db.SaveChanges();
        }
        Change(c => { c.Phone = ""; c.City = ""; c.Bio = ""; });
        await Check(0);
        Change(c => { c.Phone = "0771234567"; c.City = "Colombo"; c.Bio = "Medical student"; });
        await Check(3);
        Change(c => c.CandidateSkills.Add(new CandidateSkill { Skill = new Skill { Name = "Cardiology", Category = "Medicine" } }));
        await Check(4);
        Change(c => c.Educations.Add(new Education { Institution = "University of Colombo", Degree = "MBBS", FieldOfStudy = "Cardiology", StartYear = 2022, EndYear = 2026 }));
        await Check(5);
        Change(c => c.CVDocuments.Add(new CVDocument { FileName = "medical.pdf", FilePath = "uploads/medical.pdf" }));
        await Check(6);
        Change(c => c.Phone = " ");
        await Check(5);
        Change(c => c.CVDocuments.Clear());
        await Check(4);
        Assert.Equal(HttpStatusCode.Forbidden, (await b.GetAsync($"/api/candidates/{id}/completeness")).StatusCode);
        var otherScore = await Get(b, $"/api/candidates/{other.CandidateId}/completeness");
        Assert.False(otherScore.GetProperty("isComplete").GetBoolean());
        Assert.Contains(otherScore.GetProperty("missingFields").EnumerateArray(), x => x.GetString() == "Skills");
    }

    [Fact]
    public async Task ZeroScoreAndEvidenceArePersistedAlongsidePendingStatus_AndRemainAfterWithdrawal()
    {
        using var factory = new IsolationApiFactory();
        var (a, candidate) = await Register(factory, "evaluationA");
        var (b, _) = await Register(factory, "evaluationB");
        using var owner = a; using var other = b;
        factory.CompleteProfile(candidate.CandidateId!.Value);
        factory.Ai.Score = 0;
        var submitted = await Json(await a.PostAsync($"/api/vacancies/{factory.VacancyId}/apply", null));
        var id = submitted.GetProperty("id").GetInt32();
        Assert.False((await Get(a, $"/api/applications/{id}")).TryGetProperty("evaluation", out _));
        (await a.PostAsync($"/api/applications/{id}/evaluate-match", null)).EnsureSuccessStatusCode();
        var detail = await Get(a, $"/api/applications/{id}");
        Assert.Equal("PENDING_RECRUITER_APPROVAL", detail.GetProperty("status").GetString());
        Assert.Equal(0, detail.GetProperty("evaluation").GetProperty("matchScore").GetDouble());
        Assert.Equal("React", Assert.Single(detail.GetProperty("evaluation").GetProperty("evidence").GetProperty("missing_required_skills").EnumerateArray()).GetString());
        var listed = Assert.Single((await Get(a, "/api/applications/me")).EnumerateArray());
        Assert.Equal(detail.GetProperty("evaluation").GetRawText(), listed.GetProperty("evaluation").GetRawText());
        Assert.Empty((await Get(b, "/api/applications/me")).EnumerateArray());
        Assert.Equal(HttpStatusCode.NotFound, (await b.GetAsync($"/api/applications/{id}")).StatusCode);
        (await a.PostAsync($"/api/applications/{id}/withdraw", null)).EnsureSuccessStatusCode();
        var withdrawn = await Get(a, $"/api/applications/{id}");
        Assert.Equal("WITHDRAWN", withdrawn.GetProperty("status").GetString());
        Assert.Equal(detail.GetProperty("evaluation").GetRawText(), withdrawn.GetProperty("evaluation").GetRawText());
        Assert.Equal(HttpStatusCode.BadRequest, (await a.PostAsync($"/api/applications/{id}/evaluate-match", null)).StatusCode);
        Assert.Single(factory.Ai.Requests);
    }

    [Fact]
    public async Task WithdrawalDuringEvaluationCannotBeReactivatedByLateAiResponse()
    {
        using var factory = new IsolationApiFactory();
        var (a, candidate) = await Register(factory, "lateEvaluation");
        using var owner = a;
        factory.CompleteProfile(candidate.CandidateId!.Value);
        var submitted = await Json(await a.PostAsync($"/api/vacancies/{factory.VacancyId}/apply", null));
        var id = submitted.GetProperty("id").GetInt32();
        factory.Ai.BeforeResponse = async () =>
            (await a.PostAsync($"/api/applications/{id}/withdraw", null)).EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.Conflict, (await a.PostAsync($"/api/applications/{id}/evaluate-match", null)).StatusCode);
        var detail = await Get(a, $"/api/applications/{id}");
        Assert.Equal("WITHDRAWN", detail.GetProperty("status").GetString());
        Assert.False(detail.TryGetProperty("evaluation", out _));
        Assert.False(await HasApplied(a, factory.VacancyId));
        using var scope = factory.Services.CreateScope();
        Assert.Empty(scope.ServiceProvider.GetRequiredService<ApplicationDbContext>().AIWorkflows);
    }

    [Fact]
    public async Task CandidateShortlistsScopeBothContainersAndRecommendations_FromAuthenticatedIdentity()
    {
        using var factory = new IsolationApiFactory();
        var (a, candidateA) = await Register(factory, "shortlistA");
        var (b, candidateB) = await Register(factory, "shortlistB");
        var (c, _) = await Register(factory, "shortlistC");
        using var ownerA = a; using var ownerB = b; using var newCandidate = c;
        int shortlistId;
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var shortlist = new Shortlist { Title = "Shared shortlist", VacancyId = factory.VacancyId };
            shortlist.Recommendations.Add(new Recommendation { Application = new Application { CandidateId = candidateA.CandidateId!.Value, VacancyId = factory.VacancyId }, CalculatedScore = 0 });
            shortlist.Recommendations.Add(new Recommendation { Application = new Application { CandidateId = candidateB.CandidateId!.Value, VacancyId = factory.VacancyId }, CalculatedScore = 75 });
            db.Shortlists.Add(shortlist); db.SaveChanges(); shortlistId = shortlist.Id;
        }
        foreach (var (client, candidate) in new[] { (a, candidateA), (b, candidateB) })
        {
            var list = await Get(client, $"/api/shortlists/me?candidateId={candidateB.CandidateId}&email=spoof@example.test");
            var shortlist = Assert.Single(list.EnumerateArray());
            var recommendation = Assert.Single(shortlist.GetProperty("recommendations").EnumerateArray());
            Assert.Equal(candidate.CandidateId, recommendation.GetProperty("candidateId").GetInt32());
            var detail = await Get(client, $"/api/shortlists/me/{shortlistId}");
            Assert.Equal(candidate.CandidateId, Assert.Single(detail.GetProperty("recommendations").EnumerateArray()).GetProperty("candidateId").GetInt32());
            Assert.Equal(HttpStatusCode.Forbidden, (await client.GetAsync($"/api/shortlists/{shortlistId}")).StatusCode);
        }
        Assert.Empty((await Get(c, "/api/shortlists/me")).EnumerateArray());
        Assert.Equal(HttpStatusCode.NotFound, (await c.GetAsync($"/api/shortlists/me/{shortlistId}")).StatusCode);
        using var missingProfile = factory.StaffClient("Candidate");
        Assert.Empty((await Get(missingProfile, $"/api/shortlists/me?candidateId={candidateA.CandidateId}")).EnumerateArray());
        using var staff = factory.StaffClient();
        Assert.Equal(2, (await Get(staff, $"/api/shortlists/{shortlistId}")).GetProperty("recommendations").GetArrayLength());
        using var anonymous = factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.GetAsync("/api/shortlists/me")).StatusCode);
    }

    private static async Task<bool> HasApplied(HttpClient client, int vacancyId)
    {
        var vacancies = await Get(client, "/api/vacancies");
        Assert.Equal(JsonValueKind.Object, vacancies.ValueKind);
        var items = vacancies.GetProperty("items");
        Assert.Equal(JsonValueKind.Array, items.ValueKind);
        var vacancy = Assert.Single(items.EnumerateArray(), v => v.GetProperty("id").GetInt32() == vacancyId);
        Assert.False(vacancy.TryGetProperty("applications", out _));
        return vacancy.GetProperty("hasApplied").GetBoolean();
    }

    private static async Task<JsonElement> Get(HttpClient client, string path)
    {
        var response = await client.GetAsync(path);
        response.EnsureSuccessStatusCode();
        return await Json(response);
    }

    private static async Task<JsonElement> Json(HttpResponseMessage response) =>
        JsonDocument.Parse(await response.Content.ReadAsStringAsync()).RootElement.Clone();
}

internal sealed class IsolationApiFactory : WebApplicationFactory<Program>
{
    private readonly SqliteConnection _connection = new("Data Source=:memory:");
    public StubAiHandler Ai { get; } = new();
    public int VacancyId { get; private set; }
    public int StaffUserId { get; private set; }

    public IsolationApiFactory() => _connection.Open();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.ConfigureTestServices(services =>
        {
            services.RemoveAll<DbContextOptions<ApplicationDbContext>>();
            services.AddSingleton(new DbContextOptionsBuilder<ApplicationDbContext>().UseSqlite(_connection).Options);
            services.RemoveAll<IDbInitializer>();
            services.AddScoped<IDbInitializer, EmptyInitializer>();
            services.RemoveAll<IHttpClientFactory>();
            services.AddSingleton<IHttpClientFactory>(new StubAiFactory(Ai));
        });
    }

    protected override Microsoft.Extensions.Hosting.IHost CreateHost(Microsoft.Extensions.Hosting.IHostBuilder builder)
    {
        var host = base.CreateHost(builder);
        using var scope = host.Services.CreateScope();
        scope.ServiceProvider.GetRequiredService<ApplicationDbContext>().Database.EnsureCreated();
        // Seed a non-candidate user first so User.Id and Candidate.Id cannot accidentally coincide.
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var staff = new User { FullName = "Recruiter", Email = "recruiter@isolation.test", Role = "Recruiter", PasswordHash = "unused" };
        var vacancy = new Vacancy { Title = "Software Engineering Intern", Company = new Company { Name = "Test Company" }, IsActive = true };
        db.Users.Add(staff);
        db.Vacancies.Add(vacancy);
        db.SaveChanges();
        StaffUserId = staff.Id;
        VacancyId = vacancy.Id;
        return host;
    }

    public HttpClient StaffClient(string role = "Recruiter")
    {
        _ = Services; // Initialize the isolated host and its seed fixture.
        return AuthenticatedClient(new User { Id = StaffUserId, FullName = "Staff", Email = "staff@isolation.test", Role = role });
    }

    public void CompleteProfile(int id)
    {
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var candidate = db.Candidates.Find(id)!;
        candidate.IsProfileComplete = true;
        candidate.Phone = "0771234567"; candidate.City = "Colombo"; candidate.Bio = "Medical student";
        candidate.CandidateSkills.Add(new CandidateSkill { Skill = new Skill { Name = $"Cardiology {id}", Category = "Medicine" } });
        candidate.Educations.Add(new Education { Institution = "University of Colombo", Degree = "MBBS", FieldOfStudy = "Cardiology", StartYear = 2022, EndYear = 2026 });
        candidate.CVDocuments.Add(new CVDocument { FileName = "profile.pdf", FilePath = $"uploads/{id}.pdf" });
        db.SaveChanges();
    }

    public void SeedOtherCandidatesInterview()
    {
        _ = Services; // Initialize the isolated host and its seed fixture.
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        db.Interviews.Add(new Interview
        {
            Application = new Application
            {
                VacancyId = VacancyId, Status = "APPROVED",
                Candidate = new Candidate { User = new User { FullName = "Existing Candidate", Email = "existing@isolation.test", Role = "Candidate", PasswordHash = "unused" } }
            },
            ScheduledTime = DateTime.UtcNow.AddDays(1), Status = "CONFIRMED"
        });
        db.SaveChanges();
    }

    public HttpClient InterviewerClient(bool assigned)
    {
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var interviewer = new Interviewer { User = new User { FullName = "Interviewer", Email = $"interviewer-{assigned}@isolation.test", Role = "Interviewer", PasswordHash = "unused" } };
        db.Interviewers.Add(interviewer);
        db.SaveChanges();
        if (assigned) { db.Interviews.Single().InterviewerId = interviewer.Id; db.SaveChanges(); }
        return AuthenticatedClient(interviewer.User);
    }

    private HttpClient AuthenticatedClient(User user)
    {
        using var scope = Services.CreateScope();
        var token = scope.ServiceProvider.GetRequiredService<IJwtTokenService>().GenerateToken(user);
        var client = CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return client;
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        if (disposing) _connection.Dispose();
    }

    private sealed class EmptyInitializer : IDbInitializer { public void Initialize() { } }
    private sealed class StubAiFactory(StubAiHandler handler) : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => new(handler, disposeHandler: false);
    }
}

internal sealed class StubAiHandler : HttpMessageHandler
{
    public double Score { get; set; } = 75;
    public Func<Task>? BeforeResponse { get; set; }
    public bool Offline { get; set; }
    public bool MissingScore { get; set; }
    public List<string> Requests { get; } = new();
    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        Requests.Add(await request.Content!.ReadAsStringAsync(cancellationToken));
        if (Offline) throw new HttpRequestException("Test AI service is offline.");
        if (BeforeResponse != null) await BeforeResponse();
        return new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(MissingScore ? "{}" : JsonSerializer.Serialize(new {
                workflow_id = "test-workflow", plan = new {},
                match_result = new { match_score = Score, missing_required_skills = new[] { "React" }, matched_required_skills = Array.Empty<string>() },
                requires_human_approval = true
            }), Encoding.UTF8, "application/json")
        };
    }
}
