"""
SkillBridge AI — Agent Evaluation Test Suite
=============================================
pytest golden-case dataset + rule-based schema validation tests.

Test categories:
  1. Tool-level unit tests  — test each allow-listed tool in isolation
  2. Agent-level tests      — test each agent with known inputs
  3. Golden-case E2E test   — known candidate/vacancy → expected outputs
  4. Negative-case tests    — disallowed attributes, bad inputs, schema failures
  5. Workflow graph tests   — end-to-end workflow execution trace
"""

from __future__ import annotations

import pytest
from typing import Any, Dict, List

# ── Allow-listed tools ────────────────────────────────────────────────────────
from app.tools.allowlisted_tools import (
    calculate_match_score,
    delegate_task,
    get_available_interview_slots,
    get_candidate_experience,
    get_candidate_profile,
    get_candidate_skills,
    get_vacancy_requirements,
    get_workflow_status,
    request_approval,
    validate_allowed_attributes,
    validate_eligibility,
    validate_match_calculation,
)

# ── Agents ────────────────────────────────────────────────────────────────────
from app.agents.candidate_analysis_agent import CandidateAnalysisAgent
from app.agents.job_matching_agent import JobMatchingAgent
from app.agents.planner_agent import PlanningAgent
from app.agents.validation_fairness_agent import ValidationFairnessAgent
from app.agents.workflow_graph import SkillBridgeWorkflowGraph


# =============================================================================
# GOLDEN CASE DATA — fixed inputs for deterministic expected outputs
# =============================================================================

GOLDEN_CANDIDATE: Dict[str, Any] = {
    "candidate_id": 42,
    "name": "Golden Candidate",
    "education": "BSc (Hons) in Information Technology",
    "skills": ["React", "SQL", "Git", "C#", "ASP.NET Core"],
    "experience_years": 1,
    "location_preference": "Colombo",
    "cv_parsed_summary": "Full-stack intern with strong React and SQL skills.",
}

GOLDEN_SKILLS: List[Dict[str, str]] = [
    {"skill_name": "React",        "proficiency_level": "Expert"},
    {"skill_name": "SQL",          "proficiency_level": "Intermediate"},
    {"skill_name": "Git",          "proficiency_level": "Expert"},
    {"skill_name": "C#",           "proficiency_level": "Intermediate"},
    {"skill_name": "ASP.NET Core", "proficiency_level": "Intermediate"},
]

GOLDEN_EXPERIENCE: List[Dict[str, Any]] = [
    {
        "company_name": "TechCorp Lanka",
        "job_title": "Intern",
        "duration_months": 6,
        "description": "Built REST APIs.",
    }
]

GOLDEN_VACANCY: Dict[str, Any] = {
    "vacancy_id": 7,
    "title": "Software Engineering Intern",
    "required_skills": ["React", "SQL", "Git"],
    "preferred_skills": ["Docker", "C#"],
    "min_experience_years": 0,
    "location": "Colombo",
}

# Expected: React(req) + SQL(req) + Git(req) = 3/3 * 80 = 80.0
#           C#(pref)                          = 1/2 * 20 = 10.0
#           Total = 90.0
GOLDEN_EXPECTED_SCORE = 90.0


# =============================================================================
# 1. TOOL-LEVEL UNIT TESTS
# =============================================================================

class TestAllowedAttributeValidation:
    def test_clean_profile_passes(self):
        result = validate_allowed_attributes(
            {"skills": ["React"], "education": "BSc", "experience_years": 1}
        )
        assert result["valid"] is True
        assert result["disallowed_detected"] == []

    def test_gender_detected(self):
        result = validate_allowed_attributes({"skills": ["React"], "gender": "male"})
        assert result["valid"] is False
        assert "gender" in result["disallowed_detected"]

    def test_multiple_disallowed_detected(self):
        result = validate_allowed_attributes({"skills": [], "age": 25, "race": "unknown"})
        assert result["valid"] is False
        assert "age" in result["disallowed_detected"]
        assert "race" in result["disallowed_detected"]

    def test_case_insensitive_key_detection(self):
        result = validate_allowed_attributes({"Gender": "X", "AGE": 30})
        assert result["valid"] is False
        assert len(result["disallowed_detected"]) == 2

    def test_empty_profile_is_valid(self):
        result = validate_allowed_attributes({})
        assert result["valid"] is True

    def test_type_error_on_non_dict(self):
        with pytest.raises(TypeError):
            validate_allowed_attributes(["skills", "React"])


