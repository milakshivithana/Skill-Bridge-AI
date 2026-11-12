# PostgreSQL Deployment Evidence — SkillBridge AI

**Project:** SkillBridge AI — Intelligent Internship & Recruitment Coordination System  
**Database Provider:** Supabase PostgreSQL (AWS ap-southeast-2)  
**ORM:** Entity Framework Core 8.0 with Npgsql provider  
**Deployment:** Render.com (Backend) + Supabase (Database) + Vercel (Frontend)

---

## 1. NuGet Package Reference — Npgsql PostgreSQL Provider

**File:** [`SkillBridge.Api.csproj`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/backend/SkillBridge.Api/SkillBridge.Api.csproj)

```xml
<PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.0.*" />
<PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="8.0.*" />
<PackageReference Include="Microsoft.EntityFrameworkCore.InMemory" Version="8.0.*" />
```

The project targets `.NET 8.0` and uses `Npgsql.EntityFrameworkCore.PostgreSQL` as the primary database provider. `InMemory` is included only as a fallback for local development when no PostgreSQL connection is available.

---

## 2. Connection String Configuration — Supabase PostgreSQL

### Production (Supabase Pooler) — [`env.render`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/backend/SkillBridge.Api/.env.render)

```env
# --- PostgreSQL (Supabase) ---
ConnectionStrings__DefaultConnection=Host=aws-0-ap-southeast-2.pooler.supabase.com;Port=5432;Database=postgres;Username=postgres.ibxfguzlvhfytnxrwznh;Password=****;SSL Mode=Require;Trust Server Certificate=true
```

> **Evidence:** Connection targets `aws-0-ap-southeast-2.pooler.supabase.com` — Supabase's managed PostgreSQL pooler in the Asia-Pacific (Sydney) region with SSL encryption enforced.

### Development (Local PostgreSQL) — [`appsettings.Development.json`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/backend/SkillBridge.Api/appsettings.Development.json)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=SkillBridge;Username=postgres;Password=123;Port=5432"
  }
}
```

### Base Configuration Template — [`appsettings.json`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/backend/SkillBridge.Api/appsettings.json)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=SkillBridge;Username=postgres;Password=YOUR_DB_PASSWORD;Port=5432"
  }
}
```

---

## 3. EF Core DbContext — PostgreSQL Entity Registration

**File:** [`ApplicationDbContext.cs`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/backend/SkillBridge.Api/Data/ApplicationDbContext.cs)

All 30+ entities are registered as `DbSet<>` properties, organized by component:

```csharp
// Component D — Shortlisting, Approval & Analytics (my owned tables)
public DbSet<Shortlist> Shortlists { get; set; }
public DbSet<Recommendation> Recommendations { get; set; }
public DbSet<AIWorkflow> AIWorkflows { get; set; }
public DbSet<AIWorkflowStep> AIWorkflowSteps { get; set; }
public DbSet<AIToolExecution> AIToolExecutions { get; set; }
public DbSet<AIValidationResult> AIValidationResults { get; set; }
public DbSet<Approval> Approvals { get; set; }
public DbSet<AuditLog> AuditLogs { get; set; }
```

The `OnModelCreating()` method configures:
- **Unique indexes:** `Users.Email`, `Skills.Name`, `CandidateSkills(CandidateId, SkillId)`, `CandidatePreferences.CandidateId`
- **Foreign key cascades:** `Candidate → User (CASCADE)`, `Interviewer → User (CASCADE)`, `CandidateSkill → Candidate (CASCADE)`, `CandidateSkill → Skill (RESTRICT)`
- **Composite unique constraints:** Prevents duplicate candidate-skill pairs

---

## 4. Code-First EF Core Migrations (Applied to PostgreSQL)

**Directory:** [`Migrations/`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/backend/SkillBridge.Api/Migrations)

