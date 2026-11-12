# ADR-001: ASP.NET Core as the Sole Public Backend API

**Date:** 2026-09-10  
**Status:** Accepted  
**Component:** All (Shared Architecture)

---

## Context

SkillBridge AI requires a single, secure, and scalable backend API to serve both a React web application (Recruiter portal) and a Flutter mobile application (Candidate portal). We also require this backend to act as the sole orchestrator of the internal Python Agentic AI microservice, ensuring no client application ever directly contacts the AI service or the database.

## Decision

We adopt **ASP.NET Core 8 Web API (C#)** as the sole public backend API layer.

- All React and Flutter clients communicate exclusively with ASP.NET Core via HTTP/JWT.
- ASP.NET Core is the only service that can call the internal Python/FastAPI AI microservice.
- All AI API keys, secrets, and execution state are managed by ASP.NET Core — never exposed to clients.
- The API follows the **Controller → Service → Repository** pattern with Dependency Injection.

## Consequences

**Positive:**
- Single security boundary — JWT auth, role validation, and secret management in one place.
- Strong typing via C# and EF Core prevents data contract errors.
- xUnit testing is well-supported natively.
- GitHub Actions CI/CD with `dotnet build` and `dotnet test` is straightforward.

**Negative:**
- More boilerplate than a Node.js API for simple CRUD operations.
- Requires .NET SDK on all developer machines.

## Alternatives Considered

| Alternative | Rejected Because |
|-------------|-----------------|
| Node.js/Express | Weaker typing, less structured DI container |
| Python FastAPI for everything | Would mix public API with internal AI service, breaking isolation |
| Firebase Functions | Not suitable for complex EF Core/PostgreSQL workflows |
