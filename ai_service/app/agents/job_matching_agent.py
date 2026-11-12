"""
SkillBridge AI — Job Matching & Interview Agent
================================================
Role 3 of 4 in the multi-agent recruitment pipeline.

Responsibilities:
  - Retrieve vacancy requirements via allow-listed tool.
  - Calculate a deterministic match score comparing candidate skills against
    vacancy requirements (no probabilistic LLM scoring).
  - Identify missing mandatory skills for the recruiter HITL report.
  - Propose a conflict-free interview slot from the interviewer's availability.
  - Emit a structured match result dict that the Validation Agent can validate.

Tools used:
  - get_vacancy_requirements(vacancy_id)
  - calculate_match_score(candidate_skills, required_skills, preferred_skills)
  - get_available_interview_slots(interviewer_id, target_date)

Scoring formula (deterministic):
  required_component  = (matched_required  / total_required)  * 80.0
  preferred_component = (matched_preferred / total_preferred) * 20.0
  total_score         = min(100.0, required_component + preferred_component)

Output contract (keys guaranteed in return dict):
  agent, vacancy_id, vacancy_title, match_score, mandatory_passed,
  matched_skills, missing_required_skills, matched_preferred_skills,
  score_breakdown, recommendation, proposed_interview_slot,
  slot_selection_reason, started_at, completed_at
"""

from __future__ import annotations

import datetime
from typing import Any, Dict, List, Optional

from app.tools.allowlisted_tools import (
    calculate_match_score,
    get_available_interview_slots,
    get_vacancy_requirements,
)


