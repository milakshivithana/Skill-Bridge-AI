"""
SkillBridge AI — Workflow Graph Orchestrator
=============================================
LangGraph-compatible multi-agent workflow orchestrator for the SkillBridge
recruitment AI pipeline.

Architecture (4-node directed graph):
  ┌─────────┐     ┌──────────────────┐     ┌─────────────────┐     ┌───────────────────┐
  │  plan   │────▶│ analyze_profile  │────▶│  match_jobs     │────▶│ validate_and_route│
  └─────────┘     └──────────────────┘     └─────────────────┘     └───────────────────┘
                                                                            │
                                               ┌─────────────────────────────┘
                                               ▼
                                    if validation_passed:
                                      → PENDING_RECRUITER_APPROVAL
                                    else:
                                      → REJECTED_BY_VALIDATION

State:
  WorkflowState (TypedDict) is passed through all nodes. Each node
  reads from and writes to the shared state, accumulating the full
  execution trace that is returned to the caller and persisted by
  the ASP.NET Core backend.

Usage:
    graph = SkillBridgeWorkflowGraph()
    result = graph.execute(
        candidate_id=1,
        vacancy_id=1,
        objective="Evaluate candidate for Software Engineering Intern vacancy."
    )
"""

from __future__ import annotations

import datetime
import time
import uuid
from typing import Any, Dict, List, Optional

from app.agents.candidate_analysis_agent import CandidateAnalysisAgent
from app.agents.job_matching_agent import JobMatchingAgent
from app.agents.planner_agent import PlanningAgent, WorkflowState
from app.agents.validation_fairness_agent import ValidationFairnessAgent


# ---------------------------------------------------------------------------
# Node functions (LangGraph-compatible signature: state → state)
# ---------------------------------------------------------------------------

def node_plan(state: WorkflowState) -> WorkflowState:
    """
    Node 1 — Planning.

    Invokes PlanningAgent.create_execution_plan() and writes the plan
    into the shared workflow state.

    Args:
        state: Shared WorkflowState dict.

    Returns:
        Updated WorkflowState with 'plan' key populated.
    """
    agent = PlanningAgent()
    plan = agent.create_execution_plan(
        objective=state["objective"],
        candidate_id=state["candidate_id"],
        vacancy_id=state["vacancy_id"],
    )
    state["plan"] = plan
    state["current_step"] = 1
    state["status"] = "PLANNING_COMPLETE"
    return state


def node_analyze_profile(state: WorkflowState) -> WorkflowState:
    """
    Node 2 — Candidate Profile Analysis.

    Invokes CandidateAnalysisAgent.analyze_profile() and writes the
    enriched profile into the shared workflow state.

    Args:
        state: Shared WorkflowState dict (must contain 'candidate_id').

    Returns:
        Updated WorkflowState with 'profile_analysis' key populated.
    """
    agent = CandidateAnalysisAgent()
    profile = agent.analyze_profile(candidate_id=state["candidate_id"], profile_data=state["profile_data"]).model_dump()
    state["profile_analysis"] = profile
    state["current_step"] = 2
    state["status"] = "PROFILE_ANALYSIS_COMPLETE"
    return state


def node_match_jobs(state: WorkflowState) -> WorkflowState:
    """
    Node 3 — Job Matching & Interview Planning.

    Invokes JobMatchingAgent.match_and_plan_interview() using the candidate
    skills extracted in the previous node and writes the match result into state.

    Args:
        state: Shared WorkflowState dict (must contain 'profile_analysis' and 'vacancy_id').

    Returns:
        Updated WorkflowState with 'match_result' key populated.

    Raises:
        RuntimeError: If profile_analysis is not yet in state.
    """
    if "profile_analysis" not in state:
        raise RuntimeError("node_match_jobs requires 'profile_analysis' in state.")

    agent = JobMatchingAgent()
    candidate_skills = state["profile_analysis"].get("skills", [])
    match = agent.match_and_plan_interview(
        candidate_skills=candidate_skills,
        vacancy_id=state["vacancy_id"],
        vacancy_data=state.get("vacancy_data"),
        profile_evidence=state.get("profile_data"),
    )
    state["match_result"] = match
    state["current_step"] = 3
    state["status"] = "MATCHING_COMPLETE"
    return state


