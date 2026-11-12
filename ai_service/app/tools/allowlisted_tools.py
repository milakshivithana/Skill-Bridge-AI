"""
SkillBridge AI — Allow-listed Tool Registry
============================================
All tools available to the 4 specialized agents. Each tool enforces strict
schema validation on inputs and outputs. Only job-relevant attributes are
permitted — no protected characteristics (age, gender, race, religion, etc.).

Tool Ownership:
  Planning Agent          : get_workflow_status, delegate_task
  Candidate Analysis Agent: get_candidate_profile, get_candidate_skills,
                            get_candidate_experience
  Job Matching Agent      : get_vacancy_requirements, calculate_match_score,
                            get_available_interview_slots
  Validation Agent        : validate_eligibility, validate_match_calculation,
                            validate_allowed_attributes, request_approval
"""

from __future__ import annotations

import datetime
import time
from typing import Any, Dict, List, Optional


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

_DISALLOWED_KEYS: frozenset[str] = frozenset(
    {"age", "gender", "race", "religion", "marital_status",
     "salary_history", "nationality", "ethnicity", "disability"}
)

_WORKFLOW_REGISTRY: Dict[str, Dict[str, Any]] = {}  # in-memory store (demo)


# ===========================================================================
# PLANNING AGENT TOOLS
# ===========================================================================

def get_workflow_status(workflow_id: str) -> Dict[str, Any]:
    """
    Retrieve the current execution status of an AI workflow by its ID.

    Args:
        workflow_id: Unique identifier of the workflow (e.g. 'wf-1-3').

    Returns:
        Dict containing workflow_id, status, steps_completed, steps_total,
        last_updated, and any error message.

    Raises:
        ValueError: If workflow_id is empty or None.
    """
    if not workflow_id:
        raise ValueError("workflow_id must be a non-empty string.")

    record = _WORKFLOW_REGISTRY.get(workflow_id)
    if record is None:
        return {
            "workflow_id": workflow_id,
            "status": "NOT_FOUND",
            "steps_completed": 0,
            "steps_total": 4,
            "last_updated": None,
            "error": None,
        }

    return {
        "workflow_id": workflow_id,
        "status": record.get("status", "IN_PROGRESS"),
        "steps_completed": record.get("steps_completed", 0),
        "steps_total": record.get("steps_total", 4),
        "last_updated": record.get("last_updated"),
        "error": record.get("error"),
    }


