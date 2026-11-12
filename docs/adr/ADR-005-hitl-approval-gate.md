# ADR-005: Human-in-the-Loop (HITL) Approval Gate Design

**Date:** 2026-09-10  
**Status:** Accepted  
**Component:** D — Shortlisting, Approval & Analytics

---

## Context

The SkillBridge AI pipeline uses four specialized AI agents to automatically match candidates to vacancies and propose interview slots. However, AI-only decisions in high-impact recruitment contexts carry risks:

- Bias introduced by training data
- Errors in match score calculation
- Missing context a human recruiter would catch

We must ensure a recruiter always reviews and authorizes AI-generated recruitment decisions before they take effect.

## Decision

We implement a mandatory **Human-in-the-Loop (HITL) Approval Gate** at the boundary between the AI pipeline and final recruitment action.

### Flow

```
AI Pipeline Completes
       ↓
Application.Status = "PENDING_RECRUITER_APPROVAL"
       ↓
[PAUSE — HITL Gate Active]
       ↓
Recruiter sees card in HitlApprovalQueue (React Web)
       ↓
Recruiter chooses: APPROVE / REJECT / REQUEST REVISION
       ↓
Decision written to PostgreSQL (Approval + AuditLog entities)
       ↓
Application.Status updated → Flutter candidate notified
```

### Enforced Rules

1. No application transitions directly from `IN_AI_MATCHING` to `APPROVED` without recruiter action.
2. Every HITL decision is persisted in the `AuditLog` table with `UserId`, `Action`, `EntityId`, and `Timestamp`.
3. The Validation & Fairness Agent must pass (`ValidationPassed = true`) before routing to HITL.
4. Only the `Recruiter` or `Administrator` role may call approve/reject/revision endpoints.

## Consequences

**Positive:**
- Eliminates fully automated high-stakes decisions — aligned with AI safety best practices.
- Complete audit trail for compliance and dispute resolution.
- Recruiter can add comments at each decision point.

**Negative:**
- Adds latency to the recruitment process (human review step required).
- Requires recruiter availability for the system to progress applications.

## Alternatives Considered

| Alternative | Rejected Because |
|-------------|-----------------|
| Fully automated AI approval | Violates AI safety requirements; no human oversight |
| Optional HITL (recruiter can skip) | Defeats the purpose; non-compliant with assignment spec |
| Email-based approval workflow | Too slow; poor auditability; not integrated with system state |
