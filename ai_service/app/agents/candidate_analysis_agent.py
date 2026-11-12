"""
SkillBridge AI — Candidate Profile Analysis Agent
==================================================
Role 2 of 4 in the multi-agent recruitment pipeline.

Responsibilities:
  - Retrieve raw candidate data via allow-listed tools.
  - Build a structured, job-relevant profile summary that downstream agents
    can consume safely (no protected characteristics included).
  - Compute a profile completeness score.
  - Produce a human-readable CV summary for the recruiter-facing HITL UI.

Tools used:
  - get_candidate_profile(candidate_id)
  - get_candidate_skills(candidate_id)
  - get_candidate_experience(candidate_id)

Output contract (keys guaranteed in return dict):
  agent, candidate_id, education, skills, skills_with_proficiency,
  experience_records, experience_years, total_experience_months,
  location_preference, profile_completeness_score, cv_summary, summary
"""

from __future__ import annotations

import datetime
from typing import Any, Dict, List, Optional
from app.schemas.candidate_schemas import CandidateProfileSummary
from app.tools.allowlisted_tools import (
    get_candidate_experience,
    get_candidate_profile,
    get_candidate_skills,
    validate_allowed_attributes,
)

_UNSET = object()

class WorkflowProfile(dict):
    """Keep the workflow mapping contract with attribute access for summary consumers."""
    def __getattr__(self, name):
        try:
            return self[name]
        except KeyError as exc:
            raise AttributeError(name) from exc





