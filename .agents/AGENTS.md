# SkillBridge AI - Project Rules & Standards (SE3090 Assignment 1)

This repository contains the full-stack and agentic AI application **SkillBridge AI - Intelligent Internship & Recruitment Coordination System** developed for SE3090: Software Engineering Frameworks. All development must strictly adhere to the rules and architectural constraints defined below.

---

## 1. Mandatory Technology Stack

| Domain | Technology / Framework | Constraints & Guidelines |
| :--- | :--- | :--- |
| **Backend API** | ASP.NET Core Web API (C#) | Sole public API layer. Controllers, DTOs, Application/Service layer, Dependency Injection. |
| **Database** | PostgreSQL | Managed via EF Core with PostgreSQL provider (`Npgsql.EntityFrameworkCore.PostgreSQL`). |
| **Web Frontend** | React (JavaScript / TypeScript) | Functional components, hooks, React Router, state management (Zustand / Redux Toolkit / Context). |
| **Mobile App** | Flutter & Dart | Reusable widgets, state management (Provider / Riverpod / Bloc), secure storage, native device features. |
| **Agentic AI** | Python (LangGraph / FastAPI) | **INTERNAL SERVICE ONLY**. Must be called exclusively by the ASP.NET Core API backend. |
| **CI/CD** | GitHub Actions | Automated build, restore, and test execution for ASP.NET Core backend on every push/PR. |

---

## 2. Integrated Architecture Rules

1. **Single Backend Rule**: Both React (Web) and Flutter (Mobile) **must only** communicate with the ASP.NET Core Web API backend. Neither client app may directly contact the PostgreSQL database or the internal Agentic AI service.
2. **Internal Agentic AI Rule**: The Agentic AI service operates as an internal microservice. ASP.NET Core orchestrates AI calls, manages API keys/secrets, applies security checks, and stores execution state in PostgreSQL.
3. **Cross-Platform End-to-End Workflow**:
   - Candidate applies for a vacancy in Flutter (Mobile).
   - Application sent to ASP.NET Core Web API.
   - ASP.NET Core triggers internal Agentic AI service (multi-agent plan, candidate profile analysis, matching score, interview slot proposal).
   - Paused for **Human-in-the-Loop (HITL)** recruiter approval.
   - Recruiter reviews and Approves/Rejects/Requests Revision in React (Web).
   - State updated in PostgreSQL and reflected back to Flutter mobile candidate status.

---

## 3. Four-Member Business Component Division

- **Component A (Member 1)**: Candidate Profile & Skill Management (Entities: Candidate, CandidateSkill, Skill, Education, Experience, Certificate, CVDocument, CandidatePreference)
- **Component B (Member 2)**: Vacancy & Application Management (Entities: Company, Vacancy, VacancySkill, VacancyRequirement, Application, ApplicationStatusHistory, SavedVacancy)
- **Component C (Member 3)**: Interview & Scheduling Management (Entities: Interview, InterviewSlot, Interviewer, InterviewPanel, InterviewScore, InterviewFeedback, Availability)
- **Component D (Member 4)**: Shortlisting, Approval & Analytics (Entities: Shortlist, Recommendation, Approval, AIWorkflow, AIWorkflowStep, AIToolExecution, AIValidationResult, AuditLog, Report)

---

## 4. Four Specialized Agentic AI Roles

1. **Planning Agent**: Converts recruitment objective into a structured multi-step plan and delegates tasks (`createWorkflow`, `getWorkflowStatus`, `delegateTask`).
2. **Candidate Profile Analysis Agent**: Builds structured job-relevant candidate summary from CV, skills, experience, education (`getCandidateProfile`, `getCandidateSkills`, `getCandidateExperience`).
3. **Job Matching & Interview Agent**: Compares vacancy requirements with candidate profile, calculates match score (e.g. 84%), and proposes conflict-free interview slot (`getVacancyRequirements`, `calculateMatchScore`, `getAvailableInterviewSlots`).
4. **Validation & Fairness Agent**: Applies deterministic rules, schema checks, allowed-attribute validation, and recruiter approval routing (`validateEligibility`, `validateMatchCalculation`, `validateAllowedAttributes`, `requestApproval`).

---

## 5. Security & Quality Rules

1. **Zero Secret Hardcoding**: Store all API keys, connection strings, JWT secrets in `appsettings.json` / environment variables. Never commit secrets to Git.
2. **User Roles**: `Candidate` (Flutter), `Recruiter` (React), `Interviewer` (React/Flutter), `Administrator` (React).
3. **Automated Testing**:
   - Backend: xUnit unit tests & WebApplicationFactory API integration tests.
   - React: Component & state tests (Vitest / React Testing Library).
   - Flutter: Unit & widget tests (`flutter test`).
   - Agent Evaluation: Golden case dataset + rule-based schema validation.
4. **CI/CD Pipeline**: GitHub Actions workflow running automated restore, build, and test steps on push and pull requests to `main`.
5. **Architecture Decision Records (ADRs)**: Document 3–6 core architecture decisions in Markdown format.