class TestCalculateMatchScore:
    def test_golden_case_score(self):
        result = calculate_match_score(
            candidate_skills=GOLDEN_CANDIDATE["skills"],
            required_skills=GOLDEN_VACANCY["required_skills"],
            preferred_skills=GOLDEN_VACANCY["preferred_skills"],
        )
        assert result["match_score"] == GOLDEN_EXPECTED_SCORE
        assert result["mandatory_passed"] is True

    def test_zero_score_no_skill_overlap(self):
        # No overlap gives zero; absent preferred criteria award no free points.
        result = calculate_match_score(
            candidate_skills=["Python", "Django"],
            required_skills=["Java", "Spring", "Kubernetes"],
            preferred_skills=[],
        )
        assert result["match_score"] == 0.0
        assert result["mandatory_passed"] is False
        assert result["recommendation"] == "NOT_RECOMMENDED"

    def test_full_score_all_skills_matched(self):
        result = calculate_match_score(
            candidate_skills=["React", "SQL", "Docker"],
            required_skills=["React", "SQL"],
            preferred_skills=["Docker"],
        )
        assert result["match_score"] == 100.0

    def test_score_breakdown_components_sum_correctly(self):
        result = calculate_match_score(
            candidate_skills=["React", "SQL"],
            required_skills=["React", "SQL", "Git"],
            preferred_skills=["Docker"],
        )
        breakdown = result["score_breakdown"]
        computed_sum = round(breakdown["required_component"] + breakdown["preferred_component"], 2)
        assert abs(computed_sum - result["match_score"]) <= 0.5

    def test_case_insensitive_skill_matching(self):
        # No preferred_skills → pref_score defaults to 20.0
        # All 3 required matched → req_score = 3/3 * 80 = 80.0
        # Total = 80 + 20 = 100.0
        result = calculate_match_score(
            candidate_skills=["REACT", "sql", "Git"],
            required_skills=["React", "SQL", "Git"],
        )
        assert result["match_score"] == 100.0  # 80 req + 20 pref default
        assert result["mandatory_passed"] is True

    def test_empty_required_skills_gives_default_score(self):
        result = calculate_match_score(
            candidate_skills=["React"],
            required_skills=[],
            preferred_skills=["React"],
        )
        assert result["match_score"] == 100.0


class TestValidateEligibility:
    def test_golden_candidate_passes_all_rules(self):
        result = validate_eligibility(GOLDEN_CANDIDATE, GOLDEN_VACANCY)
        assert result["eligible"] is True
        assert result["failure_reasons"] == []

    def test_no_skill_overlap_fails(self):
        candidate = {**GOLDEN_CANDIDATE, "skills": ["Python", "Django"]}
        result = validate_eligibility(candidate, GOLDEN_VACANCY)
        assert result["eligible"] is False

    def test_location_mismatch_fails(self):
        candidate = {**GOLDEN_CANDIDATE, "location_preference": "Kandy"}
        result = validate_eligibility(candidate, GOLDEN_VACANCY)
        assert result["eligible"] is False
        assert any("Kandy" in r for r in result["failure_reasons"])

    def test_insufficient_experience_fails(self):
        vacancy = {**GOLDEN_VACANCY, "min_experience_years": 5}
        candidate = {**GOLDEN_CANDIDATE, "experience_years": 1}
        result = validate_eligibility(candidate, vacancy)
        assert result["eligible"] is False

    def test_rule_results_count(self):
        result = validate_eligibility(GOLDEN_CANDIDATE, GOLDEN_VACANCY)
        assert len(result["rule_results"]) == 3


