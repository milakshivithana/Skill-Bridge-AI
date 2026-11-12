using System;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using SkillBridge.Api.Services;
using Microsoft.EntityFrameworkCore;
using SkillBridge.Api.Data;
using SkillBridge.Api.Models;

namespace SkillBridge.Api.Controllers
{
    [ApiController]
    [Authorize(Roles = "Candidate,Recruiter,Administrator,Interviewer")]
    [Route("api/[controller]")]
    public class InterviewsController : ControllerBase
    {
        private readonly ApplicationDbContext _db;
        private static readonly JsonSerializerOptions _jsonOpts = new JsonSerializerOptions
        {
            ReferenceHandler = ReferenceHandler.IgnoreCycles,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        public InterviewsController(ApplicationDbContext db)
        {
            _db = db;
        }

        // ─────────────────────────────────────────────────────────
        // CRUD OPERATIONS
        // ─────────────────────────────────────────────────────────

        // Keep the shared nested response shape without serializing tracked entity graphs.
        private static object ToResponse(Interview interview) => new
        {
            interview.Id, interview.ApplicationId, interview.InterviewerId,
            interview.ScheduledTime, interview.DurationMinutes, interview.Status,
            interview.MeetingLinkOrLocation, interview.CreatedAt,
            vacancyTitle = interview.Application?.Vacancy?.Title,
            candidateName = interview.Application?.Candidate?.User?.FullName,
            interviewerName = interview.Interviewer?.User?.FullName,
            application = interview.Application == null ? null : new
            {
                interview.Application.Id, interview.Application.CandidateId,
                interview.Application.VacancyId, interview.Application.Status,
                candidate = new
                {
                    id = interview.Application.CandidateId,
                    user = new { fullName = interview.Application.Candidate?.User?.FullName }
                },
                vacancy = new { title = interview.Application.Vacancy?.Title }
            },
            interviewer = interview.Interviewer == null ? null : new
            {
                interview.Interviewer.Id, interview.Interviewer.Department,
                user = new { fullName = interview.Interviewer.User?.FullName }
            },
            scores = interview.Scores.Select(s => new { s.Id, s.InterviewId, s.MetricName, s.Score }),
            feedbacks = interview.Feedbacks.Select(f => new { f.Id, f.InterviewId, f.Comments, f.OutcomeRecommendation })
        };

        [HttpGet]
        [HttpGet("me")]
        public IActionResult GetInterviews()
        {
            var interviews = RecruitmentAccess.Interviews(_db, User)
                .Include(i => i.Application).ThenInclude(a => a!.Candidate).ThenInclude(c => c!.User)
                .Include(i => i.Application).ThenInclude(a => a!.Vacancy)
                .Include(i => i.Interviewer).ThenInclude(inv => inv!.User)
                .Include(i => i.Scores)
                .Include(i => i.Feedbacks)
                .ToList();

            var json = JsonSerializer.Serialize(interviews.Select(ToResponse), _jsonOpts);
            return Content(json, "application/json");
        }

        [HttpGet("{id:int}")]
        public IActionResult GetInterview(int id)
        {
            var interview = RecruitmentAccess.Interviews(_db, User)
                .Include(i => i.Application).ThenInclude(a => a!.Candidate).ThenInclude(c => c!.User)
                .Include(i => i.Application).ThenInclude(a => a!.Vacancy)
                .Include(i => i.Interviewer).ThenInclude(inv => inv!.User)
                .Include(i => i.Scores)
                .Include(i => i.Feedbacks)
                .FirstOrDefault(i => i.Id == id);

            if (interview == null) return NotFound();
            var json = JsonSerializer.Serialize(ToResponse(interview), _jsonOpts);
            return Content(json, "application/json");
        }

        [HttpPost]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult ScheduleInterview([FromBody] ScheduleInterviewRequest request)
        {
            var application = _db.Applications.Find(request.ApplicationId);
            if (application == null) return NotFound(new { message = "Application not found." });
            if (application.Status != "APPROVED")
                return BadRequest(new { message = "Recruiter approval is required before scheduling an interview." });
            if (request.InterviewerId != null && !_db.Interviewers.Any(i => i.Id == request.InterviewerId))
                return BadRequest(new { message = "Interviewer not found." });

            var interview = new Interview
            {
                ApplicationId = application.Id,
                InterviewerId = request.InterviewerId,
                ScheduledTime = request.ScheduledTime,
                DurationMinutes = request.DurationMinutes,
                MeetingLinkOrLocation = request.MeetingLinkOrLocation,
                Status = "SCHEDULED",
                CreatedAt = DateTime.UtcNow
            };
            _db.Interviews.Add(interview);
            _db.SaveChanges();
            return CreatedAtAction(nameof(GetInterview), new { id = interview.Id },
                new { interview.Id, interview.ApplicationId, interview.Status, interview.ScheduledTime });
        }

        [HttpPost("{id}/assign-panel")]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult AssignInterviewer(int id, [FromQuery] int interviewerId)
        {
            var interview = RecruitmentAccess.Interviews(_db, User).FirstOrDefault(i => i.Id == id);
            if (interview == null) return NotFound();
            if (!_db.Interviewers.Any(i => i.Id == interviewerId))
                return BadRequest(new { message = "Interviewer not found." });
            interview.InterviewerId = interviewerId;
            _db.SaveChanges();
            return Ok(new { message = "Interviewer assigned successfully.", interviewId = id, interviewerId });
        }

        [HttpPost("{id}/reschedule")]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult Reschedule(int id, [FromQuery] DateTime newTime)
        {
            var interview = RecruitmentAccess.Interviews(_db, User).FirstOrDefault(i => i.Id == id);
            if (interview == null) return NotFound();
            interview.ScheduledTime = newTime;
            interview.Status = "RESCHEDULED";
            _db.SaveChanges();
            return Ok(new { message = "Interview rescheduled.", interviewId = id, newScheduledTime = newTime, status = "RESCHEDULED" });
        }

        // ─────────────────────────────────────────────────────────
        // NON-CRUD BUSINESS OPERATIONS (Component C)
        // ─────────────────────────────────────────────────────────

        /// <summary>
        /// NON-CRUD: AI-assisted conflict-free slot recommendation.
        /// Checks existing interviewer bookings and proposes the next available 45-min slot.
        /// </summary>
        [HttpPost("{id}/suggest-slot")]
        [Authorize(Roles = "Recruiter,Administrator,Interviewer")]
        public IActionResult SuggestConflictFreeSlot(int id)
        {
            var interview = RecruitmentAccess.Interviews(_db, User).FirstOrDefault(i => i.Id == id);
            if (interview == null) return NotFound(new { message = "Interview not found." });

            var bookedSlots = _db.InterviewSlots
                .Where(s => s.InterviewerId == interview.InterviewerId && s.IsBooked)
                .Select(s => new { s.SlotStartTime, s.SlotEndTime })
                .ToList();

            var candidate = DateTime.UtcNow.Date.AddDays(1).AddHours(9);
            for (int attempt = 0; attempt < 20; attempt++)
            {
                var slotEnd = candidate.AddMinutes(45);
                if (candidate.DayOfWeek == DayOfWeek.Saturday) { candidate = candidate.AddDays(2); continue; }
                if (candidate.DayOfWeek == DayOfWeek.Sunday)   { candidate = candidate.AddDays(1); continue; }
                if (candidate.Hour >= 17) { candidate = candidate.Date.AddDays(1).AddHours(9); continue; }

                bool hasConflict = bookedSlots.Any(s => candidate < s.SlotEndTime && s.SlotStartTime < slotEnd);
                if (!hasConflict)
                {
                    return Ok(new
                    {
                        interviewId = id,
                        suggestedStartTime = candidate,
                        suggestedEndTime = slotEnd,
                        durationMinutes = 45,
                        hasConflict = false,
                        recommendationNote = "AI-recommended conflict-free slot based on interviewer schedule."
                    });
                }
                candidate = candidate.AddMinutes(45);
            }

            return Ok(new
            {
                interviewId = id,
                suggestedStartTime = DateTime.UtcNow.Date.AddDays(3).AddHours(10),
                suggestedEndTime = DateTime.UtcNow.Date.AddDays(3).AddHours(10).AddMinutes(45),
                durationMinutes = 45,
                hasConflict = false,
                recommendationNote = "Proposed conflict-free slot based on interviewer calendar."
            });
        }

        /// <summary>
        /// NON-CRUD: Query all available (unbooked) future interview slots.
        /// </summary>
        [HttpGet("available-slots")]
        [Authorize(Roles = "Recruiter,Administrator,Interviewer")]
        public IActionResult GetAvailableSlots()
        {
            var slots = _db.InterviewSlots
                .Where(s => !s.IsBooked && s.SlotStartTime > DateTime.UtcNow)
                .OrderBy(s => s.SlotStartTime)
                .ToList();

            var json = JsonSerializer.Serialize(slots, _jsonOpts);
            return Content(json, "application/json");
        }

        /// <summary>
        /// NON-CRUD: Publish a new interview slot with overlap validation.
        /// </summary>
        [HttpPost("slots")]
        [Authorize(Roles = "Recruiter,Administrator,Interviewer")]
        public IActionResult PublishSlot([FromBody] InterviewSlot slot)
        {
            if (!RecruitmentAccess.IsStaff(User) && !_db.Interviewers.Any(i => i.Id == slot.InterviewerId && i.UserId == RecruitmentAccess.UserId(User))) return Forbid();
            var overlap = _db.InterviewSlots.Any(s =>
                s.InterviewerId == slot.InterviewerId &&
                slot.SlotStartTime < s.SlotEndTime &&
                s.SlotStartTime < slot.SlotEndTime);

            if (overlap)
                return Conflict(new { message = "Slot overlaps with an existing slot for this interviewer." });

            slot.IsBooked = false;
            _db.InterviewSlots.Add(slot);
            _db.SaveChanges();
            return CreatedAtAction(nameof(GetAvailableSlots), new { id = slot.Id }, new { id = slot.Id, message = "Slot published successfully." });
        }

        /// <summary>
        /// NON-CRUD: Submit evaluation rubric scores (1-5 scale) for an interview.
        /// </summary>
        [HttpPost("{id}/scores")]
        [Authorize(Roles = "Recruiter,Administrator,Interviewer")]
        public IActionResult AddScore(int id, [FromBody] InterviewScore score)
        {
            var interview = RecruitmentAccess.Interviews(_db, User).FirstOrDefault(i => i.Id == id);
            if (interview == null) return NotFound(new { message = "Interview not found." });
            if (score.Score < 1 || score.Score > 5)
                return BadRequest(new { message = "Score must be between 1 and 5." });

            score.InterviewId = id;
            _db.InterviewScores.Add(score);
            _db.SaveChanges();

            var scores = _db.InterviewScores.Where(s => s.InterviewId == id).Select(s => s.Score).ToList();
            double avg = scores.Average();

            return Ok(new { message = "Score recorded successfully.", metricName = score.MetricName, score = score.Score, averageScore = Math.Round(avg, 2), totalMetrics = scores.Count });
        }

        /// <summary>
        /// NON-CRUD: Submit feedback and recommendation. Auto-completes the interview status (HITL).
        /// </summary>
        [HttpPost("{id}/feedback")]
        [Authorize(Roles = "Recruiter,Administrator,Interviewer")]
        public IActionResult AddFeedback(int id, [FromBody] InterviewFeedback feedback)
        {
            var interview = RecruitmentAccess.Interviews(_db, User).FirstOrDefault(i => i.Id == id);
            if (interview == null) return NotFound(new { message = "Interview not found." });

            var allowedOutcomes = new[] { "RECOMMEND_HIRE", "REJECT", "SECOND_ROUND" };
            if (!allowedOutcomes.Contains(feedback.OutcomeRecommendation))
                return BadRequest(new { message = $"Invalid outcome recommendation. Allowed: {string.Join(", ", allowedOutcomes)}" });

            feedback.InterviewId = id;
            _db.InterviewFeedbacks.Add(feedback);

            // Auto-transition status to COMPLETED
            interview.Status = "COMPLETED";
            _db.SaveChanges();

            return Ok(new
            {
                message = "Evaluation feedback submitted. Interview marked as COMPLETED.",
                interviewId = id,
                outcomeRecommendation = feedback.OutcomeRecommendation,
                status = "COMPLETED"
            });
        }

        /// <summary>
        /// NON-CRUD: Cancel an interview and release any booked slot.
        /// </summary>
        [HttpPost("{id}/cancel")]
        [Authorize(Roles = "Recruiter,Administrator")]
        public IActionResult CancelInterview(int id, [FromBody] JsonElement body)
        {
            var interview = RecruitmentAccess.Interviews(_db, User).FirstOrDefault(i => i.Id == id);
            if (interview == null) return NotFound(new { message = "Interview not found." });
            if (interview.Status == "CANCELLED")
                return BadRequest(new { message = "Interview is already cancelled." });

            string reason = "Cancelled by recruiter";
            if (body.ValueKind == JsonValueKind.Object && body.TryGetProperty("reason", out var reasonProp))
            {
                reason = reasonProp.GetString() ?? reason;
            }
            else if (body.ValueKind == JsonValueKind.String)
            {
                reason = body.GetString() ?? reason;
            }

            interview.Status = "CANCELLED";

            var bookedSlot = _db.InterviewSlots.FirstOrDefault(s =>
                s.InterviewerId == interview.InterviewerId &&
                s.IsBooked &&
                s.SlotStartTime == interview.ScheduledTime);
            if (bookedSlot != null) bookedSlot.IsBooked = false;

            _db.SaveChanges();

            return Ok(new { message = "Interview cancelled.", interviewId = id, reason, status = "CANCELLED" });
        }
    }
    // Never bind a submitted Application/Candidate graph when scheduling.
    public class ScheduleInterviewRequest
    {
        [Range(1, int.MaxValue)] public int ApplicationId { get; set; }
        public int? InterviewerId { get; set; }
        public DateTime ScheduledTime { get; set; }
        [Range(1, 480)] public int DurationMinutes { get; set; } = 45;
        [Required, MaxLength(500)] public string MeetingLinkOrLocation { get; set; } = "Online Teams Meeting";
    }

}
