"""
SkillBridge AI — Validation & Fairness Agent
=============================================
Role 4 of 4 in the multi-agent recruitment pipeline.

Responsibilities:
  - Apply a 4-gate deterministic validation pipeline to every AI recommendation
    before it reaches a human recruiter.
  - Gate 1 (Allowed-Attribute Check): Ensure no protected characteristics
    (age, gender, race, religion, etc.) are present in the candidate payload.
  - Gate 2 (Eligibility Check): Validate candidate meets vacancy hard requirements
    (skills overlap, minimum experience, location match).
  - Gate 3 (Schema / Match-Calculation Check): Verify the match result object
    produced by the Job Matching Agent is structurally valid and internally
    consistent (scores in range, breakdown sums correct).
  - Gate 4 (HITL Routing): Route to the Human-in-the-Loop recruiter approval queue
    if and only if all 3 prior gates pass. Reject automatically otherwise.

Tools used:
  - validate_allowed_attributes(input_data)
  - validate_eligibility(candidate_profile, vacancy_requirements)
  - validate_match_calculation(match_result)
  - request_approval(workflow_id, summary, match_score, candidate_id, vacancy_id)

Output contract (keys guaranteed in return dict):
  agent, candidate_id, vacancy_id, workflow_id,
  gate_results (list of 4 gate dicts),
  validation_passed (bool), approval_status (str),
  approval_request (dict | None),
  requires_human_approval (bool),
  rejection_reasons (list[str]),
  summary, started_at, completed_at
"""

from __future__ import annotations

import datetime
from typing import Any, Dict, List, Optional

from app.tools.allowlisted_tools import (
    request_approval,
    validate_allowed_attributes,
    validate_eligibility,
    validate_match_calculation,
)


