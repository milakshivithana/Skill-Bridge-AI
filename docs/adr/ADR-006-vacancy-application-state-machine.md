# ADR-006: Vacancy & Application Management State Machine and Eligibility Checks

**Date:** 2026-09-20  
**Status:** Accepted  
**Component:** B — Vacancy & Application Management

---

## Context

In SkillBridge AI, candidates apply for internship vacancies, bookmark vacancies, track application progress, and withdraw applications. To prevent inconsistent database states and ensure only qualified candidates progress through the recruitment workflow, we require a clear application state machine and deterministic eligibility validation rules before AI matching and recruiter review.

## Decision

We implement a formal **Application State Machine** and a **Deterministic Eligibility Validation Engine** in the ASP.NET Core backend.

### Application State Machine Transitions

```
[SUBMITTED]
    │
    ├──────────► [IN_AI_MATCHING] ──────────► [PENDING_RECRUITER_APPROVAL]
    │                                                   │
    │                                 ┌─────────────────┼─────────────────┐
    │                                 ▼                 ▼                 ▼
    │                            [APPROVED]        [REJECTED]   [REVISION_REQUESTED]
    │
    └──────────► [WITHDRAWN] (Candidate action before final outcome)
```

### Key Business & Architecture Rules

1. **Duplicate Application Prevention**: Candidates are constrained by database unique indexes and API-level checks to prevent submitting duplicate applications for the same vacancy.
2. **Business-Specific Operation (Non-Negotiable Eligibility Check)**:
   - Before an application progresses into AI evaluation or recruiter review, ASP.NET Core executes deterministic checks:
     a. **Profile Completeness**: Candidate profile must have uploaded CV and populated skills.
     b. **Mandatory Vacancy Skills**: Candidate skills taxonomy must match all mandatory vacancy skills.
     c. **Non-Negotiable Requirements**: Evaluates non-negotiable criteria (e.g. CS/SE degree enrolment, location availability).
3. **Application Status History & Audit Traceability**: Every state transition generates a recorded entry in `ApplicationStatusHistory` and logs audit events to `AuditLog`.
4. **Candidate Withdrawal Control**: Candidates may withdraw active applications at any point prior to final recruiter action, transitioning status to `WITHDRAWN`.

## Consequences

**Positive:**
- Enforces strict data integrity and eliminates duplicate submissions.
- Rejects non-eligible applications deterministically before calling expensive AI pipelines.
- Complete history trace for candidate status timeline in both React web and Flutter mobile applications.

**Negative:**
- Requires careful handling of status history records in database transactions.

## Alternatives Considered

| Alternative | Rejected Because |
|-------------|-----------------|
| Allowing AI to evaluate non-eligible candidates | Wastes AI pipeline resources on invalid candidates |
| Loose status strings without history logging | Missing auditability required by SE3090 specification |