def delegate_task(
    agent_name: str,
    task_description: str,
    context: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Delegate a sub-task from the Planning Agent to a downstream agent.

    Args:
        agent_name      : Name of the target agent (must match one of the 4 roles).
        task_description: Human-readable description of the task to execute.
        context         : Key-value context payload passed to the target agent.

    Returns:
        Dict with delegation_id, agent_name, task_description, context,
        status, and delegated_at timestamp.

    Raises:
        ValueError: If agent_name is not one of the 4 recognized roles.
    """
    VALID_AGENTS = {
        "Candidate Profile Analysis Agent",
        "Job Matching & Interview Agent",
        "Validation & Fairness Agent",
        "Planning Agent",
    }
    if agent_name not in VALID_AGENTS:
        raise ValueError(
            f"Unknown agent '{agent_name}'. Must be one of: {sorted(VALID_AGENTS)}"
        )
    if not task_description.strip():
        raise ValueError("task_description must not be empty.")

    delegation_id = f"dlg-{agent_name[:4].lower().replace(' ', '')}-{int(time.time() * 1000) % 100000}"
    return {
        "delegation_id": delegation_id,
        "agent_name": agent_name,
        "task_description": task_description,
        "context_keys": list(context.keys()),
        "status": "DELEGATED",
        "delegated_at": datetime.datetime.utcnow().isoformat() + "Z",
    }


# ===========================================================================
# CANDIDATE PROFILE ANALYSIS AGENT TOOLS
# ===========================================================================

def get_candidate_profile(
    candidate_id: int,
    mock_db: Optional[Dict[int, Dict[str, Any]]] = None,
) -> Dict[str, Any]:
    """
    Retrieve a job-relevant candidate profile.

    Only returns attributes that are on the allow-list (education, skills,
    experience, location preference). Protected characteristics are never
    included.

    Args:
        candidate_id: Integer ID of the candidate.
        mock_db     : Optional override dict for testing.

    Returns:
        Dict with candidate_id, name, education, skills, experience_years,
        location_preference, and cv_parsed_summary.

    Raises:
        ValueError: If candidate_id is not a positive integer.
    """
    if not isinstance(candidate_id, int) or candidate_id <= 0:
        raise ValueError("candidate_id must be a positive integer.")

    if mock_db and candidate_id in mock_db:
        return mock_db[candidate_id]

    return {
        "candidate_id": candidate_id,
        "name": f"Candidate {candidate_id}",
        "education": "BSc (Hons) in Information Technology",
        "skills": ["React", "Java", "SQL", "Git", "C#", "ASP.NET Core"],
        "experience_years": 2,
        "location_preference": "Colombo",
        "cv_parsed_summary": (
            "Hands-on experience in full-stack web development and REST APIs. "
            "Strong academic background in software engineering fundamentals."
        ),
    }


def get_candidate_skills(
    candidate_id: int,
    mock_db: Optional[Dict[int, List[Dict[str, str]]]] = None,
) -> List[Dict[str, str]]:
    """
    Retrieve the structured skill list for a candidate with proficiency levels.

    Args:
        candidate_id: Integer ID of the candidate.
        mock_db     : Optional override for testing.

    Returns:
        List of dicts, each with 'skill_name' and 'proficiency_level'
        (Beginner | Intermediate | Expert).

    Raises:
        ValueError: If candidate_id is not a positive integer.
    """
    if not isinstance(candidate_id, int) or candidate_id <= 0:
        raise ValueError("candidate_id must be a positive integer.")

    if mock_db and candidate_id in mock_db:
        return mock_db[candidate_id]

    return [
        {"skill_name": "React",        "proficiency_level": "Expert"},
        {"skill_name": "Java",         "proficiency_level": "Intermediate"},
        {"skill_name": "SQL",          "proficiency_level": "Intermediate"},
        {"skill_name": "Git",          "proficiency_level": "Expert"},
        {"skill_name": "C#",           "proficiency_level": "Intermediate"},
        {"skill_name": "ASP.NET Core", "proficiency_level": "Intermediate"},
    ]


def get_candidate_experience(
    candidate_id: int,
    mock_db: Optional[Dict[int, List[Dict[str, Any]]]] = None,
) -> List[Dict[str, Any]]:
    """
    Retrieve structured work experience records for a candidate.

    Args:
        candidate_id: Integer ID of the candidate.
        mock_db     : Optional override for testing.

    Returns:
        List of dicts with company_name, job_title, duration_months,
        and description. Never includes salary history.

    Raises:
        ValueError: If candidate_id is not a positive integer.
    """
    if not isinstance(candidate_id, int) or candidate_id <= 0:
        raise ValueError("candidate_id must be a positive integer.")

    if mock_db and candidate_id in mock_db:
        return mock_db[candidate_id]

    return [
        {
            "company_name": "TechCorp Lanka (Pvt) Ltd",
            "job_title": "Junior Software Engineer (Intern)",
            "duration_months": 6,
            "description": "Developed React dashboards and REST APIs using ASP.NET Core.",
        },
        {
            "company_name": "University IT Department",
            "job_title": "Part-time Web Developer",
            "duration_months": 12,
            "description": "Maintained university web portal using Java Spring and SQL.",
        },
    ]


# ===========================================================================
# JOB MATCHING & INTERVIEW AGENT TOOLS
# ===========================================================================

def get_vacancy_requirements(
    vacancy_id: int,
    mock_db: Optional[Dict[int, Dict[str, Any]]] = None,
) -> Dict[str, Any]:
    """
    Retrieve structured job requirements for a vacancy.

    Args:
        vacancy_id: Integer ID of the vacancy.
        mock_db   : Optional override for testing.

    Returns:
        Dict with vacancy_id, title, required_skills, preferred_skills,
        min_experience_years, and location.

    Raises:
        ValueError: If vacancy_id is not a positive integer.
    """
    if not isinstance(vacancy_id, int) or vacancy_id <= 0:
        raise ValueError("vacancy_id must be a positive integer.")

    if mock_db and vacancy_id in mock_db:
        return mock_db[vacancy_id]

    return {
        "vacancy_id": vacancy_id,
        "title": "Software Engineering Intern",
        "required_skills": ["React", "SQL", "Git"],
        "preferred_skills": ["Docker", "C#"],
        "min_experience_years": 0,
        "location": "Colombo",
    }


def calculate_match_score(
    candidate_skills: List[str],
    required_skills: List[str],
    preferred_skills: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Deterministically calculate the candidate-vacancy match score.

    Scoring formula (deterministic, no probabilistic LLM involved):
      - Required skills component : (matched_required / total_required) * 80.0
      - Preferred skills component: (matched_preferred / total_preferred) * 20.0
      - Total capped at 100.0

    Args:
        candidate_skills: List of skill names the candidate declares.
        required_skills : List of mandatory skills the vacancy requires.
        preferred_skills: List of nice-to-have skills (default empty).

    Returns:
        Dict with match_score (float), mandatory_passed (bool),
        matched_skills, missing_required_skills, matched_preferred_skills,
        score_breakdown, and recommendation string.

    Raises:
        ValueError: If candidate_skills or required_skills are not lists.
    """
    if not isinstance(candidate_skills, list):
        raise ValueError("candidate_skills must be a list of strings.")
    if not isinstance(required_skills, list):
        raise ValueError("required_skills must be a list of strings.")

    preferred_skills = preferred_skills or []
    required_skills = list({s.strip().casefold(): s.strip() for s in required_skills if s.strip()}.values())
    preferred_skills = list({s.strip().casefold(): s.strip() for s in preferred_skills if s.strip() and s.strip().casefold() not in {r.casefold() for r in required_skills}}.values())
    if not required_skills and not preferred_skills:
        raise ValueError("Vacancy has no structured skills; no defensible match score can be calculated.")
    candidate_set = {s.strip().casefold() for s in candidate_skills}

    matched_required   = [s for s in required_skills  if s.casefold() in candidate_set]
    missing_required   = [s for s in required_skills  if s.casefold() not in candidate_set]
    matched_preferred  = [s for s in preferred_skills if s.casefold() in candidate_set]

    # Preserve the established 80/20 priority when both groups exist; no free
    # points for absent criteria. A sole group is normalized to 100.
    req_weight = 80.0 if preferred_skills else 100.0
    pref_weight = 20.0 if required_skills else 100.0
    req_score = len(matched_required) / len(required_skills) * req_weight if required_skills else 0.0
    pref_score = len(matched_preferred) / len(preferred_skills) * pref_weight if preferred_skills else 0.0
    total_score = min(100.0, round(req_score + pref_score, 2))
    mandatory_passed = len(missing_required) == 0

    return {
        "match_score": total_score,
        "mandatory_passed": mandatory_passed,
        "matched_skills": matched_required + matched_preferred,
        "matched_required_skills": matched_required,
        "missing_preferred_skills": [s for s in preferred_skills if s.casefold() not in candidate_set],
        "missing_required_skills": missing_required,
        "matched_preferred_skills": matched_preferred,
        "score_breakdown": {
            "required_component":  round(req_score, 2),
            "preferred_component": round(pref_score, 2),
        },
        "recommendation": (
            "SUITABLE_FOR_RECRUITER_REVIEW" if mandatory_passed else "NOT_RECOMMENDED"
        ),
    }


def get_available_interview_slots(
    interviewer_id: int = 1,
    target_date: str = "2026-09-25",
) -> List[Dict[str, Any]]:
    """
    Retrieve conflict-free available interview slots for a given interviewer.

    Args:
        interviewer_id: ID of the interviewer (default 1).
        target_date   : ISO date string (YYYY-MM-DD) for the interview day.

    Returns:
        List of slot dicts with slot_id, interviewer_id, start_time,
        end_time, and is_booked (always False for available slots).

    Raises:
        ValueError: If target_date is not a valid YYYY-MM-DD string.
    """
    try:
        datetime.date.fromisoformat(target_date)
    except ValueError:
        raise ValueError(f"target_date must be YYYY-MM-DD, got '{target_date}'.")

    return [
        {
            "slot_id": 101,
            "interviewer_id": interviewer_id,
            "start_time": f"{target_date}T09:00:00Z",
            "end_time":   f"{target_date}T09:45:00Z",
            "is_booked": False,
        },
        {
            "slot_id": 102,
            "interviewer_id": interviewer_id,
            "start_time": f"{target_date}T14:00:00Z",
            "end_time":   f"{target_date}T14:45:00Z",
            "is_booked": False,
        },
        {
            "slot_id": 103,
            "interviewer_id": interviewer_id,
            "start_time": f"{target_date}T15:30:00Z",
            "end_time":   f"{target_date}T16:15:00Z",
            "is_booked": False,
        },
    ]


# ===========================================================================
# VALIDATION & FAIRNESS AGENT TOOLS
# ===========================================================================

def validate_allowed_attributes(input_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Ensure no protected/sensitive non-job-related attributes are present in
    the candidate payload submitted to the AI pipeline.

    Disallowed keys: age, gender, race, religion, marital_status,
                     salary_history, nationality, ethnicity, disability.

    Args:
        input_data: The dict payload that will be evaluated by downstream agents.

    Returns:
        Dict with valid (bool) and disallowed_detected (list of offending keys).

    Raises:
        TypeError: If input_data is not a dict.
    """
    if hasattr(input_data, "model_dump"):
        input_data = input_data.model_dump()
    if not isinstance(input_data, dict):
        raise TypeError("input_data must be a dict.")

    detected = [k for k in input_data if k.lower() in _DISALLOWED_KEYS]
    return {
        "valid": len(detected) == 0,
        "disallowed_detected": detected,
    }


def validate_eligibility(
    candidate_profile: Dict[str, Any],
    vacancy_requirements: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Apply deterministic eligibility rules between a candidate and a vacancy.

    Rules enforced:
      1. Candidate must have at least one skill in the required_skills list.
      2. Candidate experience_years must meet min_experience_years.
      3. Candidate location_preference must match vacancy location (case-insensitive).

    Args:
        candidate_profile   : Output of get_candidate_profile().
        vacancy_requirements: Output of get_vacancy_requirements().

    Returns:
        Dict with eligible (bool), rule_results (list of per-rule outcomes),
        and failure_reasons (list of strings, empty if eligible).

    Raises:
        KeyError: If required fields are missing from either dict.
    """
    required_keys_candidate = {"skills", "experience_years", "location_preference"}
    required_keys_vacancy   = {"required_skills"}

    for k in required_keys_candidate:
        if k not in candidate_profile:
            raise KeyError(f"candidate_profile is missing required field: '{k}'")
    for k in required_keys_vacancy:
        if k not in vacancy_requirements:
            raise KeyError(f"vacancy_requirements is missing required field: '{k}'")

    rule_results: List[Dict[str, Any]] = []
    failure_reasons: List[str] = []

    # Rule 1 — At least one required skill
    cand_skills_lower = {s.lower() for s in candidate_profile["skills"]}
    req_skills_lower  = {s.lower() for s in vacancy_requirements["required_skills"]}
    has_any_req_skill = req_skills_lower.issubset(cand_skills_lower)
    rule_results.append({
        "rule": "has_all_required_skills",
        "passed": has_any_req_skill,
    })
    if not has_any_req_skill:
        failure_reasons.append(
            "Candidate is missing required skills for this vacancy."
        )

    # Rule 2 — Minimum experience
    exp_ok = candidate_profile["experience_years"] >= vacancy_requirements.get("min_experience_years", 0)
    rule_results.append({
        "rule": "meets_minimum_experience",
        "passed": exp_ok,
        "candidate_years": candidate_profile["experience_years"],
        "required_years":  vacancy_requirements.get("min_experience_years", 0),
    })
    if not exp_ok:
        failure_reasons.append(
            f"Candidate has {candidate_profile['experience_years']} year(s) experience; "
            f"{vacancy_requirements['min_experience_years']} required."
        )

    # Rule 3 — Location match
    loc_ok = (
        not vacancy_requirements.get("location") or
        (candidate_profile.get("location_preference") or "").lower()
        == vacancy_requirements["location"].lower()
    )
    rule_results.append({
        "rule": "location_preference_matches",
        "passed": loc_ok,
        "candidate_location": candidate_profile["location_preference"],
        "vacancy_location":   vacancy_requirements.get("location"),
    })
    if not loc_ok:
        failure_reasons.append(
            f"Candidate prefers '{candidate_profile['location_preference']}' but "
            f"vacancy is in '{vacancy_requirements['location']}'."
        )

    return {
        "eligible": len(failure_reasons) == 0,
        "rule_results": rule_results,
        "failure_reasons": failure_reasons,
    }


def validate_match_calculation(match_result: Dict[str, Any]) -> Dict[str, Any]:
    """
    Validate the structural integrity and business-rule compliance of a
    match score result produced by the Job Matching Agent.

    Checks:
      - Required keys present: match_score, mandatory_passed, recommendation.
      - match_score is a float in [0.0, 100.0].
      - mandatory_passed is a boolean.
      - recommendation is one of the allowed values.
      - score_breakdown components sum correctly (within floating-point tolerance).

    Args:
        match_result: Output dict from calculate_match_score().

    Returns:
        Dict with schema_valid (bool), score_in_range (bool),
        breakdown_consistent (bool), all_checks_passed (bool),
        and validation_errors (list of strings).

    Raises:
        TypeError: If match_result is not a dict.
    """
    if not isinstance(match_result, dict):
        raise TypeError("match_result must be a dict.")

    errors: List[str] = []
    REQUIRED_KEYS = {"match_score", "mandatory_passed", "recommendation"}
    ALLOWED_RECOMMENDATIONS = {"SUITABLE_FOR_RECRUITER_REVIEW", "NOT_RECOMMENDED"}

    # Schema check
    missing = REQUIRED_KEYS - match_result.keys()
    schema_valid = len(missing) == 0
    if not schema_valid:
        errors.append(f"Missing required keys: {sorted(missing)}")

    # Range check
    score = match_result.get("match_score", -1)
    score_in_range = isinstance(score, (int, float)) and 0.0 <= score <= 100.0
    if not score_in_range:
        errors.append(f"match_score '{score}' is out of range [0.0, 100.0].")

    # Recommendation enum check
    rec = match_result.get("recommendation", "")
    rec_valid = rec in ALLOWED_RECOMMENDATIONS
    if not rec_valid:
        errors.append(
            f"recommendation '{rec}' is not one of {sorted(ALLOWED_RECOMMENDATIONS)}."
        )

    # Breakdown consistency (optional but validated if present)
    breakdown_consistent = True
    breakdown = match_result.get("score_breakdown")
    if breakdown:
        req_c  = breakdown.get("required_component",  0)
        pref_c = breakdown.get("preferred_component", 0)
        computed = round(req_c + pref_c, 2)
        if abs(computed - round(score, 2)) > 1.0:   # 1-point tolerance
            breakdown_consistent = False
            errors.append(
                f"score_breakdown ({req_c} + {pref_c} = {computed}) "
                f"inconsistent with match_score ({score})."
            )

    return {
        "schema_valid": schema_valid,
        "score_in_range": score_in_range,
        "recommendation_valid": rec_valid,
        "breakdown_consistent": breakdown_consistent,
        "all_checks_passed": len(errors) == 0,
        "validation_errors": errors,
    }


def request_approval(
    workflow_id: str,
    summary: str,
    match_score: float,
    candidate_id: int,
    vacancy_id: int,
) -> Dict[str, Any]:
    """
    Route a validated AI workflow to the Human-in-the-Loop (HITL) recruiter
    approval queue. This is the final step before any recruitment action is taken.

    Args:
        workflow_id : Unique workflow identifier.
        summary     : Human-readable summary of the AI recommendation.
        match_score : Final calculated match score (0–100).
        candidate_id: Candidate being evaluated.
        vacancy_id  : Vacancy being applied to.

    Returns:
        Dict with approval_request_id, workflow_id, status
        (always PENDING_RECRUITER_APPROVAL), routed_at, and summary.

    Raises:
        ValueError: If match_score is outside [0, 100] or workflow_id is empty.
    """
    if not workflow_id:
        raise ValueError("workflow_id must not be empty.")
    if not (0.0 <= match_score <= 100.0):
        raise ValueError(f"match_score must be in [0, 100], got {match_score}.")

    approval_id = f"apr-{workflow_id}-{int(time.time() * 1000) % 100000}"

    # Register in workflow registry so get_workflow_status() reflects HITL state
    _WORKFLOW_REGISTRY[workflow_id] = {
        "status": "PENDING_RECRUITER_APPROVAL",
        "steps_completed": 4,
        "steps_total": 4,
        "last_updated": datetime.datetime.utcnow().isoformat() + "Z",
        "error": None,
    }

    return {
        "approval_request_id": approval_id,
        "workflow_id": workflow_id,
        "candidate_id": candidate_id,
        "vacancy_id": vacancy_id,
        "match_score": match_score,
        "summary": summary,
        "status": "PENDING_RECRUITER_APPROVAL",
        "routed_at": datetime.datetime.utcnow().isoformat() + "Z",
        "message": (
            "Workflow has been placed in the Human-in-the-Loop recruiter approval queue. "
            "No recruitment action will be taken until the recruiter approves, rejects, "
            "or requests revision via the React web portal."
        ),
    }


# Candidate API adapters preserve the stashed CamelCase tool contracts while
# leaving structured snake_case tools used by the workflow unchanged.
getCandidateProfile = get_candidate_profile


def getCandidateSkills(candidate_id, mock_db=None):
    return [item["skill_name"] if isinstance(item, dict) else item
            for item in get_candidate_skills(candidate_id, mock_db)]


def getCandidateExperience(candidate_id, mock_db=None):
    if mock_db is not None and candidate_id in mock_db:
        return mock_db[candidate_id]
    profile = get_candidate_profile(candidate_id)
    return {
        "candidate_id": candidate_id,
        "experience_years": profile.get("experience_years", 0),
        "education": profile.get("education", ""),
        "cv_summary": profile.get("cv_parsed_summary", ""),
    }