class TestValidateMatchCalculation:
    def test_valid_match_result_passes(self):
        result = validate_match_calculation({
            "match_score": 84.0,
            "mandatory_passed": True,
            "recommendation": "SUITABLE_FOR_RECRUITER_REVIEW",
            "score_breakdown": {"required_component": 80.0, "preferred_component": 4.0},
        })
        assert result["all_checks_passed"] is True

    def test_missing_required_keys_fails(self):
        result = validate_match_calculation({"match_score": 84.0})
        assert result["schema_valid"] is False
        assert result["all_checks_passed"] is False

    def test_out_of_range_score_fails(self):
        result = validate_match_calculation({
            "match_score": 150.0,
            "mandatory_passed": True,
            "recommendation": "SUITABLE_FOR_RECRUITER_REVIEW",
        })
        assert result["score_in_range"] is False

    def test_invalid_recommendation_fails(self):
        result = validate_match_calculation({
            "match_score": 80.0,
            "mandatory_passed": True,
            "recommendation": "MAYBE_HIRE",
        })
        assert result["recommendation_valid"] is False


class TestDelegateTask:
    def test_valid_delegation(self):
        result = delegate_task(
            agent_name="Candidate Profile Analysis Agent",
            task_description="Retrieve candidate profile.",
            context={"candidate_id": 1},
        )
        assert result["status"] == "DELEGATED"
        assert "delegation_id" in result

    def test_unknown_agent_raises(self):
        with pytest.raises(ValueError, match="Unknown agent"):
            delegate_task("Rogue Agent", "Do something.", {})

    def test_empty_description_raises(self):
        with pytest.raises(ValueError):
            delegate_task("Planning Agent", "   ", {})


class TestInterviewSlots:
    def test_returns_three_slots_by_default(self):
        slots = get_available_interview_slots()
        assert len(slots) == 3

    def test_slots_are_not_booked(self):
        slots = get_available_interview_slots()
        assert all(s["is_booked"] is False for s in slots)

    def test_invalid_date_raises(self):
        with pytest.raises(ValueError, match="YYYY-MM-DD"):
            get_available_interview_slots(target_date="25-09-2026")

    def test_custom_date_reflected_in_slots(self):
        slots = get_available_interview_slots(target_date="2026-10-01")
        assert all("2026-10-01" in s["start_time"] for s in slots)


# =============================================================================
# 2. AGENT-LEVEL TESTS
# =============================================================================

class TestPlanningAgent:
    def setup_method(self):
        self.agent = PlanningAgent()

    def test_plan_has_correct_step_count(self):
        plan = self.agent.create_execution_plan("Test objective", 1, 1)
        assert plan["total_steps"] == 3

    def test_plan_status_is_generated(self):
        plan = self.agent.create_execution_plan("Test", 1, 1)
        assert plan["status"] == "PLAN_GENERATED"

    def test_plan_delegation_log_populated(self):
        plan = self.agent.create_execution_plan("Test", 1, 1)
        assert len(plan["delegation_log"]) == 3

    def test_empty_objective_raises(self):
        with pytest.raises(ValueError):
            self.agent.create_execution_plan("   ", 1, 1)

    def test_invalid_candidate_id_raises(self):
        with pytest.raises(ValueError):
            self.agent.create_execution_plan("Objective", -1, 1)


class TestCandidateAnalysisAgent:
    def setup_method(self):
        self.agent = CandidateAnalysisAgent()
        self.mock_profile_db = {42: GOLDEN_CANDIDATE}
        self.mock_skills_db  = {42: GOLDEN_SKILLS}
        self.mock_exp_db     = {42: GOLDEN_EXPERIENCE}

    def test_profile_contains_required_keys(self):
        result = self.agent.analyze_profile(42, self.mock_profile_db, self.mock_skills_db, self.mock_exp_db)
        for key in ("agent", "candidate_id", "education", "skills",
                    "skills_with_proficiency", "experience_records",
                    "experience_years", "total_experience_months",
                    "profile_completeness_score", "cv_summary", "summary"):
            assert key in result, f"Missing key: {key}"

    def test_completeness_score_is_100_for_full_profile(self):
        result = self.agent.analyze_profile(42, self.mock_profile_db, self.mock_skills_db, self.mock_exp_db)
        assert result["profile_completeness_score"] == 100

    def test_skills_grouped_by_proficiency(self):
        result = self.agent.analyze_profile(42, self.mock_profile_db, self.mock_skills_db, self.mock_exp_db)
        assert "React" in result["skills_by_level"].get("Expert", [])
        assert "Git"   in result["skills_by_level"].get("Expert", [])

    def test_total_experience_months_calculated(self):
        result = self.agent.analyze_profile(42, self.mock_profile_db, self.mock_skills_db, self.mock_exp_db)
        assert result["total_experience_months"] == 6

    def test_invalid_candidate_id_raises(self):
        with pytest.raises(ValueError):
            self.agent.analyze_profile(0)


