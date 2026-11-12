from fastapi.testclient import TestClient
from app.main import app
from app.agents.workflow_graph import SkillBridgeWorkflowGraph


def evidence(skills):
    return {"candidate_id": 71, "skills": skills,
            "education": [{"institution": "University of Colombo", "degree": "MBBS", "field_of_study": "Cardiology"}],
            "experience": []}


def vacancy():
    return {"vacancy_id": 92, "title": "Software Engineering Intern",
            "required_skills": ["React", "SQL", "Git", "Docker"], "preferred_skills": [],
            "requirements": [{"text": "Relevant software qualification", "non_negotiable": True}]}


def run(profile):
    return SkillBridgeWorkflowGraph().execute(71, 92, "Evaluate actual application", profile_data=profile, vacancy_data=vacancy())


def test_cross_domain_profile_is_low_and_relevant_skills_materially_higher():
    medical = run(evidence(["Cardiology", "MBBS"]))
    technical_profile = evidence(["React", "SQL", "Git", "Docker"])
    technical_profile["education"] = [{"degree": "Software Engineering"}]
    technical = run(technical_profile)
    assert medical["status"] == "PENDING_RECRUITER_APPROVAL", medical
    assert technical["status"] == "PENDING_RECRUITER_APPROVAL", technical
    low, high = medical["match_result"], technical["match_result"]
    assert low["match_score"] == 0  # Zero of four required skills, no preferred criteria.
    assert set(low["missing_required_skills"]) == {"React", "SQL", "Git", "Docker"}
    assert low["matched_skills"] == []
    assert high["match_score"] >= low["match_score"] + 70
    assert high["eligibility_gate_passed"] is False  # Unstructured qualification still needs HITL.
    assert medical["requires_human_approval"] and technical["requires_human_approval"]
    assert low["proposed_interview_slot"] is None
    assert low["requirements_review"][0]["result"] == "REQUIRES_HUMAN_REVIEW"
    assert medical["workflow_id"] != run(evidence(["Cardiology"]))["workflow_id"]


def test_http_refuses_id_only_or_mismatched_evidence():
    client = TestClient(app)
    payload = {"candidate_id": 71, "vacancy_id": 92, "objective": "Evaluate actual application"}
    assert client.post("/api/ai/workflow/execute", json=payload).status_code == 422
    payload.update(profile_data=evidence(["MBBS"]), vacancy_data=vacancy())
    response = client.post("/api/ai/workflow/execute", json=payload)
    assert response.status_code == 200
    assert response.json()["match_result"]["match_score"] == 0
    payload["profile_data"]["candidate_id"] = 999
    assert client.post("/api/ai/workflow/execute", json=payload).status_code == 422


def test_empty_requirements_fail_without_fabricating_score():
    v = vacancy()
    v["required_skills"] = []
    result = SkillBridgeWorkflowGraph().execute(71, 92, "Evaluate actual application", profile_data=evidence([]), vacancy_data=v)
    assert result["status"] == "ERROR"
    assert result["match_result"] == {}
