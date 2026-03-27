from pydantic import BaseModel, Field, EmailStr, field_validator
from typing import List, Optional, Dict
from datetime import datetime

class HealthLogBase(BaseModel):
    """
    Base schema for health logs with strict data validation.
    """
    symptom: str = Field(..., min_length=1, max_length=100)
    severity: int = Field(..., ge=1, le=10)
    sleep_hours: float = Field(default=0.0, ge=0, le=24.0)
    water_intake: float = Field(default=0.0, ge=0, le=15.0) # Litres
    exercise_minutes: int = Field(default=0, ge=0, le=1440) # Minutes in a day
    mood: str = Field(default="", max_length=50)
    stress_level: int = Field(default=5, ge=1, le=10)
    notes: Optional[str] = Field(default=None, max_length=1000)

    @field_validator('symptom')
    @classmethod
    def symptom_must_not_be_blank(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError('Symptom name cannot be empty or just whitespace')
        return v.strip()

class HealthLogCreate(HealthLogBase):
    pass

class HealthLog(HealthLogBase):
    id: str
    user_id: str
    created_at: datetime

class UserProfileBase(BaseModel):
    """
    Base schema for user profiles with strict data validation.
    """
    display_name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    photo_url: Optional[str] = Field(default=None, max_length=500)
    age: Optional[int] = Field(default=None, ge=0, le=120)
    height_cm: Optional[float] = Field(default=None, ge=30, le=300)
    weight_kg: Optional[float] = Field(default=None, ge=2, le=600)
    primary_condition: Optional[str] = Field(default=None, max_length=200)

    @field_validator('display_name')
    @classmethod
    def name_must_not_be_empty(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError('Display name cannot be empty')
        return v.strip()

class UserProfile(UserProfileBase):
    uid: str

class Insight(BaseModel):
    id: str
    title: str = Field(..., max_length=200)
    description: str = Field(..., max_length=1000)
    type: str # correlation, trend, prediction, recommendation
    confidence: float = Field(..., ge=0.0, le=1.0)
    confidence_label: str
    trigger_factor: Optional[str] = None
    generated_at: datetime

class WeeklyReport(BaseModel):
    week_start: datetime
    week_end: datetime
    total_logs: int = Field(..., ge=0)
    top_symptoms: List[str]
    symptom_frequencies: Dict[str, int]
    avg_sleep_hours: float = Field(..., ge=0, le=24)
    avg_water_intake_litres: float = Field(..., ge=0)
    avg_stress_level: float = Field(..., ge=1, le=10)
    total_exercise_minutes: int = Field(..., ge=0)
    wellness_score: float = Field(..., ge=0, le=100)
    daily_scores: List[float]
    insights: List[Insight]
