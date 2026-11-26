from pydantic import BaseModel
from typing import List, Optional, Any
from datetime import datetime

class UserLoginRequest(BaseModel):
    invite_code: str

class UserResponse(BaseModel):
    id: int
    invite_code: str
    full_name: str
    email: Optional[str]
    role: str
    cohort: str
    avatar_initials: str

class LocationModel(BaseModel):
    location_id: str
    name: str
    address: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    map_reference: Optional[str]
    description: Optional[str]

    class Config:
        from_attributes = True

class ItineraryActivityModel(BaseModel):
    activity_id: str
    day_number: int
    date: str
    start_time: str
    end_time: Optional[str]
    title: str
    venue_name: str
    target_audience: str
    description: Optional[str]
    location_id: Optional[str]
    status: str
    version: int
    display_order: int

    class Config:
        from_attributes = True

class ActivityCreateRequest(BaseModel):
    day_number: int
    date: str
    start_time: str
    end_time: Optional[str] = None
    title: str
    venue_name: str
    target_audience: str = "Everyone"
    description: Optional[str] = None
    location_id: Optional[str] = None
    status: str = "draft"

class ActivityUpdateRequest(BaseModel):
    day_number: Optional[int] = None
    date: Optional[str] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    title: Optional[str] = None
    venue_name: Optional[str] = None
    target_audience: Optional[str] = None
    description: Optional[str] = None
    location_id: Optional[str] = None
    status: Optional[str] = None

class CulturalArticleCreateRequest(BaseModel):
    title: str
    category: str
    summary: str
    content: str
    fact_1: Optional[str] = None
    fact_2: Optional[str] = None
    vietnamese_word: Optional[str] = None
    word_translation: Optional[str] = None
    source_title: str
    source_author: str
    source_date: str
    source_label: str
    location_id: Optional[str] = None
    status: str = "published"

class LocationCreateRequest(BaseModel):
    location_id: str
    name: str
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    map_reference: Optional[str] = None
    description: Optional[str] = None

class LocationUpdateRequest(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    map_reference: Optional[str] = None
    description: Optional[str] = None

class BroadcastUpdateRequest(BaseModel):
    message: str
    time_label: Optional[str] = ""
    day_number: Optional[int] = 1

class CulturalArticleModel(BaseModel):
    content_id: str
    title: str
    category: str
    summary: str
    content: str
    fact_1: Optional[str]
    fact_2: Optional[str]
    vietnamese_word: Optional[str]
    word_translation: Optional[str]
    source_title: str
    source_author: str
    source_date: str
    source_label: str
    location_id: Optional[str]
    status: str

    class Config:
        from_attributes = True

class QRLookupRequest(BaseModel):
    qr_id: str

class GuideQuestionRequest(BaseModel):
    question: str
    offline_mode: Optional[bool] = False

class GuideStep(BaseModel):
    step_number: int
    description: str

class GuideResponse(BaseModel):
    question: str
    answer: str
    source_type: str # schedule, culture, none
    source_stub: Optional[str] # e.g. "1 Itinerary · Day 3" or "A1 Chinh (2024)"
    note: Optional[str]
    status: str # success, not_in_sources, offline
    steps: List[str]
    response_time_sec: float
    try_next: List[str]
    log_id: Optional[int] = None

class FeedbackRequest(BaseModel):
    log_id: int
    feedback: str # thumbs_up or thumbs_down

class ApprovalActionRequest(BaseModel):
    approval_id: int
    action: str # approve or reject
