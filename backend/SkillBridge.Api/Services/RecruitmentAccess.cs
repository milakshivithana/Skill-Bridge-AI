using System.Security.Claims;
using SkillBridge.Api.Data;
using SkillBridge.Api.Models;

namespace SkillBridge.Api.Services;

public static class RecruitmentAccess
{
    public static int? UserId(ClaimsPrincipal user) =>
        int.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : null;

    public static bool IsStaff(ClaimsPrincipal user) =>
        user.IsInRole("Recruiter") || user.IsInRole("Administrator");

    public static int? CandidateId(ApplicationDbContext db, ClaimsPrincipal user)
    {
        if (user.Identity?.IsAuthenticated != true || !user.IsInRole("Candidate")) return null;
        var userId = UserId(user);
        return db.Candidates.Where(c => c.UserId == userId).Select(c => (int?)c.Id).SingleOrDefault();
    }

    public static IQueryable<Application> Applications(ApplicationDbContext db, ClaimsPrincipal user)
    {
        if (user.Identity?.IsAuthenticated != true) return db.Applications.Where(a => false);
        if (IsStaff(user)) return db.Applications;
        var candidateId = CandidateId(db, user);
        return db.Applications.Where(a => candidateId != null && a.CandidateId == candidateId);
    }

    public static IQueryable<Interview> Interviews(ApplicationDbContext db, ClaimsPrincipal user)
    {
        if (user.Identity?.IsAuthenticated != true) return db.Interviews.Where(i => false);
        if (IsStaff(user)) return db.Interviews;
        if (user.IsInRole("Interviewer"))
        {
            var userId = UserId(user);
            return db.Interviews.Where(i => i.Interviewer != null && i.Interviewer.UserId == userId);
        }
        var candidateId = CandidateId(db, user);
        return db.Interviews.Where(i => candidateId != null && i.Application != null &&
            i.Application.CandidateId == candidateId);
    }
}