class JobMatchingAgent:
    """
    Job Matching & Interview Agent.

    Deterministically evaluates how well a candidate's declared skills match
    a vacancy's requirements, and selects the most suitable conflict-free
    interview time slot.
    """

    # Default interviewer and interview date used for slot proposals
    DEFAULT_INTERVIEWER_ID = 1
    DEFAULT_TARGET_DATE    = "2026-09-25"

    def __init__(self) -> None:
        self.role_name = "Job Matching & Interview Agent"

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def match_and_plan_interview(
        self,
        candidate_skills: List[str],
        vacancy_id: int,
        interviewer_id: int = DEFAULT_INTERVIEWER_ID,
        target_date: str = DEFAULT_TARGET_DATE,
        mock_vacancy_db: Optional[Dict[int, Dict[str, Any]]] = None,
        vacancy_data: Optional[Dict[str, Any]] = None,
        profile_evidence: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Perform skills matching and propose an interview slot.

        Executes three tool calls in sequence:
          1. get_vacancy_requirements()       → vacancy skill/experience requirements
          2. calculate_match_score()          → deterministic match score + breakdown
          3. get_available_interview_slots()  → available time slots for the interviewer

        The slot selection rule:
          - Prefer the SECOND available slot (avoids the earliest, giving prep time).
          - Fall back to the first slot if only one is available.
          - If no slots are available, proposed_interview_slot is None.

        Args:
            candidate_skills : List of skill names from the candidate profile.
            vacancy_id       : ID of the vacancy to match against.
            interviewer_id   : ID of the interviewer for slot lookup (default 1).
            target_date      : ISO date string for interview scheduling (YYYY-MM-DD).
            mock_vacancy_db  : Optional mock override for get_vacancy_requirements().

        Returns:
            Structured dict with match result, score breakdown, missing skills,
            proposed interview slot, and slot selection reasoning.

        Raises:
            ValueError: If candidate_skills is empty or vacancy_id is invalid.
        """
        if not isinstance(candidate_skills, list):
            raise ValueError("candidate_skills must be a list of strings.")
        if not isinstance(vacancy_id, int) or vacancy_id <= 0:
            raise ValueError("vacancy_id must be a positive integer.")

        started_at = datetime.datetime.utcnow().isoformat() + "Z"

        # ── Tool call 1: Vacancy requirements ───────────────────────────
        persisted_evidence = vacancy_data is not None
        vacancy_data = vacancy_data if persisted_evidence else get_vacancy_requirements(vacancy_id, mock_db=mock_vacancy_db)
        required_skills  = vacancy_data.get("required_skills",  [])
        preferred_skills = vacancy_data.get("preferred_skills", [])

        # ── Tool call 2: Match score calculation ────────────────────────
        match_result = calculate_match_score(
            candidate_skills=candidate_skills,
            required_skills=required_skills,
            preferred_skills=preferred_skills,
        )

        # ── Tool call 3: Available interview slots ───────────────────────
        available_slots = [] if persisted_evidence else get_available_interview_slots(
            interviewer_id=interviewer_id,
            target_date=target_date,
        )
        proposed_slot, slot_reason = self._select_best_slot(available_slots)

        # ── Eligibility gate ────────────────────────────────────────────
        # Hard-fail: if any mandatory skill is missing, mark NOT_RECOMMENDED
        # (redundant with calculate_match_score but explicit for audit trail)
        mandatory_failed_skills = match_result.get("missing_required_skills", [])
        eligibility_gate_passed = len(mandatory_failed_skills) == 0 and not any(
            r.get("non_negotiable") for r in vacancy_data.get("requirements", [])
        )

        completed_at = datetime.datetime.utcnow().isoformat() + "Z"

        return {
            # Agent metadata
            "agent": self.role_name,
            "started_at": started_at,
            "completed_at": completed_at,

            # Vacancy context
            "vacancy_id": vacancy_id,
            "vacancy_title": vacancy_data.get("title", "Unknown"),
            "min_experience_years": vacancy_data.get("min_experience_years", 0),

            # Match scoring
            "match_score": match_result["match_score"],
            "mandatory_passed": match_result["mandatory_passed"],
            "eligibility_gate_passed": eligibility_gate_passed,
            "matched_skills": match_result["matched_skills"],
            "matched_required_skills": match_result["matched_required_skills"],
            "missing_preferred_skills": match_result["missing_preferred_skills"],
            "missing_required_skills": match_result["missing_required_skills"],
            "matched_preferred_skills": match_result.get("matched_preferred_skills", []),
            "score_breakdown": match_result.get("score_breakdown", {}),
            "recommendation": match_result["recommendation"],

            # Unstructured qualifications are evidence for HITL, not automatic points.
            "education_evidence": (profile_evidence or {}).get("education", []),
            "experience_evidence": (profile_evidence or {}).get("experience", []),
            "requirements_review": [dict(r, result="REQUIRES_HUMAN_REVIEW") for r in vacancy_data.get("requirements", [])],
            "reasoning": "Skill overlap only; completeness, unrelated education and mere experience presence add no points. Qualifications and non-negotiable text require recruiter review.",

            # Interview scheduling
            "available_slots_count": len(available_slots),
            "proposed_interview_slot": proposed_slot,
            "slot_selection_reason": slot_reason,
        }

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _select_best_slot(
        available_slots: List[Dict[str, Any]],
    ) -> tuple[Optional[Dict[str, Any]], str]:
        """
        Choose the most suitable available interview slot.

        Selection strategy:
          - If >= 2 slots: choose index 1 (second slot) to allow candidate prep time.
          - If exactly 1 slot: choose index 0 (only option available).
          - If 0 slots: return (None, reason explaining no availability).

        Args:
            available_slots: List of slot dicts from get_available_interview_slots().

        Returns:
            Tuple of (selected_slot_dict_or_None, reason_string).
        """
        if len(available_slots) >= 2:
            return (
                available_slots[1],
                "Second available slot selected to allow candidate preparation time.",
            )
        elif len(available_slots) == 1:
            return (
                available_slots[0],
                "Only one slot available — assigned as the proposed interview time.",
            )
        else:
            return (
                None,
                "No available interview slots found for the requested interviewer and date.",
            )