class TestJobMatchingAgent:
    def setup_method(self):
        self.agent = JobMatchingAgent()
        self.mock_vacancy_db = {7: GOLDEN_VACANCY}

    def test_golden_match_score(self):
        result = self.agent.match_and_plan_interview(
            candidate_skills=GOLDEN_CANDIDATE["skills"],
            vacancy_id=7,
            mock_vacancy_db=self.mock_vacancy_db,
        )
        assert result["match_score"] == GOLDEN_EXPECTED_SCORE

    def test_mandatory_passed_true_for_golden_case(self):
        result = self.agent.match_and_plan_interview(
            candidate_skills=GOLDEN_CANDIDATE["skills"],
            vacancy_id=7,
            mock_vacancy_db=self.mock_vacancy_db,
        )
        assert result["mandatory_passed"] is True

    def test_proposed_slot_is_not_none(self):
        result = self.agent.match_and_plan_interview(
            candidate_skills=["React"],
            vacancy_id=7,
            mock_vacancy_db=self.mock_vacancy_db,
        )
        assert result["proposed_interview_slot"] is not None

    def test_missing_skills_identified(self):
        result = self.agent.match_and_plan_interview(
            candidate_skills=["React", "SQL"],
            vacancy_id=7,
            mock_vacancy_db=self.mock_vacancy_db,
        )
        assert "Git" in result["missing_required_skills"]
        assert result["mandatory_passed"] is False


class TestValidationFairnessAgent:
    def setup_method(self):
        self.agent = ValidationFairnessAgent()
        self.clean_profile = {**GOLDEN_CANDIDATE, "skills": ["React", "SQL", "Git"]}
        self.clean_match = {
            "match_score": 84.0,
            "mandatory_passed": True,
            "recommendation": "SUITABLE_FOR_RECRUITER_REVIEW",
            "score_breakdown": {"required_component": 80.0, "preferred_component": 4.0},
            "vacancy_id": 7,
            "missing_required_skills": [],
            "matched_preferred_skills": ["C#"],
            "min_experience_years": 0,
        }
        # Provide explicit vacancy_requirements so Gate 2 uses correct location
        self.clean_vacancy_requirements = {
            "required_skills": ["React", "SQL", "Git"],
            "preferred_skills": ["C#"],
            "min_experience_years": 0,
            "location": "Colombo",
        }

    def test_all_gates_pass_for_clean_inputs(self):
        result = self.agent.validate_and_route(
            self.clean_profile, self.clean_match, self.clean_vacancy_requirements
        )
        assert result["validation_passed"] is True
        assert result["approval_status"] == "PENDING_RECRUITER_APPROVAL"
        assert result["requires_human_approval"] is True
        assert len(result["gate_results"]) == 4

    def test_gate_1_fails_on_disallowed_attribute(self):
        dirty_profile = {**self.clean_profile, "gender": "X"}
        result = self.agent.validate_and_route(dirty_profile, self.clean_match)
        assert result["validation_passed"] is False
        assert result["gate_results"][0]["passed"] is False

    def test_gate_3_fails_on_invalid_schema(self):
        bad_match = {"match_score": 84.0}
        result = self.agent.validate_and_route(self.clean_profile, bad_match)
        assert result["validation_passed"] is False
        gate3 = next(g for g in result["gate_results"] if g["gate"] == 3)
        assert gate3["passed"] is False

    def test_rejection_reasons_populated_on_failure(self):
        dirty_profile = {**self.clean_profile, "age": 25}
        result = self.agent.validate_and_route(dirty_profile, self.clean_match)
        assert len(result["rejection_reasons"]) > 0

    def test_approval_request_present_on_success(self):
        result = self.agent.validate_and_route(
            self.clean_profile, self.clean_match, self.clean_vacancy_requirements
        )
        assert result["approval_request"] is not None
        assert "approval_request_id" in result["approval_request"]