def node_validate_and_route(state: WorkflowState) -> WorkflowState:
    """
    Node 4 — Validation & HITL Routing.

    Invokes ValidationFairnessAgent.validate_and_route() using the candidate
    profile and match result from prior nodes.

    Args:
        state: Shared WorkflowState dict (must contain 'profile_analysis'
               and 'match_result').

    Returns:
        Updated WorkflowState with 'validation_result' key populated and
        final 'status' set to the approval outcome.

    Raises:
        RuntimeError: If profile_analysis or match_result are not in state.
    """
    if "profile_analysis" not in state or "match_result" not in state:
        raise RuntimeError(
            "node_validate_and_route requires 'profile_analysis' and 'match_result' in state."
        )

    agent = ValidationFairnessAgent()
    validation = agent.validate_and_route(
        candidate_profile=state["profile_analysis"],
        match_result=state["match_result"],
        workflow_id=state.get("workflow_id"),
        vacancy_requirements=state.get("vacancy_data"),
    )
    state["validation_result"] = validation
    state["current_step"] = 4
    state["status"] = validation.get("approval_status", "UNKNOWN")
    return state


# ---------------------------------------------------------------------------
# Workflow Graph
# ---------------------------------------------------------------------------

class SkillBridgeWorkflowGraph:
    """
    LangGraph-compatible multi-agent workflow graph for SkillBridge AI.

    Orchestrates the 4 specialized agents as a directed acyclic graph (DAG)
    with conditional routing after the Validation node.

    Nodes (in execution order):
      1. plan               — PlanningAgent
      2. analyze_profile    — CandidateAnalysisAgent
      3. match_jobs         — JobMatchingAgent
      4. validate_and_route — ValidationFairnessAgent

    The graph is compiled once at instantiation and executed via execute().
    """

    # Ordered list of node functions (DAG edges are implicit sequential)
    _NODES = [
        node_plan,
        node_analyze_profile,
        node_match_jobs,
        node_validate_and_route,
    ]

    def __init__(self) -> None:
        """Build and compile the workflow graph."""
        self._graph = self._build_graph()

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def execute(
        self,
        candidate_id: int,
        vacancy_id: int,
        objective: str,
        profile_data: Optional[Dict[str, Any]] = None,
        vacancy_data: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Execute the full 4-agent recruitment workflow and return a complete
        execution trace.

        Args:
            candidate_id: Positive integer ID of the candidate.
            vacancy_id  : Positive integer ID of the vacancy.
            objective   : Human-readable recruitment goal string.

        Returns:
            Dict containing:
              - workflow_id         : Unique workflow identifier.
              - objective           : The original objective string.
              - candidate_id        : Integer candidate ID.
              - vacancy_id          : Integer vacancy ID.
              - status              : Final workflow status.
              - plan                : PlanningAgent output.
              - profile_analysis    : CandidateAnalysisAgent output.
              - match_result        : JobMatchingAgent output.
              - validation_result   : ValidationFairnessAgent output.
              - requires_human_approval: bool.
              - final_recommendation: recommendation string.
              - execution_trace     : Per-node timing and status records.
              - started_at          : Workflow start ISO timestamp.
              - completed_at        : Workflow end ISO timestamp.
              - total_duration_ms   : Integer total execution time.

        Raises:
            ValueError : If IDs or objective are invalid.
            RuntimeError: If any node raises an unhandled exception.
        """
        if not isinstance(candidate_id, int) or candidate_id <= 0:
            raise ValueError("candidate_id must be a positive integer.")
        if not isinstance(vacancy_id, int) or vacancy_id <= 0:
            raise ValueError("vacancy_id must be a positive integer.")
        if not objective.strip():
            raise ValueError("objective must be a non-empty string.")

        if not isinstance(profile_data, dict) or not isinstance(vacancy_data, dict):
            raise ValueError("Both persisted candidate and vacancy evidence are required.")
        if profile_data.get("candidate_id") != candidate_id or vacancy_data.get("vacancy_id") != vacancy_id:
            raise ValueError("Evidence does not belong to this candidate/vacancy.")
        workflow_id = f"wf-{candidate_id}-{vacancy_id}-{uuid.uuid4().hex}"
        workflow_start = time.perf_counter()
        started_at = datetime.datetime.utcnow().isoformat() + "Z"

        # Initialise shared state
        state: WorkflowState = WorkflowState(
            workflow_id=workflow_id,
            objective=objective,
            candidate_id=candidate_id,
            vacancy_id=vacancy_id,
            current_step=0,
            status="INITIALISED",
            errors=[],
            started_at=started_at,
            completed_at=None,
            plan=None,
            profile_analysis=None,
            match_result=None,
            validation_result=None,
        )

        if profile_data is not None:
            state["profile_data"] = profile_data
            state["vacancy_data"] = vacancy_data

        execution_trace: List[Dict[str, Any]] = []

        # Run graph nodes sequentially
        for node_fn in self._graph:
            node_start = time.perf_counter()
            node_name = node_fn.__name__
            try:
                state = node_fn(state)
                duration_ms = round((time.perf_counter() - node_start) * 1000, 1)
                execution_trace.append({
                    "node": node_name,
                    "step": state.get("current_step"),
                    "status": "COMPLETED",
                    "duration_ms": duration_ms,
                    "output_status": state.get("status"),
                })
            except Exception as exc:
                duration_ms = round((time.perf_counter() - node_start) * 1000, 1)
                error_msg = f"Node '{node_name}' raised {type(exc).__name__}: {exc}"
                state["errors"].append(error_msg)
                state["status"] = "ERROR"
                execution_trace.append({
                    "node": node_name,
                    "step": state.get("current_step"),
                    "status": "ERROR",
                    "duration_ms": duration_ms,
                    "error": error_msg,
                })
                break  # Halt the graph on any node failure

        total_ms = round((time.perf_counter() - workflow_start) * 1000, 1)
        completed_at = datetime.datetime.utcnow().isoformat() + "Z"
        state["completed_at"] = completed_at

        validation_result = state.get("validation_result") or {}
        match_result      = state.get("match_result") or {}

        return {
            "workflow_id": workflow_id,
            "objective": objective,
            "candidate_id": candidate_id,
            "vacancy_id": vacancy_id,
            "status": state.get("status"),
            "plan": state.get("plan"),
            "profile_analysis": state.get("profile_analysis"),
            "match_result": match_result,
            "validation_result": validation_result,
            "requires_human_approval": validation_result.get("requires_human_approval", False),
            "final_recommendation": match_result.get("recommendation", "UNKNOWN"),
            "execution_trace": execution_trace,
            "errors": state.get("errors", []),
            "started_at": started_at,
            "completed_at": completed_at,
            "total_duration_ms": total_ms,
        }

    # ------------------------------------------------------------------
    # Graph builder (returns compiled node list)
    # ------------------------------------------------------------------

    @staticmethod
    def _build_graph() -> List:
        """
        Build the compiled workflow graph.

        Returns the ordered list of node functions representing the DAG edges.
        In a full LangGraph implementation this would return a CompiledGraph
        object with StateGraph, add_node(), add_edge(), and compile() calls.
        This implementation uses a sequential list for maximum compatibility
        without requiring the langgraph package as a dependency.
        """
        return [
            node_plan,
            node_analyze_profile,
            node_match_jobs,
            node_validate_and_route,
        ]