class CandidateAnalysisAgent:
    """
    Candidate Profile Analysis Agent.

    Builds a complete, structured, job-relevant candidate profile by
    orchestrating three allow-listed tool calls and enriching the raw data
    with computed fields (completeness score, experience months, CV summary).
    """

    COMPLETENESS_FIELDS = [
        "education",
        "skills",
        "experience_years",
        "location_preference",
        "cv_parsed_summary",
    ]

    def __init__(self) -> None:
        self.role_name = "Candidate Profile Analysis Agent"

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def analyze_profile(self, candidate_id, mock_profile_db=None, mock_skills_db=None,
                        mock_exp_db=None, *, profile_data=_UNSET, target_role=None):
        """Support both the workflow tool contract and the typed Candidate payload contract."""
        if not isinstance(candidate_id, int) or candidate_id <= 0:
            raise ValueError("candidate_id must be a positive integer.")
        if profile_data is not _UNSET or target_role is not None:
            return self.analyze_candidate(candidate_id,
                None if profile_data is _UNSET else profile_data, target_role)
        return WorkflowProfile(self._analyze_workflow_profile(
            candidate_id, mock_profile_db, mock_skills_db, mock_exp_db))

    def _analyze_workflow_profile(
        self,
        candidate_id: int,
        mock_profile_db: dict | None = None,
        mock_skills_db: dict | None = None,
        mock_exp_db: dict | None = None,
    ) -> Dict[str, Any]:
        """
        Retrieve and enrich a candidate's profile for downstream agent use.

        Orchestrates three tool calls:
          1. get_candidate_profile()  → base profile attributes
          2. get_candidate_skills()   → skills with proficiency levels
          3. get_candidate_experience() → structured work history

        Then computes:
          - Profile completeness percentage (0–100)
          - Total experience in months
          - Grouped skill breakdown by proficiency level
          - A human-readable CV summary paragraph

        Args:
            candidate_id     : Positive integer ID of the candidate.
            mock_profile_db  : Optional mock override for get_candidate_profile().
            mock_skills_db   : Optional mock override for get_candidate_skills().
            mock_exp_db      : Optional mock override for get_candidate_experience().

        Returns:
            Dict with all profile fields, enrichments, and agent metadata.

        Raises:
            ValueError: If candidate_id is not a positive integer.
        """
        if not isinstance(candidate_id, int) or candidate_id <= 0:
            raise ValueError("candidate_id must be a positive integer.")

        started_at = datetime.datetime.utcnow().isoformat() + "Z"

        # ── Tool call 1: Base profile ───────────────────────────────────
        raw_profile = get_candidate_profile(candidate_id, mock_db=mock_profile_db)

        # ── Tool call 2: Skills with proficiency ────────────────────────
        skills_structured = get_candidate_skills(candidate_id, mock_db=mock_skills_db)
        skills_by_level = self._group_skills_by_proficiency(skills_structured)

        # ── Tool call 3: Work experience ────────────────────────────────
        experience_records = get_candidate_experience(candidate_id, mock_db=mock_exp_db)
        total_exp_months = sum(r.get("duration_months", 0) for r in experience_records)

        # ── Derived computations ────────────────────────────────────────
        completeness_score = self._compute_completeness(raw_profile, skills_structured, experience_records)
        cv_summary = self._build_cv_summary(raw_profile, skills_by_level, experience_records)

        completed_at = datetime.datetime.utcnow().isoformat() + "Z"

        return {
            # Agent metadata
            "agent": self.role_name,
            "started_at": started_at,
            "completed_at": completed_at,

            # Core identity (no protected characteristics)
            "candidate_id": raw_profile["candidate_id"],
            "education": raw_profile["education"],
            "location_preference": raw_profile["location_preference"],

            # Skills
            "skills": raw_profile["skills"],
            "skills_with_proficiency": skills_structured,
            "skills_by_level": skills_by_level,

            # Experience
            "experience_years": raw_profile["experience_years"],
            "total_experience_months": total_exp_months,
            "experience_records": experience_records,

            # Computed enrichments
            "profile_completeness_score": completeness_score,
            "cv_summary": cv_summary,

            # Short summary for pipeline logging
            "summary": (
                f"Candidate {candidate_id} possesses {len(raw_profile['skills'])} declared skills "
                f"({len(skills_by_level.get('Expert', []))} Expert-level), "
                f"{total_exp_months} months of work experience, "
                f"and a profile completeness score of {completeness_score}%."
            ),
        }

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _group_skills_by_proficiency(
        skills_structured: List[Dict[str, str]],
    ) -> Dict[str, List[str]]:
        """
        Group skill names by their proficiency level.

        Args:
            skills_structured: List of dicts with 'skill_name' and 'proficiency_level'.

        Returns:
            Dict keyed by level ('Expert', 'Intermediate', 'Beginner'),
            values are lists of skill names.
        """
        grouped: Dict[str, List[str]] = {"Expert": [], "Intermediate": [], "Beginner": []}
        for entry in skills_structured:
            level = entry.get("proficiency_level", "Beginner")
            name  = entry.get("skill_name", "")
            if level in grouped:
                grouped[level].append(name)
            else:
                grouped.setdefault(level, []).append(name)
        return grouped

    @staticmethod
    def _compute_completeness(
        raw_profile: Dict[str, Any],
        skills_structured: List[Dict[str, str]],
        experience_records: List[Dict[str, Any]],
    ) -> int:
        """
        Calculate a profile completeness percentage (0–100).

        Scoring:
          - education present and non-empty    → 20 pts
          - at least 1 skill declared          → 20 pts
          - at least 1 experience record       → 20 pts
          - location_preference present        → 20 pts
          - cv_parsed_summary present          → 20 pts

        Args:
            raw_profile        : Output of get_candidate_profile().
            skills_structured  : Output of get_candidate_skills().
            experience_records : Output of get_candidate_experience().

        Returns:
            Integer percentage (0, 20, 40, 60, 80, or 100).
        """
        score = 0
        if raw_profile.get("education", "").strip():
            score += 20
        if skills_structured:
            score += 20
        if experience_records:
            score += 20
        if raw_profile.get("location_preference", "").strip():
            score += 20
        if raw_profile.get("cv_parsed_summary", "").strip():
            score += 20
        return score

    @staticmethod
    def _build_cv_summary(
        raw_profile: Dict[str, Any],
        skills_by_level: Dict[str, List[str]],
        experience_records: List[Dict[str, Any]],
    ) -> str:
        """
        Build a recruiter-readable plain-text CV summary paragraph.

        Args:
            raw_profile       : Base profile from get_candidate_profile().
            skills_by_level   : Grouped skills dict from _group_skills_by_proficiency().
            experience_records: Work history from get_candidate_experience().

        Returns:
            A formatted multi-sentence CV summary string.
        """
        expert_skills = skills_by_level.get("Expert", [])
        inter_skills  = skills_by_level.get("Intermediate", [])

        exp_titles = [r.get("job_title", "") for r in experience_records if r.get("job_title")]
        exp_companies = [r.get("company_name", "") for r in experience_records if r.get("company_name")]

        lines = [
            f"Education: {raw_profile.get('education', 'Not specified')}.",
        ]
        if expert_skills:
            lines.append(f"Expert-level skills: {', '.join(expert_skills)}.")
        if inter_skills:
            lines.append(f"Intermediate-level skills: {', '.join(inter_skills)}.")
        if exp_titles and exp_companies:
            roles = "; ".join(
                f"{t} at {c}" for t, c in zip(exp_titles, exp_companies)
            )
            lines.append(f"Work experience: {roles}.")
        lines.append(
            f"Preferred work location: {raw_profile.get('location_preference', 'Not specified')}."
        )
        return " ".join(lines)

    def analyze_candidate(
        self,
        candidate_id: int,
        profile_data: Optional[Dict[str, Any]] = None,
        target_role: Optional[str] = None,
    ) -> CandidateProfileSummary:
        """
        Analyzes a candidate's profile to build a structured, job-relevant summary.
        - Uses least-privilege allow-listed tools.
        - Identifies missing profile components.
        - Flags disallowed personal attributes (fairness & bias prevention).
        - Strictly summarizes qualifications without making hiring decisions.
        - Implements safe failure handling for empty/corrupt profiles.
        """
        disallowed_detected: List[str] = []

        # Step 1: Fairness & Disallowed Attribute Check on input data
        if profile_data and isinstance(profile_data, dict):
            attr_validation = validate_allowed_attributes(profile_data)
            if not attr_validation["valid"]:
                disallowed_detected = attr_validation["disallowed_detected"]

        # Step 2: Retrieve candidate profile data via allow-listed tools or provided payload
        # The supplied backend snapshot is authoritative; absent fields must stay missing.
        raw_profile = dict(profile_data) if isinstance(profile_data, dict) else {}

        # Step 3: Extract & normalize attributes
        full_name = raw_profile.get("fullName") or raw_profile.get("name") or f"Candidate #{candidate_id}"

        # Education extraction
        education_str = ""
        educations = raw_profile.get("educations") or raw_profile.get("education")
        if isinstance(educations, list) and educations:
            primary_edu = educations[0]
            if isinstance(primary_edu, dict):
                degree = primary_edu.get("degree", "")
                inst = primary_edu.get("institution", "")
                field = primary_edu.get("fieldOfStudy") or primary_edu.get("field_of_study", "")
                parts = [p for p in [degree, f"in {field}" if field else "", f"at {inst}" if inst else ""] if p]
                education_str = " ".join(parts).strip()
            else:
                education_str = str(primary_edu)
        elif isinstance(educations, str):
            education_str = educations
        # Skills extraction
        skills: List[str] = []
        raw_skills = raw_profile.get("skills")
        if isinstance(raw_skills, list):
            for s in raw_skills:
                if isinstance(s, dict):
                    skill_name = s.get("skillName") or s.get("name")
                    if skill_name:
                        skills.append(str(skill_name).strip())
                elif isinstance(s, str) and s.strip():
                    skills.append(s.strip())
        # Deduplicate skills preserving order
        deduped_skills: List[str] = []
        seen = set()
        for sk in skills:
            if sk.lower() not in seen:
                seen.add(sk.lower())
                deduped_skills.append(sk)
        skills = deduped_skills

        # Experience extraction
        experience_years = 0.0
        exp_raw = raw_profile.get("experience_years", raw_profile.get("experienceYears"))
        if exp_raw is not None:
            try:
                experience_years = self._nonnegative_number(exp_raw)
            except (ValueError, TypeError):
                experience_years = 0.0
        elif "experiences" in raw_profile or "experience" in raw_profile:
            experiences = raw_profile.get("experiences", raw_profile.get("experience"))
            if isinstance(experiences, list) and experiences:
                total_months = sum(self._nonnegative_number(e.get("durationMonths", e.get("duration_months", 0))) for e in experiences if isinstance(e, dict))
                experience_years = round(total_months / 12.0, 1) if total_months > 0 else 0.0
            else:
                experience_years = 0.0
        # Location preference extraction
        location_preference = raw_profile.get("location_preference") or raw_profile.get("locationPreference") or raw_profile.get("city")

        # CV Summary extraction
        cv_summary = (
            raw_profile.get("cv_parsed_summary")
            or raw_profile.get("cvSummary")
            or raw_profile.get("bio")
        )
        if not cv_summary and raw_profile.get("cvDocuments"):
            cv_docs = raw_profile.get("cvDocuments")
            if isinstance(cv_docs, list) and len(cv_docs) > 0 and isinstance(cv_docs[0], dict):
                cv_summary = f"Uploaded CV Document: {cv_docs[0].get('fileName', 'resume')}"

        full_name = full_name if isinstance(full_name, str) else None
        location_preference = location_preference if isinstance(location_preference, str) else None
        cv_summary = cv_summary if isinstance(cv_summary, str) else None

        # Step 4: Missing data analysis
        missing_data: List[str] = []
        if not skills:
            missing_data.append("skills")
        if not education_str.strip():
            missing_data.append("education")
        if experience_years <= 0 and not raw_profile.get("experiences"):
            missing_data.append("experience")
        if not cv_summary:
            missing_data.append("cv_document")
        if not location_preference:
            missing_data.append("location_preference")

        is_complete = len(missing_data) == 0

        # Step 5: Structured job-relevant synthesis (NO hiring decision made!)
        summary_parts = []
        if target_role:
            summary_parts.append(f"Target role: '{target_role}'.")

        if skills:
            top_skills = ", ".join(skills[:4])
            summary_parts.append(f"Candidate possesses {len(skills)} declared skill(s) including {top_skills}.")
        else:
            summary_parts.append("Candidate has no declared technical skills.")

        if education_str:
            summary_parts.append(f"Academic qualification: {education_str}.")
        else:
            summary_parts.append("No academic qualifications recorded.")

        if experience_years > 0:
            summary_parts.append(f"Candidate has approximately {experience_years:.1f} year(s) of relevant experience.")
        else:
            summary_parts.append("Candidate is entry-level with no declared professional experience.")

        if location_preference:
            summary_parts.append(f"Location preference: {location_preference}.")

        if missing_data:
            summary_parts.append(f"Gaps identified: {', '.join(missing_data)}.")

        profile_summary_text = " ".join(summary_parts)

        # Step 6: Construct and validate output Pydantic model
        return CandidateProfileSummary(
            agent=self.role_name,
            candidate_id=candidate_id,
            full_name=full_name,
            education=education_str,
            skills=skills,
            experience_years=experience_years,
            location_preference=location_preference,
            cv_summary=cv_summary,
            missing_data=missing_data,
            is_complete=is_complete,
            summary=profile_summary_text,
            disallowed_attributes_detected=disallowed_detected,
        )

    @staticmethod
    def _nonnegative_number(value):
        import math
        try:
            number = float(value)
            return number if math.isfinite(number) and number >= 0 else 0.0
        except (TypeError, ValueError):
            return 0.0
