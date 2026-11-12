"""
SkillBridge AI — FastAPI Internal Microservice
===============================================
Internal agentic AI service called exclusively by the ASP.NET Core Web API
backend. Never exposed directly to React or Flutter clients.

Endpoints:
  GET  /health                          — Liveness probe
  POST /api/ai/workflow/execute         — Full 4-agent workflow execution
  GET  /api/ai/workflow/{workflow_id}/status — Workflow status query
  POST /api/ai/tools/validate           — Standalone validation tool endpoint
  POST /api/ai/tools/match              — Standalone match-score tool endpoint

Architecture:
  All requests are routed through SkillBridgeWorkflowGraph which orchestrates
  the 4 agents in sequence. The raw workflow output is returned to the
  ASP.NET Core backend which persists AIWorkflow, AIWorkflowStep, and
  AIToolExecution records to PostgreSQL before sending the final status
  back to the React/Flutter clients.
"""

from __future__ import annotations

import datetime
import logging
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, field_validator

from app.agents.workflow_graph import SkillBridgeWorkflowGraph
from app.agents.candidate_analysis_agent import CandidateAnalysisAgent
from app.schemas.candidate_schemas import CandidateAnalysisRequest, CandidateProfileSummary
from app.tools.allowlisted_tools import (
    calculate_match_score,
    get_workflow_status,
    validate_allowed_attributes,
    validate_eligibility,
    validate_match_calculation,
)

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("skillbridge_ai")