| Migration | Date | Size | Purpose |
|:---|:---|:---|:---|
| `20260819071400_InitialCreate` | 2026-08-19 | 47,776 bytes | Full schema creation — all 30+ tables, indexes, FKs |
| `20260917120951_AddCandidateConstraintsAndIndexes` | 2026-09-17 | 7,396 bytes | Added composite unique constraints and performance indexes |
| `20260930035714_AddLinkedInAndPortfolioToCandidate` | 2026-09-30 | 1,202 bytes | Added `LinkedInUrl` and `PortfolioUrl` columns to Candidates |
| `ApplicationDbContextModelSnapshot.cs` | — | 53,056 bytes | Current schema snapshot tracking all 30+ tables |

All 3 migrations are registered in the Supabase `__EFMigrationsHistory` table:

```sql
INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion") VALUES
    ('20260819071400_InitialCreate', '8.0.31'),
    ('20260917120951_AddCandidateConstraintsAndIndexes', '8.0.31'),
    ('20260930035714_AddLinkedInAndPortfolioToCandidate', '8.0.31');
```

---

## 5. Supabase Migration SQL Script (Full DDL + Seed Data)

**File:** [`supabase_migration.sql`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/backend/SkillBridge.Api/supabase_migration.sql) — **544 lines, 28,181 bytes**

This script was executed directly in Supabase Dashboard → SQL Editor to provision the production database. It contains:

### 5.1 Schema DDL — Component D Tables (Lines 317–407)

```sql
-- Component D: Shortlisting, Approval & Analytics
CREATE TABLE "Shortlists" (
    "Id" integer GENERATED BY DEFAULT AS IDENTITY,
    "VacancyId" integer NOT NULL,
    "Title" character varying(200) NOT NULL DEFAULT '',
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT NOW(),
    CONSTRAINT "PK_Shortlists" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Shortlists_Vacancies" FOREIGN KEY ("VacancyId")
        REFERENCES "Vacancies" ("Id") ON DELETE CASCADE
);

CREATE TABLE "Recommendations" ( ... );     -- FK → Shortlists, Applications
CREATE TABLE "Approvals" ( ... );           -- FK → Recommendations, Users
CREATE TABLE "AIWorkflows" ( ... );         -- Tracks 4-agent pipeline execution
CREATE TABLE "AIWorkflowSteps" ( ... );     -- FK → AIWorkflows
CREATE TABLE "AIToolExecutions" ( ... );    -- FK → AIWorkflowSteps
CREATE TABLE "AIValidationResults" ( ... ); -- FK → AIWorkflows
CREATE TABLE "AuditLogs" ( ... );           -- Tamper-evident action log
```

### 5.2 Seed Data (Lines 419–543)

