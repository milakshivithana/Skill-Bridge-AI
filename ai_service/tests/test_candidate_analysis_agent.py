"""
Evaluation Tests for Candidate Profile Analysis Agent (Role 2 / Component A).
Tests golden cases, missing profile data detection, fairness attribute filtering,
schema validation, safe failure recovery, and FastAPI endpoint contracts.
"""

import pytest
from starlette.testclient import TestClient

from app.main import app
from app.agents.candidate_analysis_agent import CandidateAnalysisAgent
from app.schemas.candidate_schemas import CandidateProfileSummary, CandidateAnalysisRequest
from app.tools.allowlisted_tools import (
    getCandidateProfile,
    getCandidateSkills,
    getCandidateExperience,
)


@pytest.fixture
def agent():
    return CandidateAnalysisAgent()


@pytest.fixture
def client():
    return TestClient(app)


def test_golden_case_candidate_profile(agent):
    """
    Golden Case: Full, rich candidate profile with all qualifications declared.
    Verifies full extraction, completeness = True, and summary generation.
    """
    golden_profile = {
        "candidate_id": 101,
        "fullName": "Jane Developer",
        "city": "Colombo",
        "educations": [
            {
                "degree": "BSc (Hons) Software Engineering",
                "institution": "SLIIT",
                "fieldOfStudy": "Computing",
                "graduationYear": 2025
            }
        ],
        "skills": [
            {"skillName": "React", "proficiency": "Advanced"},
            {"skillName": "TypeScript", "proficiency": "Intermediate"},
            {"skillName": "C#", "proficiency": "Advanced"},
            {"skillName": "PostgreSQL", "proficiency": "Intermediate"}
        ],
        "experiences": [
            {
                "company": "Tech Corp",
                "title": "Software Engineering Intern",
                "durationMonths": 12,
                "description": "Full-stack development with React and ASP.NET Core"
            }
        ],
        "locationPreference": "Colombo",
        "cvDocuments": [{"fileName": "Jane_Developer_Resume.pdf"}],
        "bio": "Passionate full stack developer with experience in React and C#."
    }

    result = agent.analyze_profile(101, profile_data=golden_profile, target_role="Junior Full Stack Engineer")

    assert isinstance(result, CandidateProfileSummary)
    assert result.candidate_id == 101
    assert result.full_name == "Jane Developer"
    assert result.is_complete is True
    assert len(result.missing_data) == 0
    assert "React" in result.skills
    assert "C#" in result.skills
    assert result.experience_years >= 1.0
    assert "SLIIT" in result.education
    assert "Junior Full Stack Engineer" in result.summary
    assert len(result.disallowed_attributes_detected) == 0


def test_missing_profile_data_reporting(agent):
    """
    Missing Data: Incomplete candidate profile missing skills, experience, and CV.
    Verifies deterministic identification of missing sections and is_complete = False.
    """
    incomplete_profile = {
        "candidate_id": 202,
        "fullName": "New Applicant",
        "city": "Kandy",
        "educations": [
            {"degree": "High School Diploma", "institution": "Central College"}
        ],
        "skills": [],
        "experiences": [],
        "cvDocuments": []
    }

    result = agent.analyze_profile(202, profile_data=incomplete_profile)

    assert result.is_complete is False
    assert "skills" in result.missing_data
    assert "experience" in result.missing_data
    assert "cv_document" in result.missing_data
    assert "Gaps identified" in result.summary


def test_disallowed_personal_attributes_filtering(agent):
    """
    Fairness & Bias Check: Input contains prohibited attributes (gender, religion, marital_status).
    Verifies they are flagged and excluded from summary.
    """
    biased_input = {
        "candidate_id": 303,
        "fullName": "Protected Candidate",
        "gender": "Female",
        "religion": "Buddhist",
        "marital_status": "Single",
        "age": 22,
        "skills": ["Python", "Machine Learning"],
        "education": "BSc in Artificial Intelligence"
    }

    result = agent.analyze_profile(303, profile_data=biased_input)

    assert len(result.disallowed_attributes_detected) > 0
    assert "gender" in result.disallowed_attributes_detected
    assert "religion" in result.disallowed_attributes_detected

    # Disallowed attributes must NEVER appear in the candidate summary
    summary_lower = result.summary.lower()
    assert "female" not in summary_lower
    assert "buddhist" not in summary_lower
    assert "single" not in summary_lower


def test_safe_failure_handling(agent):
    """
    Safe Failure: Empty, corrupt, or invalid profile data passed.
    Must never crash or raise unhandled exceptions.
    """
    # Empty dictionary
    res_empty = agent.analyze_profile(999, profile_data={})
    assert isinstance(res_empty, CandidateProfileSummary)
    assert res_empty.candidate_id == 999

    # Non-dictionary or None
    res_none = agent.analyze_profile(999, profile_data=None)
    assert isinstance(res_none, CandidateProfileSummary)
    assert res_none.candidate_id == 999


def test_non_hiring_decision_constraint(agent):
    """
    Rule Verification: Agent must provide structured qualification summaries
    and NOT make final hiring/rejection decisions (which belong to recruiters/HITL).
    """
    result = agent.analyze_profile(102)

    # Ensure no hiring decision attributes or terms exist
    assert not hasattr(result, "hiring_decision")
    assert not hasattr(result, "hire_recommendation")
    assert "HIRED" not in result.summary.upper()
    assert "REJECTED" not in result.summary.upper()


def test_allowlisted_tools():
    """
    Verifies least-privilege allow-listed tools comply with naming and behavior.
    """
    profile = getCandidateProfile(102)
    assert "candidate_id" in profile
    assert profile["candidate_id"] == 102

    skills = getCandidateSkills(102)
    assert isinstance(skills, list)
    assert len(skills) > 0

    exp = getCandidateExperience(102)
    assert "experience_years" in exp
    assert "education" in exp


def test_fastapi_analyze_candidate_endpoint(client):
    """
    Integration: Tests POST /api/ai/candidate/analyze endpoint.
    """
    payload = {
        "candidate_id": 102,
        "profile_data": {
            "fullName": "Test Candidate",
            "skills": ["React", "FastAPI"],
            "education": "BSc in Computer Science",
            "city": "Colombo"
        },
        "target_role": "Backend Engineer"
    }

    response = client.post("/api/ai/candidate/analyze", json=payload)
    assert response.status_code == 200

    data = response.json()
    assert data["agent"] == "Candidate Profile Analysis Agent"
    assert data["candidate_id"] == 102
    assert "React" in data["skills"]
    assert "FastAPI" in data["skills"]
    assert "Backend Engineer" in data["summary"]
    assert "is_complete" in data
