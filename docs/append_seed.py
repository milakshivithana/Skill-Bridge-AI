with open("backend/SkillBridge.Api/init_railway.sql", "r", encoding="utf-8") as f:
    sql = f.read()

seed_sql = """
-- ============================================================
-- SEED DATA (Default Users, Skills, Companies, Vacancies)
-- ============================================================

-- 1. Skills
INSERT INTO "Skills" ("Id", "Name", "Category") OVERRIDING SYSTEM VALUE VALUES
(1, 'React', 'Framework'),
(2, 'C#', 'Programming'),
(3, 'SQL', 'Database'),
(4, 'Git', 'Tool'),
(5, 'Docker', 'DevOps'),
(6, 'Python', 'Programming'),
(7, 'Flutter', 'Mobile')
ON CONFLICT ("Id") DO NOTHING;

-- 2. Users (Admin, Recruiter, Candidate, Interviewer)
INSERT INTO "Users" ("Id", "FullName", "Email", "PasswordHash", "Role", "CreatedAt", "UpdatedAt") OVERRIDING SYSTEM VALUE VALUES
(1, 'System Administrator', 'admin@skillbridge.lk', 'PrP+ZrMeO00Q+nC1ytSccRIpSvauTkdqHEBRVdRaoSE=', 'Administrator', NOW(), NOW()),
(2, 'Sarah Jenkins (Recruiter)', 'recruiter@techcorp.com', 'QmUs0ffUorCnpmvDdDBSvp/hE5uarcnXEd8rSoS1Qrc=', 'Recruiter', NOW(), NOW()),
(3, 'Candidate 102', 'candidate102@student.sliit.lk', '0Lxw6MB9pNd9oQ57QWA6lVFo2IAUuvQh7Bb78Huwj0U=', 'Candidate', NOW(), NOW()),
(4, 'Dr. Aruni Silva (Interviewer)', 'interviewer@techcorp.com', '3p9kEw8QOwGA5DMj0gba05o2XyeKfy2UhKTYxb/PQ94=', 'Interviewer', NOW(), NOW())
ON CONFLICT ("Id") DO NOTHING;

-- 3. Candidate & Interviewer Profiles
INSERT INTO "Candidates" ("Id", "UserId", "Phone", "City", "Bio", "IsProfileComplete", "CreatedAt", "UpdatedAt") OVERRIDING SYSTEM VALUE VALUES
(1, 3, '+94771234567', 'Colombo', 'Undergraduate student specializing in Software Engineering.', true, NOW(), NOW())
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO "Interviewers" ("Id", "UserId", "Department") OVERRIDING SYSTEM VALUE VALUES
(1, 4, 'Software Architecture')
ON CONFLICT ("Id") DO NOTHING;

-- 4. Candidate Skills
INSERT INTO "CandidateSkills" ("CandidateId", "SkillId", "ProficiencyLevel") VALUES
(1, 1, 'Expert'),
(1, 2, 'Intermediate'),
(1, 3, 'Intermediate'),
(1, 4, 'Intermediate');

-- 5. Companies
INSERT INTO "Companies" ("Id", "Name", "Industry", "Location", "Website") OVERRIDING SYSTEM VALUE VALUES
(1, 'TechCorp Solutions', 'Software Development', 'Colombo 03', 'https://techcorp.com'),
(2, 'CloudNation Technologies', 'Cloud & DevOps Solutions', 'Kandy / Remote', 'https://cloudnation.io')
ON CONFLICT ("Id") DO NOTHING;

-- 6. Vacancies
INSERT INTO "Vacancies" ("Id", "CompanyId", "Title", "Description", "Location", "EmploymentType", "IsActive", "ApplicationDeadline", "CreatedAt", "UpdatedAt") OVERRIDING SYSTEM VALUE VALUES
(1, 1, 'Software Engineering Intern', 'Seeking a driven intern proficient in React, SQL, and Git. Knowledge of C# and Docker is preferred.', 'Colombo', 'Internship', true, NOW() + INTERVAL '25 days', NOW(), NOW()),
(2, 1, 'Frontend Developer Intern (React)', 'Join our web app team focusing on modern React, TypeScript, and state management.', 'Colombo', 'Internship', true, NOW() + INTERVAL '15 days', NOW(), NOW()),
(3, 2, 'Backend & Cloud Intern (C# / Python)', 'Hands-on experience building REST APIs with ASP.NET Core, PostgreSQL, and cloud deployments.', 'Remote', 'Internship', true, NOW() + INTERVAL '20 days', NOW(), NOW())
ON CONFLICT ("Id") DO NOTHING;

-- 7. Vacancy Skills
INSERT INTO "VacancySkills" ("VacancyId", "SkillId", "IsMandatory") VALUES
(1, 1, true),  -- React (Mandatory)
(1, 3, true),  -- SQL (Mandatory)
(1, 4, true),  -- Git (Mandatory)
(1, 2, false), -- C# (Preferred)
(1, 5, false), -- Docker (Preferred)
(2, 1, true),  -- React (Mandatory)
(2, 4, true),  -- Git (Mandatory)
(3, 2, true),  -- C# (Mandatory)
(3, 3, true);  -- SQL (Mandatory)

-- 8. Vacancy Requirements
INSERT INTO "VacancyRequirements" ("VacancyId", "RequirementText", "IsNonNegotiable") VALUES
(1, 'Must be currently pursuing a degree in CS, SE, or IT.', true),
(1, 'Available for a minimum 6-month full-time internship.', true),
(2, 'Enrolled in a recognized tertiary computing degree program.', true),
(3, 'Familiarity with relational database design and Git workflows.', true);

-- Reset Sequences so future inserts auto-increment properly
SELECT setval(pg_get_serial_sequence('"Skills"', 'Id'), COALESCE(MAX("Id"), 1)) FROM "Skills";
SELECT setval(pg_get_serial_sequence('"Users"', 'Id'), COALESCE(MAX("Id"), 1)) FROM "Users";
SELECT setval(pg_get_serial_sequence('"Candidates"', 'Id'), COALESCE(MAX("Id"), 1)) FROM "Candidates";
SELECT setval(pg_get_serial_sequence('"Interviewers"', 'Id'), COALESCE(MAX("Id"), 1)) FROM "Interviewers";
SELECT setval(pg_get_serial_sequence('"Companies"', 'Id'), COALESCE(MAX("Id"), 1)) FROM "Companies";
SELECT setval(pg_get_serial_sequence('"Vacancies"', 'Id'), COALESCE(MAX("Id"), 1)) FROM "Vacancies";
"""

if "COMMIT;" in sql:
    sql_with_seed = sql.replace("COMMIT;", seed_sql + "\nCOMMIT;")
else:
    sql_with_seed = sql + "\n" + seed_sql

with open("backend/SkillBridge.Api/init_railway.sql", "w", encoding="utf-8") as f:
    f.write(sql_with_seed)

print("init_railway.sql updated with seed data successfully!")