# ---------------------------------------------------------------------------
# App initialisation
# ---------------------------------------------------------------------------
app = FastAPI(
    title="SkillBridge Agentic AI Microservice",
    version="2.0.0",
    description=(
        "Internal Agentic AI Service for SkillBridge. "
        "Orchestrates Planning, Candidate Analysis, Job Matching, and "
        "Validation & Fairness agents. Called exclusively by the ASP.NET "
        "Core Web API backend."
    ),
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5264", "http://localhost:5000"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Singleton workflow graph (compiled once at startup)
_workflow_graph = SkillBridgeWorkflowGraph()

# ---------------------------------------------------------------------------
# Request / Response models
# ---------------------------------------------------------------------------

class VacancyEvidence(BaseModel):
    vacancy_id: int = Field(..., gt=0)
    title: str
    description: str = ""
    required_skills: list[str]
    preferred_skills: list[str]
    requirements: list[dict[str, Any]] = Field(default_factory=list)


class WorkflowRequest(BaseModel):
    """Request body for the full 4-agent workflow execution."""

    objective: str = Field(
        ...,
        min_length=5,
        example="Evaluate candidate application for Software Engineering Intern vacancy.",
    )
    candidate_id: int = Field(..., gt=0, example=1)
    vacancy_id:   int = Field(..., gt=0, example=1)

    profile_data: Dict[str, Any]
    vacancy_data: VacancyEvidence

    @field_validator("objective")
    @classmethod
    def objective_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("objective must not be blank.")
        return v.strip()


class ValidateRequest(BaseModel):
    """Request body for the standalone validation endpoint."""

    candidate_profile: Dict[str, Any] = Field(
        ...,
        example={
            "candidate_id": 1,
            "skills": ["React", "SQL", "Git"],
            "education": "BSc IT",
            "experience_years": 1,
            "location_preference": "Colombo",
        },
    )
    match_result: Dict[str, Any] = Field(
        ...,
        example={
            "match_score": 84.0,
            "mandatory_passed": True,
            "recommendation": "SUITABLE_FOR_RECRUITER_REVIEW",
        },
    )
    vacancy_requirements: Optional[Dict[str, Any]] = Field(
        default=None,
        example={
            "required_skills": ["React", "SQL"],
            "preferred_skills": ["Docker"],
            "min_experience_years": 0,
            "location": "Colombo",
        },
    )


class MatchRequest(BaseModel):
    """Request body for the standalone match-score endpoint."""

    candidate_skills: List[str] = Field(..., example=["React", "SQL", "Git", "C#"])
    required_skills:  List[str] = Field(..., example=["React", "SQL", "Git"])
    preferred_skills: List[str] = Field(default_factory=list, example=["Docker", "C#"])


# ---------------------------------------------------------------------------
# Middleware — request/response logging
# ---------------------------------------------------------------------------

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log every incoming request and its response status code."""
    start = datetime.datetime.utcnow()
    logger.info("▶  %s %s", request.method, request.url.path)
    response = await call_next(request)
    duration = (datetime.datetime.utcnow() - start).total_seconds() * 1000
    logger.info(
        "◀  %s %s → %d (%.1fms)",
        request.method, request.url.path, response.status_code, duration,
    )
    return response


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.get("/health", tags=["System"])
def health_check() -> Dict[str, Any]:
    """
    Liveness probe for the AI microservice.

    Returns:
        JSON with status, service name, version, and current UTC timestamp.
    """
    return {
        "status": "HEALTHY",
        "service": "SkillBridge Agentic AI Microservice",
        "version": "2.0.0",
        "agents": [
            "Planning Agent",
            "Candidate Profile Analysis Agent",
            "Job Matching & Interview Agent",
            "Validation & Fairness Agent",
        ],
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
    }


@app.post("/api/ai/workflow/execute", tags=["Workflow"])
def execute_workflow(request: WorkflowRequest) -> Dict[str, Any]:
    """
    Execute the full 4-agent recruitment workflow.

    Runs the SkillBridgeWorkflowGraph which orchestrates:
      1. Planning Agent        — creates execution plan
      2. Candidate Analysis    — builds enriched profile
      3. Job Matching          — calculates match score & interview slot
      4. Validation & Fairness — 4-gate validation + HITL routing

    The ASP.NET Core backend calls this endpoint, receives the full workflow
    output, and persists AIWorkflow/AIWorkflowStep/AIToolExecution records
    to PostgreSQL before returning the result to the client.

    Args:
        request: WorkflowRequest body with objective, candidate_id, vacancy_id.

    Returns:
        Full workflow execution result including all agent outputs, execution
        trace, timing, and final HITL routing decision.

    Raises:
        HTTPException 422: If request validation fails.
        HTTPException 500: If any agent raises an unhandled exception.
    """
    logger.info(
        "Executing workflow: candidate_id=%d, vacancy_id=%d, objective='%s'",
        request.candidate_id, request.vacancy_id, request.objective[:60],
    )
    try:
        result = _workflow_graph.execute(
            candidate_id=request.candidate_id,
            vacancy_id=request.vacancy_id,
            objective=request.objective,
            profile_data=request.profile_data,
            vacancy_data=request.vacancy_data.model_dump(),
        )
        logger.info(
            "Workflow %s completed: status=%s, duration=%.1fms",
            result.get("workflow_id"),
            result.get("status"),
            result.get("total_duration_ms", 0),
        )
        return result
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))
    except Exception as exc:
        logger.exception("Workflow execution error: %s", exc)
        raise HTTPException(status_code=500, detail=str(exc))


@app.get("/api/ai/workflow/{workflow_id}/status", tags=["Workflow"])
def get_workflow_status_endpoint(workflow_id: str) -> Dict[str, Any]:
    """
    Query the current execution status of an AI workflow.

    Args:
        workflow_id: Workflow identifier (e.g. 'wf-1-3').

    Returns:
        Status dict from the workflow registry.

    Raises:
        HTTPException 400: If workflow_id is blank.
    """
    if not workflow_id.strip():
        raise HTTPException(status_code=400, detail="workflow_id must not be blank.")
    return get_workflow_status(workflow_id)


@app.post("/api/ai/tools/validate", tags=["Tools"])
def run_validation(request: ValidateRequest) -> Dict[str, Any]:
    """
    Run the full 4-gate validation pipeline as a standalone endpoint.

    Useful for testing the Validation & Fairness Agent in isolation,
    or for re-validating an existing candidate/match pair without running
    the full workflow.

    Args:
        request: ValidateRequest body with candidate_profile, match_result,
                 and optional vacancy_requirements.

    Returns:
        Full ValidationReport dict from ValidationFairnessAgent.

    Raises:
        HTTPException 500: On unexpected errors.
    """
    from app.agents.validation_fairness_agent import ValidationFairnessAgent

    try:
        agent = ValidationFairnessAgent()
        return agent.validate_and_route(
            candidate_profile=request.candidate_profile,
            match_result=request.match_result,
            vacancy_requirements=request.vacancy_requirements,
        )
    except Exception as exc:
        logger.exception("Validation tool error: %s", exc)
        raise HTTPException(status_code=500, detail=str(exc))


@app.post("/api/ai/tools/match", tags=["Tools"])
def run_match_score(request: MatchRequest) -> Dict[str, Any]:
    """
    Run the deterministic match-score calculation as a standalone endpoint.

    Useful for testing the scoring algorithm in isolation or for ad-hoc
    skill-matching queries from the ASP.NET Core backend.

    Args:
        request: MatchRequest body with candidate_skills, required_skills,
                 and optional preferred_skills.

    Returns:
        Match result dict from calculate_match_score().

    Raises:
        HTTPException 422: On invalid input.
        HTTPException 500: On unexpected errors.
    """
    try:
        return calculate_match_score(
            candidate_skills=request.candidate_skills,
            required_skills=request.required_skills,
            preferred_skills=request.preferred_skills,
        )
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))
    except Exception as exc:
        logger.exception("Match score tool error: %s", exc)
        raise HTTPException(status_code=500, detail=str(exc))


@app.post("/api/ai/candidate/analyze", response_model=CandidateProfileSummary)
def analyze_candidate_profile(request: CandidateAnalysisRequest) -> CandidateProfileSummary:
    """Summarize supplied qualifications and gaps; never make a hiring decision."""
    try:
        return CandidateAnalysisAgent().analyze_profile(
            candidate_id=request.candidate_id,
            profile_data=request.profile_data,
            target_role=request.target_role,
        )
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Candidate profile analysis failed")
        raise HTTPException(status_code=503, detail="Candidate analysis is unavailable.") from exc
