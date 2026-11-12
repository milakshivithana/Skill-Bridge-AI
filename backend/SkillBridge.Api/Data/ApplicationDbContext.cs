using Microsoft.EntityFrameworkCore;
using SkillBridge.Api.Models;

namespace SkillBridge.Api.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
        {
        }

        // Identity & Shared
        public DbSet<User> Users { get; set; }

        // Component A
        public DbSet<Candidate> Candidates { get; set; }
        public DbSet<Skill> Skills { get; set; }
        public DbSet<CandidateSkill> CandidateSkills { get; set; }
        public DbSet<Education> Educations { get; set; }
        public DbSet<Experience> Experiences { get; set; }
        public DbSet<Certificate> Certificates { get; set; }
        public DbSet<CVDocument> CVDocuments { get; set; }
        public DbSet<CandidatePreference> CandidatePreferences { get; set; }

        // Component B
        public DbSet<Company> Companies { get; set; }
        public DbSet<Vacancy> Vacancies { get; set; }
        public DbSet<VacancySkill> VacancySkills { get; set; }
        public DbSet<VacancyRequirement> VacancyRequirements { get; set; }
        public DbSet<Application> Applications { get; set; }
        public DbSet<ApplicationStatusHistory> ApplicationStatusHistories { get; set; }
        public DbSet<SavedVacancy> SavedVacancies { get; set; }

        // Component C
        public DbSet<Interviewer> Interviewers { get; set; }
        public DbSet<Interview> Interviews { get; set; }
        public DbSet<InterviewSlot> InterviewSlots { get; set; }
        public DbSet<Availability> Availabilities { get; set; }
        public DbSet<InterviewScore> InterviewScores { get; set; }
        public DbSet<InterviewFeedback> InterviewFeedbacks { get; set; }

        // Component D
        public DbSet<Shortlist> Shortlists { get; set; }
        public DbSet<Recommendation> Recommendations { get; set; }
        public DbSet<AIWorkflow> AIWorkflows { get; set; }
        public DbSet<AIWorkflowStep> AIWorkflowSteps { get; set; }
        public DbSet<AIToolExecution> AIToolExecutions { get; set; }
        public DbSet<AIValidationResult> AIValidationResults { get; set; }
        public DbSet<Approval> Approvals { get; set; }
        public DbSet<AuditLog> AuditLogs { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure Indexes & Constraints
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            modelBuilder.Entity<Candidate>()
                .HasOne(c => c.User)
                .WithOne(u => u.CandidateProfile)
                .HasForeignKey<Candidate>(c => c.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Interviewer>()
                .HasOne(i => i.User)
                .WithOne(u => u.InterviewerProfile)
                .HasForeignKey<Interviewer>(i => i.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Candidate>()
                .HasIndex(c => c.UserId);

            modelBuilder.Entity<Candidate>()
                .HasIndex(c => c.City);

            modelBuilder.Entity<Skill>()
                .HasIndex(s => s.Name)
                .IsUnique();

            // CandidateSkill composite unique constraint: prevents duplicate skills for a candidate
            modelBuilder.Entity<CandidateSkill>()
                .HasIndex(cs => new { cs.CandidateId, cs.SkillId })
                .IsUnique();

            modelBuilder.Entity<CandidateSkill>()
                .HasOne(cs => cs.Candidate)
                .WithMany(c => c.CandidateSkills)
                .HasForeignKey(cs => cs.CandidateId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<CandidateSkill>()
                .HasOne(cs => cs.Skill)
                .WithMany()
                .HasForeignKey(cs => cs.SkillId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Education>()
                .HasOne(e => e.Candidate)
                .WithMany(c => c.Educations)
                .HasForeignKey(e => e.CandidateId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Education>()
                .HasIndex(e => e.CandidateId);

            modelBuilder.Entity<Experience>()
                .HasOne(exp => exp.Candidate)
                .WithMany(c => c.Experiences)
                .HasForeignKey(exp => exp.CandidateId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Experience>()
                .HasIndex(exp => exp.CandidateId);

            modelBuilder.Entity<Certificate>()
                .HasOne(cert => cert.Candidate)
                .WithMany(c => c.Certificates)
                .HasForeignKey(cert => cert.CandidateId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Certificate>()
                .HasIndex(cert => cert.CandidateId);

            modelBuilder.Entity<CVDocument>()
                .HasOne(d => d.Candidate)
                .WithMany(c => c.CVDocuments)
                .HasForeignKey(d => d.CandidateId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<CVDocument>()
                .HasIndex(d => d.CandidateId);

            modelBuilder.Entity<CandidatePreference>()
                .HasOne(cp => cp.Candidate)
                .WithOne(c => c.Preference)
                .HasForeignKey<CandidatePreference>(cp => cp.CandidateId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<CandidatePreference>()
                .HasIndex(cp => cp.CandidateId)
                .IsUnique();

            modelBuilder.Entity<VacancySkill>()
                .HasOne(vs => vs.Vacancy)
                .WithMany(v => v.VacancySkills)
                .HasForeignKey(vs => vs.VacancyId);

            modelBuilder.Entity<VacancySkill>()
                .HasOne(vs => vs.Skill)
                .WithMany()
                .HasForeignKey(vs => vs.SkillId);

            modelBuilder.Entity<Application>()
                .HasOne(a => a.Candidate)
                .WithMany(c => c.Applications)
                .HasForeignKey(a => a.CandidateId);

            modelBuilder.Entity<Application>()
                .HasOne(a => a.Vacancy)
                .WithMany(v => v.Applications)
                .HasForeignKey(a => a.VacancyId);
        }
    }
}
