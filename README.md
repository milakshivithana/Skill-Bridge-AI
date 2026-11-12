# SkillBridge AI 🎯
### Intelligent Internship & Recruitment Coordination System
> **SE3090: Software Engineering Frameworks** — Group Assignment 1

---

## 📌 Project Overview

**SkillBridge AI** is a full-stack, cross-platform, agentic AI-powered recruitment coordination system that automates candidate-vacancy matching, interview scheduling, and recruiter approval workflows using a four-agent LangGraph pipeline with Human-in-the-Loop (HITL) controls.

---

## 🏗️ Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  Flutter Mobile │     │   React Web App  │
│  (Candidate)    │     │  (Recruiter/     │
│                 │     │   Admin)         │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └───────────┬───────────┘
                     │ HTTP (JWT)
         ┌───────────▼───────────┐
         │  ASP.NET Core Web API │
         │  (C# — Sole Backend)  │
         └──────┬──────────┬─────┘
                │           │
    ┌───────────▼──┐  ┌─────▼──────────────┐
    │  PostgreSQL   │  │  Python AI Service  │
    │  (EF Core)    │  │  (LangGraph/FastAPI)│
    └───────────────┘  └─────────────────────┘
```

---

## 👥 Team & Component Division

| Component | Member | Domain |
|-----------|--------|--------|
| **A** | Saadh M.Z.M (IT24103236) | Candidate Profile & Skill Management |
| **B** | Vithana M.S (IT24103200) | Vacancy & Application Management |
| **C** | Jayarathne K.P.S.U (IT24103553) | Interview & Scheduling Management |
| **D** | Ahamed M.N.R (IT24103157) | Shortlisting, Approval & Analytics |

---

## 🤖 Agentic AI Pipeline

1. **Planning Agent** — Converts recruitment objective into a multi-step plan
2. **Candidate Profile Analysis Agent** — Builds structured candidate summary from CV & skills
3. **Job Matching & Interview Agent** — Calculates match score (e.g. 84%) & proposes interview slots
4. **Validation & Fairness Agent** — Applies deterministic rules, schema checks & HITL routing

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend API | ASP.NET Core 8 Web API (C#) |
| Database | PostgreSQL + EF Core (Npgsql) |
| Web Frontend | React + TypeScript + Vite |
| Mobile App | Flutter & Dart |
| Agentic AI | Python + LangGraph + FastAPI |
| Auth | JWT Bearer Tokens (Role-based) |
| CI/CD | GitHub Actions |

---

## 🚀 Getting Started

### 1. Backend (ASP.NET Core)
```bash
cd backend
dotnet restore
dotnet ef database update --project SkillBridge.Api
dotnet run --project SkillBridge.Api
# API runs at: https://localhost:5001
```

### 2. Web App (React)
```bash
cd web_app
npm install
npm run dev
# Runs at: http://localhost:5173
```

### 3. AI Service (Python)
```bash
cd ai_service
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
# Runs at: http://localhost:8000
```

### 4. Mobile App (Flutter)
```bash
cd mobile_app
flutter pub get
flutter run
```

---

## ✅ CI/CD

GitHub Actions automatically runs on every push and PR to `main`:
- ✅ `dotnet restore` — restore backend dependencies
- ✅ `dotnet build` — build in Release mode
- ✅ `dotnet test` — run all xUnit tests

---

## 📁 Project Structure

```
SkillBridge/
├── .github/workflows/    # GitHub Actions CI/CD
├── backend/
│   ├── SkillBridge.Api/  # ASP.NET Core Web API
│   └── SkillBridge.Tests/# xUnit Tests
├── web_app/              # React TypeScript App
├── ai_service/           # Python LangGraph AI Service
│   └── app/agents/       # 4 Specialized AI Agents
├── mobile_app/           # Flutter Mobile App
└── docs/adr/             # Architecture Decision Records
```

---

## 📄 License
Academic project — SE3090, 2026.
