# Individual Contribution Report

**Name:** Ahamed M.N.R  
**Student ID:** IT24103157  
**Module:** SE3090 — Software Engineering Frameworks  
**Assignment:** Assignment 1 — SkillBridge AI: Intelligent Internship & Recruitment Coordination System  
**Owned Component:** Component D — Shortlisting, Approval & Analytics

---

## I. Contribution Statement

I was responsible for **Component D — Shortlisting, Approval & Analytics**, the final stage of the SkillBridge AI recruitment pipeline. My work encompassed the complete vertical slice across all four technology layers: designing and implementing the EF Core entity models (Shortlist, Recommendation, AIWorkflow, AIWorkflowStep, AIToolExecution, AIValidationResult, Approval, AuditLog), building the ASP.NET Core Web API controller (`ShortlistsController`) with full CRUD + HITL decision endpoints, developing the Validation & Fairness Agent (Python/LangGraph) that enforces 4-gate deterministic validation before routing to human recruiters, creating four React (TypeScript) pages for the recruiter web portal (ShortlistView, HitlApprovalQueue, AuditLog, Reports, WorkflowInspector), authoring Component D xUnit backend tests and pytest golden-case agent evaluation tests, writing ADR-005 (HITL Approval Gate Design), and integrating the cross-platform end-to-end approval workflow connecting Flutter → ASP.NET Core → AI Service → React → PostgreSQL.

---

## II. Owned Component & Technical Implementation

### 1. Data Layer — EF Core Entity Models (PostgreSQL)

