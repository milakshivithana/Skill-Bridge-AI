"""
SkillBridge AI — Planning Agent
================================
Role 1 of 4 in the multi-agent recruitment pipeline.

Responsibilities:
  - Convert a high-level recruitment objective into a structured, ordered
    multi-step execution plan.
  - Delegate each step to the appropriate downstream agent via delegate_task().
  - Track workflow status via get_workflow_status().
  - Emit a full plan manifest with per-step agent assignment, task description,
    expected input/output schema, and timing metadata.

Tools used:
  - get_workflow_status(workflow_id)
  - delegate_task(agent_name, task_description, context)
"""

from __future__ import annotations

import datetime
import time
from typing import Any, Dict, List

from app.tools.allowlisted_tools import delegate_task, get_workflow_status


# ---------------------------------------------------------------------------
# State schema (LangGraph-compatible TypedDict)
# ---------------------------------------------------------------------------

class WorkflowState(dict):
    """
    Mutable state object passed between agents in the workflow graph.
    Follows LangGraph-compatible TypedDict structure.

    Keys:
        workflow_id        : Unique workflow identifier string.
        objective          : Original recruitment objective text.
        candidate_id       : Integer candidate ID.
        vacancy_id         : Integer vacancy ID.
        plan               : Output of PlanningAgent.create_execution_plan().
        profile_analysis   : Output of CandidateAnalysisAgent.analyze_profile().
        match_result       : Output of JobMatchingAgent.match_and_plan_interview().
        validation_result  : Output of ValidationFairnessAgent.validate_and_route().
        current_step       : Current step index (1–4).
        status             : Overall workflow status string.
        errors             : List of error messages (empty if clean).
        started_at         : ISO timestamp when the workflow began.
        completed_at       : ISO timestamp when the workflow finished (or None).
    """


# ---------------------------------------------------------------------------
# Planning Agent
# ---------------------------------------------------------------------------

class PlanningAgent:
    """
    Planning Agent — converts a recruitment objective into a structured
    execution plan and delegates tasks to the 3 downstream agents.
    """

    AGENT_SEQUENCE: List[Dict[str, str]] = [
        {
            "step_number": "1",
            "agent": "Candidate Profile Analysis Agent",
            "tool": "get_candidate_profile / get_candidate_skills / get_candidate_experience",
            "expected_output": "Structured candidate summary: education, skills (with proficiency), experience, location.",
        },
        {
            "step_number": "2",
            "agent": "Job Matching & Interview Agent",
            "tool": "get_vacancy_requirements / calculate_match_score / get_available_interview_slots",
            "expected_output": "Match score (0–100), mandatory pass/fail, missing skills, proposed interview slot.",
        },
        {
            "step_number": "3",
            "agent": "Validation & Fairness Agent",
            "tool": "validate_eligibility / validate_match_calculation / validate_allowed_attributes / request_approval",
            "expected_output": "4-gate validation report + HITL approval routing decision.",
        },
    ]

    def __init__(self) -> None:
        self.role_name = "Planning Agent"

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def create_execution_plan(
        self,
        objective: str,
        candidate_id: int,
        vacancy_id: int,
    ) -> Dict[str, Any]:
        """
        Build and return a structured multi-step execution plan.

        The plan is deterministically generated from the objective text and
        IDs — no LLM call is made at this stage. Each step records:
          - which agent is responsible
          - which allow-listed tools it will invoke
          - what output schema is expected
          - delegation metadata from delegate_task()

        Args:
            objective    : Human-readable recruitment goal.
            candidate_id : ID of the candidate being evaluated.
            vacancy_id   : ID of the vacancy being applied to.

        Returns:
            Dict with objective, candidate_id, vacancy_id, total_steps,
            steps (list), delegation_log (list), status, and created_at.

        Raises:
            ValueError: If objective is empty or IDs are not positive integers.
        """
        if not objective.strip():
            raise ValueError("objective must be a non-empty string.")
        if not isinstance(candidate_id, int) or candidate_id <= 0:
            raise ValueError("candidate_id must be a positive integer.")
        if not isinstance(vacancy_id, int) or vacancy_id <= 0:
            raise ValueError("vacancy_id must be a positive integer.")

        start_ts = datetime.datetime.utcnow().isoformat() + "Z"
        plan_steps: List[Dict[str, Any]] = []
        delegation_log: List[Dict[str, Any]] = []

        for template in self.AGENT_SEQUENCE:
            step_num = int(template["step_number"])
            task_desc = self._build_task_description(
                template, candidate_id, vacancy_id, objective
            )
            context = {
                "candidate_id": candidate_id,
                "vacancy_id": vacancy_id,
                "objective": objective,
            }

            # Delegate to downstream agent and record the delegation receipt
            delegation = delegate_task(
                agent_name=template["agent"],
                task_description=task_desc,
                context=context,
            )
            delegation_log.append(delegation)

            plan_steps.append({
                "step_number": step_num,
                "agent": template["agent"],
                "task_description": task_desc,
                "tools_to_invoke": template["tool"].split(" / "),
                "expected_output_schema": template["expected_output"],
                "delegation_id": delegation["delegation_id"],
                "status": "PLANNED",
            })

        return {
            "objective": objective,
            "candidate_id": candidate_id,
            "vacancy_id": vacancy_id,
            "total_steps": len(plan_steps),
            "steps": plan_steps,
            "delegation_log": delegation_log,
            "status": "PLAN_GENERATED",
            "created_at": start_ts,
        }

    def check_workflow_status(self, workflow_id: str) -> Dict[str, Any]:
        """
        Query the current execution status of a running workflow.

        Args:
            workflow_id: Unique workflow identifier (e.g. 'wf-1-3').

        Returns:
            Status dict from get_workflow_status() tool.
        """
        return get_workflow_status(workflow_id)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _build_task_description(
        template: Dict[str, str],
        candidate_id: int,
        vacancy_id: int,
        objective: str,
    ) -> str:
        """Construct a detailed natural-language task description for a step."""
        agent = template["agent"]
        if "Candidate" in agent:
            return (
                f"Retrieve and build a structured, job-relevant profile summary "
                f"for candidate_id={candidate_id}. Extract skills (with proficiency), "
                f"education, experience records, and location preference. "
                f"Objective context: '{objective}'."
            )
        elif "Matching" in agent:
            return (
                f"Compare the candidate profile (candidate_id={candidate_id}) against "
                f"vacancy requirements (vacancy_id={vacancy_id}). Calculate a deterministic "
                f"match score (required skills 80%, preferred skills 20%). Identify missing "
                f"mandatory skills and propose a conflict-free interview slot."
            )
        elif "Validation" in agent:
            return (
                f"Run all 4 deterministic validation gates on the match result for "
                f"candidate_id={candidate_id}, vacancy_id={vacancy_id}: "
                f"(1) Allowed-attribute check, (2) Eligibility rules, "
                f"(3) Schema validation, (4) Route to HITL recruiter approval if all pass."
            )
        return f"Execute step for candidate_id={candidate_id}, vacancy_id={vacancy_id}."