# =============================================================================
# 3. GOLDEN-CASE END-TO-END TEST
# =============================================================================

class TestGoldenCaseE2E:
    def test_full_workflow_golden_case(self):
        graph = SkillBridgeWorkflowGraph()
        result = graph.execute(
            candidate_id=1,
            vacancy_id=1,
            objective="Evaluate candidate for Software Engineering Intern.",
            profile_data=dict(GOLDEN_CANDIDATE, candidate_id=1),
            vacancy_data=dict(GOLDEN_VACANCY, vacancy_id=1),
        )

        assert result["status"] == "PENDING_RECRUITER_APPROVAL"
        assert result["requires_human_approval"] is True
        assert len(result["execution_trace"]) == 4

        for trace_entry in result["execution_trace"]:
            assert trace_entry["status"] == "COMPLETED"

        match = result["match_result"]
        assert match["match_score"] >= 0.0
        assert match["mandatory_passed"] is True

        val = result["validation_result"]
        assert val["validation_passed"] is True
        assert len(val["gate_results"]) == 4
        assert result["errors"] == []


def test_job_matching_calculation():
    match = calculate_match_score(
        candidate_skills=["React", "Java", "SQL", "Git"],
        required_skills=["React", "SQL", "Git"],
        preferred_skills=["Docker"],
    )

    assert match["match_score"] == 80.0
    assert match["mandatory_passed"] is True


def test_job_matching_agent_missing_mandatory_skills():
    matcher = JobMatchingAgent()

    # Candidate lacks "React" and "Git"
    result = matcher.match_and_plan_interview(
        candidate_skills=["Java", "SQL"],
        vacancy_id=44
    )

    assert result["mandatory_passed"] is False
    assert result["recommendation"] == "NOT_RECOMMENDED"
    assert "React" in result["missing_required_skills"]
    assert "Git" in result["missing_required_skills"]


# =============================================================================
# 4. WORKFLOW GRAPH UNIT TESTS
# =============================================================================

class TestWorkflowGraph:
    def setup_method(self):
        self.graph = SkillBridgeWorkflowGraph()

    def test_workflow_returns_required_keys(self):
        result = self.graph.execute(1, 1, "Test objective", profile_data=dict(GOLDEN_CANDIDATE, candidate_id=1), vacancy_data=dict(GOLDEN_VACANCY, vacancy_id=1))
        for key in ("workflow_id", "objective", "candidate_id", "vacancy_id",
                    "status", "plan", "profile_analysis", "match_result",
                    "validation_result", "requires_human_approval",
                    "final_recommendation", "execution_trace",
                    "started_at", "completed_at", "total_duration_ms"):
            assert key in result, f"Missing top-level key: {key}"

    def test_workflow_id_format(self):
        result = self.graph.execute(5, 3, "Test", profile_data=dict(GOLDEN_CANDIDATE, candidate_id=5), vacancy_data=dict(GOLDEN_VACANCY, vacancy_id=3))
        assert result["workflow_id"].startswith("wf-5-3-")
        from uuid import UUID
        UUID(result["workflow_id"].removeprefix("wf-5-3-"))

    def test_invalid_candidate_id_raises(self):
        with pytest.raises(ValueError):
            self.graph.execute(0, 1, "Test")

    def test_total_duration_ms_is_positive(self):
        result = self.graph.execute(1, 1, "Test", profile_data=dict(GOLDEN_CANDIDATE, candidate_id=1), vacancy_data=dict(GOLDEN_VACANCY, vacancy_id=1))
        assert result["total_duration_ms"] > 0

    def test_workflow_status_not_initialised(self):
        result = self.graph.execute(1, 1, "Test objective", profile_data=dict(GOLDEN_CANDIDATE, candidate_id=1), vacancy_data=dict(GOLDEN_VACANCY, vacancy_id=1))
        assert result["status"] not in ("INITIALISED", "IN_PROGRESS", "ERROR")
