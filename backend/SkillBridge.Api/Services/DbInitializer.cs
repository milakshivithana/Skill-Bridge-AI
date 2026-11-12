using System;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using SkillBridge.Api.Data;
using SkillBridge.Api.Models;

namespace SkillBridge.Api.Services
{
    public interface IDbInitializer
    {
        void Initialize();
    }

    public class DbInitializer : IDbInitializer
    {
        private readonly ApplicationDbContext _db;

        public DbInitializer(ApplicationDbContext db)
        {
            _db = db;
        }

        public void Initialize()
        {
            try
            {
                if (_db.Database.IsNpgsql())
                {
                    _db.Database.Migrate();
                }
                else
                {
                    _db.Database.EnsureCreated();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Database Migration Notice: {ex.Message}. Ensuring DB created.");
                _db.Database.EnsureCreated();
            }

            if (_db.Users.Any())
            {
                return; // DB already seeded with data
            }

            // Create Skills Taxonomy
            var reactSkill = new Skill { Name = "React", Category = "Framework" };
            var csharpSkill = new Skill { Name = "C#", Category = "Programming" };
            var sqlSkill = new Skill { Name = "SQL", Category = "Database" };
            var gitSkill = new Skill { Name = "Git", Category = "Tool" };
            var dockerSkill = new Skill { Name = "Docker", Category = "DevOps" };
            var pythonSkill = new Skill { Name = "Python", Category = "Programming" };
            var flutterSkill = new Skill { Name = "Flutter", Category = "Mobile" };

            _db.Skills.AddRange(reactSkill, csharpSkill, sqlSkill, gitSkill, dockerSkill, pythonSkill, flutterSkill);
            _db.SaveChanges();

            // Password hashing helper
            string HashPassword(string password)
            {
                using var sha256 = SHA256.Create();
                var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
                return Convert.ToBase64String(bytes);
            }

            // Default Users for Viva Demo & Testing
            var adminUser = new User
            {
                FullName = "System Administrator",
                Email = "admin@skillbridge.lk",
                PasswordHash = HashPassword("Admin123!"),
                Role = "Administrator"
            };

            var recruiterUser = new User
            {
                FullName = "Sarah Jenkins (Recruiter)",
                Email = "recruiter@techcorp.com",
                PasswordHash = HashPassword("Recruiter123!"),
                Role = "Recruiter"
            };

            var candidateUser = new User
            {
                FullName = "Candidate 102",
                Email = "candidate102@student.sliit.lk",
                PasswordHash = HashPassword("Candidate123!"),
                Role = "Candidate"
            };

            var interviewerUser = new User
            {
                FullName = "Dr. Aruni Silva (Interviewer)",
                Email = "interviewer@techcorp.com",
                PasswordHash = HashPassword("Interviewer123!"),
                Role = "Interviewer"
            };

            _db.Users.AddRange(adminUser, recruiterUser, candidateUser, interviewerUser);
            _db.SaveChanges();

            // Candidate Profile
            var candidateProfile = new Candidate
            {
                UserId = candidateUser.Id,
                Phone = "+94771234567",
                City = "Colombo",
                Bio = "Undergraduate student specializing in Software Engineering.",
                IsProfileComplete = true
            };
            _db.Candidates.Add(candidateProfile);

            // Interviewer Profile
            var interviewerProfile = new Interviewer
            {
                UserId = interviewerUser.Id,
                Department = "Software Architecture"
            };
            _db.Interviewers.Add(interviewerProfile);
            _db.SaveChanges();

            // Candidate Skills
            _db.CandidateSkills.AddRange(
                new CandidateSkill { CandidateId = candidateProfile.Id, SkillId = reactSkill.Id, ProficiencyLevel = "Expert" },
                new CandidateSkill { CandidateId = candidateProfile.Id, SkillId = csharpSkill.Id, ProficiencyLevel = "Intermediate" },
                new CandidateSkill { CandidateId = candidateProfile.Id, SkillId = sqlSkill.Id, ProficiencyLevel = "Intermediate" },
                new CandidateSkill { CandidateId = candidateProfile.Id, SkillId = gitSkill.Id, ProficiencyLevel = "Intermediate" }
            );

            // Companies
            var company1 = new Company
            {
                Name = "TechCorp Solutions",
                Industry = "Software Development",
                Location = "Colombo 03",
                Website = "https://techcorp.com"
            };
            var company2 = new Company
            {
                Name = "CloudNation Technologies",
                Industry = "Cloud & DevOps Solutions",
                Location = "Kandy / Remote",
                Website = "https://cloudnation.io"
            };

            _db.Companies.AddRange(company1, company2);
            _db.SaveChanges();

            // Vacancies
            var vacancy1 = new Vacancy
            {
                CompanyId = company1.Id,
                Title = "Software Engineering Intern",
                Description = "Seeking a driven intern proficient in React, SQL, and Git. Knowledge of C# and Docker is preferred. You will work on full-stack web applications.",
                Location = "Colombo",
                EmploymentType = "Internship",
                IsActive = true,
                ApplicationDeadline = DateTime.UtcNow.AddDays(25)
            };

            var vacancy2 = new Vacancy
            {
                CompanyId = company1.Id,
                Title = "Frontend Developer Intern (React)",
                Description = "Join our web app team focusing on modern React, TypeScript, and state management. Great learning environment!",
                Location = "Colombo",
                EmploymentType = "Internship",
                IsActive = true,
                ApplicationDeadline = DateTime.UtcNow.AddDays(15)
            };

            var vacancy3 = new Vacancy
            {
                CompanyId = company2.Id,
                Title = "Backend & Cloud Intern (C# / Python)",
                Description = "Hands-on experience building REST APIs with ASP.NET Core, PostgreSQL, and cloud deployments.",
                Location = "Remote",
                EmploymentType = "PartTime",
                IsActive = true,
                ApplicationDeadline = DateTime.UtcNow.AddDays(40)
            };

            _db.Vacancies.AddRange(vacancy1, vacancy2, vacancy3);
            _db.SaveChanges();

            // Vacancy Skills & Requirements
            _db.VacancySkills.AddRange(
                new VacancySkill { VacancyId = vacancy1.Id, SkillId = reactSkill.Id, IsMandatory = true },
                new VacancySkill { VacancyId = vacancy1.Id, SkillId = sqlSkill.Id, IsMandatory = true },
                new VacancySkill { VacancyId = vacancy1.Id, SkillId = gitSkill.Id, IsMandatory = true },
                new VacancySkill { VacancyId = vacancy1.Id, SkillId = dockerSkill.Id, IsMandatory = false },

                new VacancySkill { VacancyId = vacancy2.Id, SkillId = reactSkill.Id, IsMandatory = true },
                new VacancySkill { VacancyId = vacancy2.Id, SkillId = gitSkill.Id, IsMandatory = true },

                new VacancySkill { VacancyId = vacancy3.Id, SkillId = csharpSkill.Id, IsMandatory = true },
                new VacancySkill { VacancyId = vacancy3.Id, SkillId = pythonSkill.Id, IsMandatory = false },
                new VacancySkill { VacancyId = vacancy3.Id, SkillId = sqlSkill.Id, IsMandatory = true }
            );

            _db.VacancyRequirements.AddRange(
                new VacancyRequirement { VacancyId = vacancy1.Id, RequirementText = "Must be currently pursuing a degree in CS or Software Engineering.", IsNonNegotiable = true },
                new VacancyRequirement { VacancyId = vacancy1.Id, RequirementText = "Available for a full-time 6-month internship in Colombo.", IsNonNegotiable = true },
                new VacancyRequirement { VacancyId = vacancy2.Id, RequirementText = "Strong grasp of modern JavaScript / TypeScript.", IsNonNegotiable = true },
                new VacancyRequirement { VacancyId = vacancy3.Id, RequirementText = "Prior coursework in database management and RESTful APIs.", IsNonNegotiable = true }
            );

            _db.SaveChanges();

            // Initial Application for Candidate
            var sampleApp = new Application
            {
                CandidateId = candidateProfile.Id,
                VacancyId = vacancy1.Id,
                Status = "SUBMITTED",
                MatchScore = 84.0,
                EligibilityPassed = true,
                AppliedAt = DateTime.UtcNow.AddDays(-2),
                UpdatedAt = DateTime.UtcNow.AddDays(-2)
            };
            _db.Applications.Add(sampleApp);
            _db.SaveChanges();

            _db.ApplicationStatusHistories.Add(new ApplicationStatusHistory
            {
                ApplicationId = sampleApp.Id,
                Status = "SUBMITTED",
                Notes = "Application submitted by candidate via SkillBridge mobile app.",
                ChangedAt = DateTime.UtcNow.AddDays(-2)
            });

            _db.SavedVacancies.Add(new SavedVacancy
            {
                CandidateId = candidateProfile.Id,
                VacancyId = vacancy2.Id,
                SavedAt = DateTime.UtcNow.AddDays(-1)
            });

            _db.SaveChanges();

            // ==========================================
            // COMPONENT C SEEDING: INTERVIEW & SCHEDULING
            // ==========================================

            // Interviewer Weekly Availability
            _db.Availabilities.AddRange(
                new Availability { InterviewerId = interviewerProfile.Id, DayOfWeek = "Monday", StartTime = new TimeSpan(9, 0, 0), EndTime = new TimeSpan(17, 0, 0) },
                new Availability { InterviewerId = interviewerProfile.Id, DayOfWeek = "Wednesday", StartTime = new TimeSpan(10, 0, 0), EndTime = new TimeSpan(16, 0, 0) },
                new Availability { InterviewerId = interviewerProfile.Id, DayOfWeek = "Friday", StartTime = new TimeSpan(13, 0, 0), EndTime = new TimeSpan(17, 0, 0) }
            );

            // Available Interview Slots
            var slot1 = new InterviewSlot
            {
                InterviewerId = interviewerProfile.Id,
                SlotStartTime = DateTime.UtcNow.Date.AddDays(2).AddHours(10),
                SlotEndTime = DateTime.UtcNow.Date.AddDays(2).AddHours(10).AddMinutes(45),
                IsBooked = false
            };
            var slot2 = new InterviewSlot
            {
                InterviewerId = interviewerProfile.Id,
                SlotStartTime = DateTime.UtcNow.Date.AddDays(3).AddHours(14),
                SlotEndTime = DateTime.UtcNow.Date.AddDays(3).AddHours(14).AddMinutes(45),
                IsBooked = false
            };
            var slot3 = new InterviewSlot
            {
                InterviewerId = interviewerProfile.Id,
                SlotStartTime = DateTime.UtcNow.Date.AddDays(4).AddHours(11),
                SlotEndTime = DateTime.UtcNow.Date.AddDays(4).AddHours(11).AddMinutes(45),
                IsBooked = true
            };
            _db.InterviewSlots.AddRange(slot1, slot2, slot3);
            _db.SaveChanges();

            // Sample Confirmed Interview
            var sampleInterview = new Interview
            {
                ApplicationId = sampleApp.Id,
                InterviewerId = interviewerProfile.Id,
                ScheduledTime = DateTime.UtcNow.Date.AddDays(2).AddHours(15),
                DurationMinutes = 45,
                Status = "CONFIRMED",
                MeetingLinkOrLocation = "https://teams.microsoft.com/l/meetup-join/skillbridge-interview-102",
                CreatedAt = DateTime.UtcNow.AddDays(-1)
            };
            _db.Interviews.Add(sampleInterview);
            _db.SaveChanges();

            // Evaluation Rubric Scores (1-5 scale)
            _db.InterviewScores.AddRange(
                new InterviewScore { InterviewId = sampleInterview.Id, MetricName = "Technical Competency", Score = 4 },
                new InterviewScore { InterviewId = sampleInterview.Id, MetricName = "Problem Solving & Analytical Ability", Score = 5 },
                new InterviewScore { InterviewId = sampleInterview.Id, MetricName = "Communication & Culture Fit", Score = 4 }
            );

            // Interviewer Feedback & Decision
            _db.InterviewFeedbacks.Add(new InterviewFeedback
            {
                InterviewId = sampleInterview.Id,
                Comments = "Candidate demonstrated exceptional proficiency in C# and React. Strong conceptual understanding of microservices architecture.",
                OutcomeRecommendation = "RECOMMEND_HIRE"
            });

            _db.SaveChanges();
        }
    }
}
