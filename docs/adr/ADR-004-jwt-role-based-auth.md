# ADR-004: JWT Role-Based Authorization

**Date:** 2026-09-10  
**Status:** Accepted  
**Component:** All (Security Layer)

---

## Context

SkillBridge AI has four distinct user roles with different access rights:
- **Candidate** — Flutter mobile only, can apply and view status
- **Recruiter** — React web, manages vacancies and HITL approvals
- **Interviewer** — React/Flutter, views and scores assigned interviews
- **Administrator** — Full React web access

We need a stateless, scalable authentication mechanism that works across both the React web app and Flutter mobile app without sharing session state.

## Decision

We use **JSON Web Tokens (JWT)** with **HMAC-SHA256 signing** for stateless authentication. Tokens are issued by the ASP.NET Core `/api/auth/login` endpoint and carry `Role` claims.

All protected endpoints use `[Authorize(Roles = "...")]` attribute-based authorization.

Token configuration is stored in `appsettings.json` with real secrets only in environment variables or `appsettings.Development.json` (which is gitignored).

```csharp
// Example role guard
[Authorize(Roles = "Recruiter,Administrator")]
[HttpPost("{id}/approve")]
public IActionResult ApproveApplication(...) { }
```

## Token Payload (Claims)

| Claim | Value |
|-------|-------|
| `NameIdentifier` | User ID |
| `Name` | Full name |
| `Email` | Email address |
| `Role` | Candidate / Recruiter / Interviewer / Administrator |

## Consequences

**Positive:**
- Stateless — no server-side session store needed.
- Works identically for React (Authorization header) and Flutter (secure storage).
- Role-based access is enforced at the API level — clients can't bypass it.

**Negative:**
- Tokens cannot be revoked before expiry (mitigated by 24h expiry + logout clearing local storage).

## Alternatives Considered

| Alternative | Rejected Because |
|-------------|-----------------|
| Session Cookies | Not suitable for mobile (Flutter) cross-origin requests |
| OAuth2/OIDC (external) | Overkill for academic project; adds external dependency |
| API Keys per user | Not scalable; doesn't carry role/identity information |
