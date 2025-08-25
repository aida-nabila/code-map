from pydantic import BaseModel
from typing import List, Optional


# -----------------------------
# User-related schemas
# -----------------------------
class UserResponses(BaseModel):
    educationLevel: Optional[str]
    cgpa: Optional[float]
    major: Optional[str]
    programmingLanguages: List[str] = []
    courseworkExperience: Optional[str]
    skillReflection: Optional[str]


class SkillReflectionRequest(BaseModel):
    user_test_id: int


# -----------------------------
# Follow-up test schemas
# -----------------------------
class FollowUpResponse(BaseModel):
    questionId: int
    selectedOption: str
    user_test_id: int


class FollowUpResponses(BaseModel):
    responses: List[FollowUpResponse]


# -----------------------------
# Job matching / profile schemas
# -----------------------------
class JobMatch(BaseModel):
    job_index: int
    similarity_score: float
    similarity_percentage: float
    job_title: str
    job_description: str
    required_skills: Optional[List[str]] = None
    required_knowledge: Optional[List[str]] = None


class UserProfileMatchResponse(BaseModel):
    profile_text: str
    top_matches: List[JobMatch]