The migration seeds the database with:
- **7 Skills** (React, C#, SQL, Git, Docker, Python, Flutter)
- **4 Users** (Administrator, Recruiter, Candidate, Interviewer) with SHA-256 hashed passwords
- **1 Candidate** with phone, city, bio, skills, and IsProfileComplete=true
- **2 Companies** (TechCorp Solutions, CloudNation Technologies)
- **3 Vacancies** with VacancySkills and VacancyRequirements
- **1 Application** (SUBMITTED, MatchScore=84.0, EligibilityPassed=true)
- **1 Interview** (CONFIRMED) with scores (4, 5, 4) and feedback (RECOMMEND_HIRE)
- **3 Interviewer Availabilities** + **3 Interview Slots**

---

## 6. Program.cs — PostgreSQL Provider Registration with Retry Logic

**File:** [`Program.cs`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/backend/SkillBridge.Api/Program.cs#L52-L126)

### 6.1 Connection String Resolution (Lines 53–63)

```csharp
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

if (string.IsNullOrWhiteSpace(connectionString) || connectionString.Contains("YOUR_DB_PASSWORD"))
{
    connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
        ?? Environment.GetEnvironmentVariable("DATABASE_PUBLIC_URL")
        ?? Environment.GetEnvironmentVariable("DATABASE_URL")
        ?? "";
}
```

Supports multiple environment variable formats for Railway, Render, and Supabase deployments.

### 6.2 PostgreSQL URI Parsing (Lines 66–81)

```csharp
// Converts postgresql://user:pass@host:port/db → Npgsql connection string
if (connectionString.StartsWith("postgres://") || connectionString.StartsWith("postgresql://"))
{
    var uri = new Uri(connectionString);
    connectionString = $"Host={uri.Host};Port={uri.Port};Database={uri.AbsolutePath.TrimStart('/')};...";
}
```

### 6.3 Connection Retry with InMemory Fallback (Lines 85–126)

```csharp
int retries = 3;
while (retries > 0)
{
    try
    {
        using var testConn = new Npgsql.NpgsqlConnection(connectionString);
        testConn.Open();
        Console.WriteLine("[DB System] Successfully connected to PostgreSQL!");
        break;
    }
    catch (Exception ex)
    {
        retries--;
        if (retries == 0)
        {
            Console.WriteLine($"[DB Notice] PostgreSQL connection failed. Using InMemory Database.");
            useInMemory = true;
        }
        else
        {
            Thread.Sleep(5000); // Wait for Supabase cold start
        }
    }
}

// Final provider registration
if (useInMemory)
    builder.Services.AddDbContext<ApplicationDbContext>(o => o.UseInMemoryDatabase("SkillBridgeDb"));
else
    builder.Services.AddDbContext<ApplicationDbContext>(o => o.UseNpgsql(connectionString));
```

### 6.4 Database Initialization on Startup (Lines 172–184)

```csharp
using (var scope = app.Services.CreateScope())
{
    var dbInitializer = scope.ServiceProvider.GetRequiredService<IDbInitializer>();
    dbInitializer.Initialize();
    Console.WriteLine("[DB System] Database initialized and seeded successfully.");
}
```

---

## 7. Deployment Infrastructure

### 7.1 Backend — Render.com (Docker)

**File:** [`Dockerfile`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/backend/SkillBridge.Api/Dockerfile)

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["SkillBridge.Api.csproj", "."]
RUN dotnet restore "SkillBridge.Api.csproj"
COPY . .
RUN dotnet publish "SkillBridge.Api.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://+:${PORT:-8080}
ENV ASPNETCORE_ENVIRONMENT=Production
ENTRYPOINT ["dotnet", "SkillBridge.Api.dll"]
```

The Render.com deployment injects the Supabase PostgreSQL connection string via the `ConnectionStrings__DefaultConnection` environment variable from [`.env.render`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/backend/SkillBridge.Api/.env.render).

### 7.2 Frontend — Vercel

**File:** [`vercel.json`](file:///c:/Users/rashi/Documents/GitHub/SkillBridge/web_app/vercel.json)

```json
{ "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }] }
```

Deployed at: `https://skill-bridge-eight.vercel.app` (configured in CORS policy via `ALLOWED_ORIGINS`).

### 7.3 CORS Configuration (Lines 158–167 in Program.cs)

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.SetIsOriginAllowed(_ => true)
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});
```

---

## 8. Evidence Summary Table

| Evidence Item | File | What It Proves |
|:---|:---|:---|
| **Npgsql NuGet package** | `SkillBridge.Api.csproj` L17 | PostgreSQL EF Core provider is declared as a project dependency |
| **Supabase connection string** | `.env.render` L7 | Production database is hosted on Supabase (ap-southeast-2) |
| **Local dev connection** | `appsettings.Development.json` L3 | Local dev uses PostgreSQL on localhost:5432 |
| **DbContext with 8 Component D DbSets** | `ApplicationDbContext.cs` L43-50 | All 8 Component D tables registered in EF Core |
| **3 EF Core migrations** | `Migrations/` directory | Schema evolved via code-first migrations tracked in `__EFMigrationsHistory` |
| **544-line SQL migration script** | `supabase_migration.sql` | Full DDL for 30+ tables + seed data executed on Supabase SQL Editor |
| **UseNpgsql() in Program.cs** | `Program.cs` L124-125 | PostgreSQL provider registered in DI container at startup |
| **3-retry connection logic** | `Program.cs` L87-113 | Resilient connection handling with Supabase cold-start retry |
| **URI → Npgsql parsing** | `Program.cs` L66-81 | Supports Railway/Render `postgresql://` URI format conversion |
| **Docker multi-stage build** | `Dockerfile` | Production containerized deployment on Render.com |
| **Vercel CORS origin** | `.env.render` L16 | Frontend at `skill-bridge-eight.vercel.app` allowed |

---

*End of PostgreSQL Deployment Evidence*