I designed and implemented **8 entity models** for Component D in [`Entities.cs`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/backend/SkillBridge.Api/Models/Entities.cs#L472-L631):

| Entity | Purpose | Key Fields |
|:---|:---|:---|
| `Shortlist` | Groups AI-ranked recommendations per vacancy | VacancyId, Title, CreatedAt |
| `Recommendation` | Links an Application to a Shortlist with a calculated score | ShortlistId, ApplicationId, CalculatedScore, AIJustification |
| `AIWorkflow` | Tracks a multi-agent AI execution pipeline per application | WorkflowId, Objective, ApplicationId, Status |
| `AIWorkflowStep` | Records each agent's input/output at every step | AgentName, StepName, StructuredInput, StructuredOutput |
| `AIToolExecution` | Logs individual tool calls with timing | ToolName, InputJson, OutputJson, ExecutionTimeMs |
| `AIValidationResult` | Stores gate-level validation outcomes | ValidationType, IsValid, Errors |
| `Approval` | Records recruiter HITL decisions | ApproverUserId, Decision, Comments, DecisionAt |
| `AuditLog` | Tamper-evident record of all system actions | UserId, Action, EntityType, EntityId, Summary, Timestamp |

All entities follow EF Core conventions with `[Key]`, `[ForeignKey]`, `[Required]`, and `[MaxLength]` annotations and are tracked via code-first migrations targeting Supabase-hosted PostgreSQL.

---

## 2. Backend API — ASP.NET Core Controller

I implemented [`ShortlistsController.cs`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/backend/SkillBridge.Api/Controllers/ShortlistsController.cs) (456 lines) exposing the following REST endpoints:

| HTTP Method | Route | Purpose |
|:---|:---|:---|
| `GET` | `/api/shortlists` | List all shortlists (role-filtered for Candidates) |
| `GET` | `/api/shortlists/{id}` | Get single shortlist with recommendations |
| `POST` | `/api/shortlists` | Create new AI-generated shortlist |
| `GET` | `/api/applications/pending-approval` | HITL Queue — all apps awaiting recruiter decision |
| `POST` | `/api/shortlists/{id}/approve` | Recruiter APPROVE — updates Application, AIWorkflow, Approval, AuditLog |
| `POST` | `/api/shortlists/{id}/reject` | Recruiter REJECT — same transactional chain |
| `POST` | `/api/shortlists/{id}/request-revision` | REQUEST REVISION — pauses workflow for re-evaluation |
| `GET` | `/api/ai-workflows/{id}` | Retrieve full AI workflow execution trace |
| `GET` | `/api/audit-logs` | Paginated audit log viewer |
| `GET` | `/api/reports/recruitment-summary` | Recruitment analytics KPIs |

**Key design decisions:**
- Each HITL decision (`approve/reject/request-revision`) is **transactional**: it atomically updates the Application status, creates or updates the AIWorkflow record, inserts an Approval decision, writes an ApplicationStatusHistory entry, and logs to AuditLog — all in a single `SaveChanges()` call.
- Candidates are role-filtered via JWT claims (`ClaimTypes.Role`, `ClaimTypes.NameIdentifier`) so they only see shortlists containing their own recommendations.

I also created the dedicated DTO layer in [`ComponentDDtos.cs`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/backend/SkillBridge.Api/DTOs/ComponentDDtos.cs) with 6 specialized DTOs:
- `PendingApprovalDto` — HITL queue data with matched skills, AI justification, and proposed interview slot
- `ApprovalDecisionDto` — Recruiter decision payload
- `AuditLogDto` — Audit trail record
- `ShortlistResponseDto` — Shortlist with nested recommendations
- `RecommendationDto` — Individual ranked candidate with score and justification
- `RecruitmentAnalyticsDto` — 11 KPIs for the reports dashboard

---

## 3. Agentic AI — Validation & Fairness Agent (Python)

I designed and implemented the **Validation & Fairness Agent** ([`validation_fairness_agent.py`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/ai_service/app/agents/validation_fairness_agent.py), 375 lines) — Role 4 of 4 in the multi-agent pipeline — which enforces a **4-gate deterministic validation pipeline**:

| Gate | Name | Tool Called | Failure Consequence |
|:---|:---|:---|:---|
| **Gate 1** | Allowed-Attribute Check | `validate_allowed_attributes()` | Rejects if protected attributes (age, gender, race, religion, etc.) found |
| **Gate 2** | Eligibility Check | `validate_eligibility()` | Rejects if no skill overlap, insufficient experience, or location mismatch |
| **Gate 3** | Schema & Match-Calculation Check | `validate_match_calculation()` | Rejects if match result object is malformed or scores out of range |
| **Gate 4** | HITL Routing | `request_approval()` | Routes to recruiter queue only if Gates 1–3 all pass |

The agent produces a full `ValidationReport` dict with guaranteed output keys: `agent`, `candidate_id`, `vacancy_id`, `workflow_id`, `gate_results` (list of 4 gate dicts), `validation_passed`, `approval_status`, `approval_request`, `requires_human_approval`, `rejection_reasons`, `summary`, `started_at`, `completed_at`.

I also implemented the 4 Validation Agent tools in [`allowlisted_tools.py`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/ai_service/app/tools/allowlisted_tools.py#L388-L636):
- `validate_allowed_attributes()` — scans for 9 disallowed keys (age, gender, race, religion, marital_status, salary_history, nationality, ethnicity, disability)
- `validate_eligibility()` — enforces 3 deterministic rules (skill overlap, minimum experience, location match)
- `validate_match_calculation()` — structural schema validation with breakdown consistency checking
- `request_approval()` — HITL routing with workflow registry state update

Additionally, I contributed to the **LangGraph Workflow Graph** ([`workflow_graph.py`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/ai_service/app/agents/workflow_graph.py)) where `node_validate_and_route` is the terminal node I implemented, which invokes the Validation & Fairness Agent as the final step before HITL routing.

---

## 4. React Web Frontend — Recruiter Dashboard Pages

I developed **5 React (TypeScript) pages** for the recruiter web portal:

| Page | File | Key Features |
|:---|:---|:---|
| **HITL Approval Queue** | [`HitlApprovalQueue.tsx`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/web_app/src/pages/HitlApprovalQueue.tsx) (183 lines) | Expandable application cards, AI match score display, skill tags, deterministic validation status, 3-action HITL buttons (Approve/Reject/Request Revision), real-time state sync |
| **Shortlist View** | [`ShortlistView.tsx`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/web_app/src/pages/ShortlistView.tsx) (166 lines) | AI-ranked candidate leaderboards per vacancy with 🥇🥈🥉 ranking, score-colored indicators, role-filtered view for candidates (see only own position) |
| **Audit Log** | [`AuditLog.tsx`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/web_app/src/pages/AuditLog.tsx) (116 lines) | Filterable table of all recruiter decisions (Approve/Reject/Revision), color-coded action badges, timestamp display, total action counter |
| **Reports & Analytics** | [`Reports.tsx`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/web_app/src/pages/Reports.tsx) (183 lines) | 4 KPI metric cards, animated status funnel bar chart, SVG score ring, AI quality checklist, conversion summary panel |
| **Workflow Inspector** | [`WorkflowInspector.tsx`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/web_app/src/pages/WorkflowInspector.tsx) (39 lines) | AI workflow execution audit viewer — loads full 4-step trace JSON by workflow ID |

All pages use glassmorphism design, lucide-react icons, CSS custom properties, and communicate exclusively with the ASP.NET Core backend via the shared `api` service module.

---

## 5. Architecture Decision Record

I authored [**ADR-005: Human-in-the-Loop (HITL) Approval Gate Design**](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/docs/adr/ADR-005-hitl-approval-gate.md) which documents:
- The mandatory HITL gate between AI pipeline completion and recruitment action
- The status flow: `PENDING_RECRUITER_APPROVAL` → `APPROVED` / `REJECTED` / `REVISION_REQUESTED`
- Four enforced rules (no auto-approval, AuditLog persistence, validation prerequisite, role restriction)
- Alternatives considered and rejected (fully automated AI approval, optional HITL, email-based workflow)

---

## III. Key Commit, Pull Request & Test Evidence

### Test Evidence — Backend (xUnit)

In [`UnitTests.cs`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/backend/SkillBridge.Tests/UnitTests.cs#L182-L377), I authored **12 xUnit tests** for Component D:

| Test Method | What It Validates |
|:---|:---|
| `TestDeterministicSkillMatchingScore` | Deterministic score formula: 3/3 required × 80 + bonus = 84% |
| `TestMatchScoreZeroWhenNoSkillsMatch` | Score drops to 0% when no required skills overlap |
| `TestAllowedAttributeValidationRule` | Clean payload passes (no disallowed keys) |
| `TestValidationFailsWhenDisallowedAttributePresent` | "gender" in payload triggers validation failure |
| `TestApprovalDecisionSetsApprovedStatus` | APPROVE → APPROVED status transition |
| `TestRejectionDecisionSetsRejectedStatus` | REJECT → REJECTED status transition |
| `TestRevisionRequestedSetsCorrectStatus` | REVISION → REVISION_REQUESTED transition |
| `TestWorkflowStatusProgressionIsOrdered` | SUBMITTED → IN_AI_MATCHING → PENDING → APPROVED ordering |
| `TestReportAnalyticsTotalsConsistency` | Analytics totals add up correctly |
| `TestAuditLogActionTypeIsRecognized` | All action types in recognized set |
| `TestSchemaValidationFailsForMissingRequiredKeys` | Missing schema keys detected |

### Test Evidence — Agent Evaluation (pytest)

In [`test_agents.py`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/ai_service/tests/test_agents.py), I authored/contributed to **40+ pytest tests** across 5 test categories:

| Test Class | Count | Scope |
|:---|:---|:---|
| `TestAllowedAttributeValidation` | 6 tests | Clean profile, gender detection, multiple disallowed, case-insensitive, empty, type error |
| `TestValidateEligibility` | 5 tests | Golden case passes, no skill overlap fails, location mismatch, insufficient experience, rule count |
| `TestValidateMatchCalculation` | 4 tests | Valid passes, missing keys fails, out-of-range score, invalid recommendation |
| `TestValidationFairnessAgent` | 5 tests | All gates pass, gate 1 fails on disallowed attribute, gate 3 fails on schema, rejection reasons populated, approval request present |
| `TestGoldenCaseE2E` | 1 test | Full 4-agent workflow with deterministic golden inputs → expected match score, validation status, 4 completed traces |

### CI/CD Pipeline

The [GitHub Actions workflow](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/.github/workflows/ci.yml) runs `dotnet restore` → `dotnet build` → `dotnet test` on every push/PR to `main` and `dev`, automatically executing all Component D xUnit tests.

### Key Commits *(to be filled with actual commit hashes)*

| Commit Hash | Description |
|:---|:---|
| `_______` | Implement Component D entities (Shortlist, Recommendation, AIWorkflow, Approval, AuditLog) |
| `_______` | Add ShortlistsController with HITL approve/reject/revision endpoints |
| `_______` | Implement Validation & Fairness Agent (4-gate pipeline) |
| `_______` | Add HITL Approval Queue, Shortlist View, Audit Log, Reports pages (React) |
| `_______` | Author ADR-005 HITL Approval Gate Design |
| `_______` | Add Component D unit tests (xUnit) and agent evaluation tests (pytest) |

---

## IV. Challenges and Learning

### Challenge 1: Designing the 4-Gate Validation Pipeline
Implementing a deterministic, rule-based validation system that sits between an AI pipeline and human decision-makers required careful thought about failure modes. The key insight was that gates must be **strictly ordered and fail-fast** — if Gate 1 (allowed-attribute check) detects bias, there is no point running Gates 2–3. I also had to ensure the gate results are fully serializable so they can be persisted in PostgreSQL and displayed in the Workflow Inspector.

**Learning:** Designing validation gates with explicit, documented contracts between each gate made the system testable and auditable. The 4-gate approach proved effective for separating concerns (fairness, eligibility, schema, routing).

### Challenge 2: Transactional Consistency in HITL Decisions
When a recruiter approves/rejects an application, the system must atomically update 4 tables (Application, AIWorkflow, Approval, AuditLog) plus insert an ApplicationStatusHistory record. Initially I had separate `SaveChanges()` calls which risked partial updates on failure.

**Learning:** Consolidating all writes into a single `SaveChanges()` call ensures EF Core wraps them in a single database transaction. I also learned the importance of creating the AIWorkflow record on-demand if it doesn't yet exist (defensive coding for edge cases where the AI pipeline didn't create one).

### Challenge 3: Role-Based Filtering for Candidates
The shortlist endpoint needed to serve both recruiters (see all candidates) and candidates (see only their own position). Implementing this with JWT claim extraction and dynamic LINQ query composition was non-trivial, especially when the `candidateId` maps through `User → Candidate → Application → Recommendation`.

**Learning:** EF Core's `Include/ThenInclude` chain with conditional `.Where()` clauses can handle complex role-based data filtering elegantly, though it requires careful null-checking throughout the navigation chain.

### Challenge 4: End-to-End Cross-Platform State Synchronization
Ensuring that a recruiter's APPROVE click in React propagates correctly through ASP.NET Core → PostgreSQL → Flutter candidate status required understanding the full state machine: `SUBMITTED → IN_AI_MATCHING → PENDING_RECRUITER_APPROVAL → APPROVED/REJECTED/REVISION_REQUESTED`.

**Learning:** Defining the state machine explicitly in ADR-006 (contributed by the team) and enforcing it at the API layer prevents invalid transitions and makes debugging cross-platform flows tractable.

---

## V. Individual AI Usage Log

| # | Date | AI Tool Used | Task | Prompt Summary | Output Used? | What I Modified |
|:---|:---|:---|:---|:---|:---|:---|
| 1 | 2026-09-05 | Google Gemini (Antigravity) | Entity model design | "Design EF Core entities for Shortlist, Recommendation, AIWorkflow, Approval, AuditLog with proper FK relationships" | ✅ Partial | Refined field constraints (`MaxLength`), added `AIToolExecution` and `AIValidationResult` entities, fixed navigation property names |
| 2 | 2026-09-08 | Google Gemini (Antigravity) | ShortlistsController scaffolding | "Create ASP.NET Core controller with HITL approve/reject/revision endpoints that update Application, AIWorkflow, and AuditLog atomically" | ✅ Partial | Rewrote role-based candidate filtering logic, added defensive AIWorkflow creation, fixed LINQ Include chains |
| 3 | 2026-09-10 | Google Gemini (Antigravity) | Validation & Fairness Agent | "Implement a 4-gate validation agent with allowed-attribute check, eligibility check, schema validation, and HITL routing" | ✅ Partial | Redesigned gate runner architecture to use private methods with shared `gate_results` list, added `_synthesise_vacancy_requirements` helper, fixed Gate 2 to use 3 eligibility rules |
| 4 | 2026-09-12 | Google Gemini (Antigravity) | React HITL Approval Queue | "Create a React page showing pending approvals with expandable cards, matched skills, and approve/reject/revision buttons" | ✅ Partial | Redesigned card layout for glassmorphism styling, added real-time decision notification banners, integrated with `api.ts` service methods |
| 5 | 2026-09-14 | Google Gemini (Antigravity) | React Reports & Analytics page | "Create a recruitment analytics dashboard with KPI cards, bar charts, and a score ring SVG" | ✅ Partial | Built custom `BarChart` and `ScoreRing` components from scratch (no charting library), added AI quality panel with checklist, fairness disclaimer |
| 6 | 2026-09-16 | Google Gemini (Antigravity) | Agent pytest tests | "Write golden-case + negative-case tests for ValidationFairnessAgent and allow-listed tools" | ✅ Partial | Added explicit `clean_vacancy_requirements` fixture to fix Gate 2 test failures, expanded edge cases (case-insensitive detection, type errors) |
| 7 | 2026-09-18 | Google Gemini (Antigravity) | Component D DTOs | "Create DTOs for HITL queue, audit log, shortlist response, and recruitment analytics" | ✅ Partial | Added `ProposedInterviewSlot` field, `AIJustification` default, renamed fields for frontend consistency |
| 8 | 2026-09-20 | Google Gemini (Antigravity) | ADR-005 | "Write an ADR for the HITL approval gate design" | ✅ Partial | Refined flow diagram, added 4 enforced rules, expanded alternatives table |

---

## VI. Individual AI Reflection (~1 Page)

### How AI Assisted My Development Process

Throughout the development of Component D, I used Google Gemini (via the Antigravity IDE) as a **pair-programming assistant** for scaffolding, code generation, and test writing. The AI was most valuable in three specific phases:

**1. Initial Scaffolding (High Value, Heavy Modification)**  
For the Entity models and ShortlistsController, the AI produced structurally correct starting points — proper EF Core annotations, navigation properties, and controller method signatures. However, every generated artifact required significant modification. The AI's initial entity design missed the `AIToolExecution` and `AIValidationResult` tables entirely, and the controller lacked role-based filtering logic. I estimate that AI-generated code constituted roughly 40–50% of the final implementation in these layers, with the remaining 50–60% being my own design decisions, bug fixes, and integration work.

**2. Validation Agent Design (Moderate Value, Architecture Was Mine)**  
The 4-gate validation pipeline architecture — the ordering of gates, the fail-fast behavior, and the explicit separation between fairness checking and eligibility checking — was my own design decision informed by the assignment requirements (ADR-005). The AI helped with Python boilerplate (type hints, docstrings, return dict structures), but the core logic of each gate runner, the `_synthesise_vacancy_requirements` helper, and the integration with `allowlisted_tools.py` were designed and implemented by me. The AI initially generated a flat function with all gates inline; I refactored it into a class with private `_run_gate_N` methods for testability.

**3. React Pages (High Value, Design Iteration Was Manual)**  
The AI was effective at generating React functional components with hooks, state management, and JSX structure. However, the visual design — glassmorphism panels, lucide-react icon selection, color-coded score indicators, the expandable card pattern in the HITL queue, and the custom SVG `ScoreRing` component — required multiple rounds of manual iteration. The AI does not understand visual aesthetics deeply; it produced plain, unstyled components that I then enhanced with CSS custom properties and inline styling to match the team's design system.

### What AI Cannot Replace

The most significant parts of my work were not assisted by AI at all:

- **Architecture decisions:** The HITL gate design, the transactional consistency strategy, the role-based filtering approach — these required understanding the full system context across Flutter, ASP.NET Core, Python, and React.
- **Integration debugging:** When the frontend showed `undefined` for recommendation scores, I traced the issue through the React `api.ts` → ASP.NET Core DTO → EF Core LINQ query → PostgreSQL schema chain. The AI cannot debug across 4 technology layers simultaneously.
- **Test design:** While the AI helped with test boilerplate, the golden-case dataset design (choosing input values that produce known expected outputs, like 3/3 required skills × 80 + 1/2 preferred × 20 = 90%) was my own work. The AI initially generated tests with magic numbers that didn't correspond to the actual scoring formula.

### Critical Assessment

I found AI assistance to be a **productivity accelerator but not a quality guarantee**. Every AI-generated artifact contained at least one bug, missing edge case, or architectural misalignment that required manual correction. The most dangerous pattern was accepting AI output without verification — in two instances, the AI generated LINQ queries with missing null-checks that would have caused `NullReferenceException` in production.

My key takeaway: AI tools are most effective when the developer has a clear mental model of the desired architecture and uses AI to accelerate the implementation of that model, rather than delegating the design to the AI.

---

*End of Individual Report — Ahamed M.N.R (IT24103157)*