class ValidationFairnessAgent:
    """
    Validation & Fairness Agent.

    Runs 4 deterministic gates on each AI-generated recommendation.
    All gates must pass before the workflow is routed to the HITL queue.
    Any gate failure results in automatic rejection with a detailed reason.
    """

    def __init__(self) -> None:
        self.role_name = "Validation & Fairness Agent"

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def validate_and_route(
        self,
        candidate_profile: Dict[str, Any],
        match_result: Dict[str, Any],
        vacancy_requirements: Optional[Dict[str, Any]] = None,
        workflow_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Run the 4-gate validation pipeline and emit a full ValidationReport.

        Gate execution order:
          1. validate_allowed_attributes() — must pass before any other gate.
          2. validate_eligibility()        — hard eligibility rules.
          3. validate_match_calculation()  — structural schema check.
          4. request_approval()            — HITL routing (only if gates 1–3 pass).

        Args:
            candidate_profile   : Output dict from CandidateAnalysisAgent.
            match_result        : Output dict from JobMatchingAgent.
            vacancy_requirements: Optional vacancy dict for eligibility check
                                  (if None, a default vacancy is synthesised
                                  from the match_result context).
            workflow_id         : Optional workflow identifier string. If None,
                                  one is auto-generated.

        Returns:
            Full ValidationReport dict (see module docstring for contract).

        Raises:
            TypeError : If candidate_profile or match_result are not dicts.
        """
        if not isinstance(candidate_profile, dict):
            raise TypeError("candidate_profile must be a dict.")
        if not isinstance(match_result, dict):
            raise TypeError("match_result must be a dict.")

        started_at = datetime.datetime.utcnow().isoformat() + "Z"

        candidate_id = candidate_profile.get("candidate_id", 0)
        vacancy_id   = match_result.get("vacancy_id", 0)

        if workflow_id is None:
            workflow_id = f"wf-{candidate_id}-{vacancy_id}"

        # Synthesise minimal vacancy_requirements if not provided
        if vacancy_requirements is None:
            vacancy_requirements = self._synthesise_vacancy_requirements(match_result)

        gate_results: List[Dict[str, Any]] = []
        all_passed = True
        rejection_reasons: List[str] = []

        # ── Gate 1: Allowed-Attribute Check ─────────────────────────────
        gate1 = self._run_gate_1(candidate_profile, gate_results, rejection_reasons)
        if not gate1:
            all_passed = False

        # ── Gate 2: Eligibility Check ────────────────────────────────────
        gate2 = self._run_gate_2(
            candidate_profile, vacancy_requirements, gate_results, rejection_reasons
        )
        if not gate2:
            all_passed = False

        # ── Gate 3: Schema / Match-Calculation Check ─────────────────────
        gate3 = self._run_gate_3(match_result, gate_results, rejection_reasons)
        if not gate3:
            all_passed = False

        # ── Gate 4: HITL Routing ─────────────────────────────────────────
        approval_request = None
        if gate1 and gate3:
            approval_request = self._run_gate_4(
                workflow_id, candidate_id, vacancy_id,
                match_result, gate_results,
            )
            approval_status = "PENDING_RECRUITER_APPROVAL"
        else:
            gate_results.append({
                "gate": 4,
                "name": "HITL Routing",
                "tool": "request_approval",
                "passed": False,
                "detail": "Skipped — prior gate(s) failed. Evaluation withheld; no hiring decision made.",
            })
            approval_status = "REJECTED_BY_VALIDATION"

        completed_at = datetime.datetime.utcnow().isoformat() + "Z"

        # Human-readable summary
        if all_passed:
            summary_text = (
                f"All 4 validation gates PASSED for candidate_id={candidate_id}, "
                f"vacancy_id={vacancy_id}. Match score: {match_result.get('match_score', 0)}%. "
                f"Routed to Human-in-the-Loop recruiter approval queue."
            )
        else:
            summary_text = (
                f"Validation FAILED for candidate_id={candidate_id}, "
                f"vacancy_id={vacancy_id}. Reasons: {'; '.join(rejection_reasons)}"
            )

        return {
            # Agent metadata
            "agent": self.role_name,
            "started_at": started_at,
            "completed_at": completed_at,

            # Context
            "candidate_id": candidate_id,
            "vacancy_id": vacancy_id,
            "workflow_id": workflow_id,

            # Gate results (4 gates)
            "gate_results": gate_results,

            # Overall outcome
            "validation_passed": all_passed,
            "approval_status": approval_status,
            "approval_request": approval_request,
            "requires_human_approval": gate1 and gate3,
            "rejection_reasons": rejection_reasons,

            "summary": summary_text,
        }

    # ------------------------------------------------------------------
    # Gate runners (each appends to gate_results in place)
    # ------------------------------------------------------------------

    def _run_gate_1(
        self,
        candidate_profile: Dict[str, Any],
        gate_results: List[Dict[str, Any]],
        rejection_reasons: List[str],
    ) -> bool:
        """
        Gate 1 — Allowed-Attribute Check.

        Calls validate_allowed_attributes() on the candidate profile.
        Fails if any disallowed key (age, gender, race, etc.) is detected.
        """
        result = validate_allowed_attributes(candidate_profile)
        passed = result["valid"]

        gate_results.append({
            "gate": 1,
            "name": "Allowed-Attribute Check",
            "tool": "validate_allowed_attributes",
            "passed": passed,
            "detail": (
                "No disallowed attributes detected. Profile is bias-compliant."
                if passed
                else f"Disallowed attributes found: {result['disallowed_detected']}."
            ),
            "disallowed_detected": result.get("disallowed_detected", []),
        })

        if not passed:
            rejection_reasons.append(
                f"Gate 1 FAILED: disallowed attributes in profile: "
                f"{result['disallowed_detected']}."
            )
        return passed

    def _run_gate_2(
        self,
        candidate_profile: Dict[str, Any],
        vacancy_requirements: Dict[str, Any],
        gate_results: List[Dict[str, Any]],
        rejection_reasons: List[str],
    ) -> bool:
        """
        Gate 2 — Eligibility Check.

        Calls validate_eligibility() with candidate profile and vacancy requirements.
        Evaluates 3 hard rules: skill overlap, minimum experience, location match.
        """
        result = validate_eligibility(candidate_profile, vacancy_requirements)
        pending = [r["text"] for r in vacancy_requirements.get("requirements", []) if r.get("non_negotiable")]
        if pending:
            result["eligible"] = False
            result["failure_reasons"].append("Non-negotiable qualifications require human review: " + "; ".join(pending))
        passed = result["eligible"]

        gate_results.append({
            "gate": 2,
            "name": "Eligibility Check",
            "tool": "validate_eligibility",
            "passed": passed,
            "rule_results": result.get("rule_results", []),
            "detail": (
                "All eligibility rules passed."
                if passed
                else f"Eligibility failures: {result['failure_reasons']}"
            ),
            "failure_reasons": result.get("failure_reasons", []),
        })

        if not passed:
            for reason in result.get("failure_reasons", []):
                rejection_reasons.append(f"Gate 2 FAILED: {reason}")
        return passed

    def _run_gate_3(
        self,
        match_result: Dict[str, Any],
        gate_results: List[Dict[str, Any]],
        rejection_reasons: List[str],
    ) -> bool:
        """
        Gate 3 — Schema / Match-Calculation Validation.

        Calls validate_match_calculation() to verify the match result object
        is structurally correct and internally consistent.
        """
        result = validate_match_calculation(match_result)
        passed = result["all_checks_passed"]

        gate_results.append({
            "gate": 3,
            "name": "Schema & Match-Calculation Check",
            "tool": "validate_match_calculation",
            "passed": passed,
            "checks": {
                "schema_valid":          result.get("schema_valid"),
                "score_in_range":        result.get("score_in_range"),
                "recommendation_valid":  result.get("recommendation_valid"),
                "breakdown_consistent":  result.get("breakdown_consistent"),
            },
            "detail": (
                "Match result schema and score breakdown are valid."
                if passed
                else f"Validation errors: {result['validation_errors']}"
            ),
            "validation_errors": result.get("validation_errors", []),
        })

        if not passed:
            for err in result.get("validation_errors", []):
                rejection_reasons.append(f"Gate 3 FAILED: {err}")
        return passed

    def _run_gate_4(
        self,
        workflow_id: str,
        candidate_id: int,
        vacancy_id: int,
        match_result: Dict[str, Any],
        gate_results: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """
        Gate 4 — HITL Routing.

        Calls request_approval() to place the workflow in the recruiter queue.
        Only reached if Gates 1–3 all passed.
        """
        match_score = match_result.get("match_score", 0.0)
        recommendation = match_result.get("recommendation", "SUITABLE_FOR_RECRUITER_REVIEW")
        missing = match_result.get("missing_required_skills", [])

        approval_summary = (
            f"AI pipeline completed successfully. Match score: {match_score}%. "
            f"Recommendation: {recommendation}. "
            f"Missing preferred skills: {missing if missing else 'None'}. "
            f"Awaiting recruiter decision."
        )

        approval_request = request_approval(
            workflow_id=workflow_id,
            summary=approval_summary,
            match_score=match_score,
            candidate_id=candidate_id,
            vacancy_id=vacancy_id,
        )

        gate_results.append({
            "gate": 4,
            "name": "HITL Routing",
            "tool": "request_approval",
            "passed": True,
            "approval_request_id": approval_request.get("approval_request_id"),
            "detail": (
                "Workflow successfully placed in Human-in-the-Loop recruiter approval queue. "
                "No recruitment action will be taken until a Recruiter approves, rejects, "
                "or requests revision via the React web portal."
            ),
        })

        return approval_request

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _synthesise_vacancy_requirements(match_result: Dict[str, Any]) -> Dict[str, Any]:
        """
        Build a minimal vacancy_requirements dict from match_result context
        when no explicit vacancy data is passed to validate_and_route().

        Args:
            match_result: Output dict from JobMatchingAgent.

        Returns:
            Minimal vacancy requirements dict compatible with validate_eligibility().
        """
        all_matched = match_result.get("matched_skills", [])
        missing     = match_result.get("missing_required_skills", [])
        return {
            "required_skills": all_matched + missing,
            "preferred_skills": match_result.get("matched_preferred_skills", []),
            "min_experience_years": match_result.get("min_experience_years", 0),
            "location": "Colombo",  # default
        }
