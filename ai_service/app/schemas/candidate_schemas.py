"""
Candidate Profile Analysis Agent Pydantic Contracts.
Defines input and output schemas for Candidate Profile Analysis Agent in accordance with AGENTS.md.
"""

from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


class EducationItem(BaseModel):
    institution: Optional[str] = Field(None, description="Educational institution")
    degree: Optional[str] = Field(None, description="Degree or qualification name")
    field_of_study: Optional[str] = Field(None, description="Field of study or major")
    graduation_year: Optional[int] = Field(None, description="Year of graduation")


class ExperienceItem(BaseModel):
    company: Optional[str] = Field(None, description="Company or organization name")
    title: Optional[str] = Field(None, description="Job title or role")
    duration_months: Optional[int] = Field(None, description="Duration in months")
    description: Optional[str] = Field(None, description="Key duties and achievements")


class CandidateAnalysisRequest(BaseModel):
    candidate_id: int = Field(..., description="Unique identifier of the candidate")
    profile_data: Optional[Dict[str, Any]] = Field(None, description="Optional raw candidate profile data payload")
    target_role: Optional[str] = Field(None, description="Optional target vacancy or role title for contextual summary")


class CandidateProfileSummary(BaseModel):
    agent: str = Field("Candidate Profile Analysis Agent", description="Agent role name")
    candidate_id: int = Field(..., description="Unique identifier of the candidate")
    full_name: Optional[str] = Field(None, description="Full name of candidate")
    education: str = Field("", description="Highest or primary academic qualification")
    skills: List[str] = Field(default_factory=list, description="List of declared/extracted technical and professional skills")
    experience_years: float = Field(0.0, description="Total years of professional/internship experience")
    location_preference: Optional[str] = Field(None, description="Preferred work location")
    cv_summary: Optional[str] = Field(None, description="Summary extracted from CV")
    missing_data: List[str] = Field(default_factory=list, description="List of missing profile components")
    is_complete: bool = Field(True, description="Whether all key profile sections are present")
    summary: str = Field(..., description="Structured job-relevant executive summary of candidate qualifications")
    disallowed_attributes_detected: List[str] = Field(
        default_factory=list,
        description="Fairness check: sensitive non-job-related attributes detected and excluded from analysis"
    )

    def __getitem__(self, item: str) -> Any:
        """Allow backwards-compatible dict-like indexing."""
        if hasattr(self, item):
            return getattr(self, item)
        raise KeyError(item)

    def __contains__(self, item: str) -> bool:
        """Allow backwards-compatible 'in' operator checks."""
        return hasattr(self, item)

    def get(self, item: str, default: Any = None) -> Any:
        """Allow backwards-compatible dict get method."""
        return getattr(self, item, default)

    def keys(self):
        """Allow dict-like keys retrieval."""
        return self.__dict__.keys()

    def values(self):
        """Allow dict-like values retrieval."""
        return self.__dict__.values()

    def items(self):
        """Allow dict-like items retrieval."""
        return self.__dict__.items()
