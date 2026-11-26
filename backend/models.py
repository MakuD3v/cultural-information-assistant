from sqlalchemy import Column, Integer, String, Text, Float, DateTime, ForeignKey, Boolean, JSON
from sqlalchemy.sql import func
from .database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    invite_code = Column(String(50), unique=True, index=True, nullable=False)
    full_name = Column(String(100), nullable=False)
    email = Column(String(100), nullable=True)
    role = Column(String(30), nullable=False, default="student") # student, professor, admin, coordinator
    cohort = Column(String(100), default="SorSU · Cohort A")
    avatar_initials = Column(String(10), default="MR")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Location(Base):
    __tablename__ = "locations"

    location_id = Column(String(50), primary_key=True, index=True)
    name = Column(String(150), nullable=False)
    address = Column(String(255), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    map_reference = Column(String(100), nullable=True)
    description = Column(Text, nullable=True)

class ItineraryActivity(Base):
    __tablename__ = "itinerary_activities"

    activity_id = Column(String(50), primary_key=True, index=True)
    day_number = Column(Integer, nullable=False, index=True)
    date = Column(String(20), nullable=False) # e.g. "2026-11-20"
    start_time = Column(String(10), nullable=False) # e.g. "07:30"
    end_time = Column(String(10), nullable=True) # e.g. "11:30"
    title = Column(String(200), nullable=False)
    venue_name = Column(String(150), nullable=False)
    target_audience = Column(String(50), default="Everyone") # Everyone, SorSU only, Staff only
    description = Column(Text, nullable=True)
    location_id = Column(String(50), ForeignKey("locations.location_id"), nullable=True)
    status = Column(String(20), default="published") # published, draft, under_review
    version = Column(Integer, default=4)
    display_order = Column(Integer, default=1)
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class CulturalArticle(Base):
    __tablename__ = "cultural_articles"

    content_id = Column(String(50), primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    category = Column(String(50), nullable=False) # Markets, Heritage, Music, Food, Words
    summary = Column(Text, nullable=False)
    content = Column(Text, nullable=False)
    fact_1 = Column(Text, nullable=True)
    fact_2 = Column(Text, nullable=True)
    vietnamese_word = Column(String(100), nullable=True)
    word_translation = Column(String(100), nullable=True)
    source_title = Column(String(255), nullable=False)
    source_author = Column(String(100), nullable=False)
    source_date = Column(String(20), nullable=False)
    source_label = Column(String(50), nullable=False) # e.g. "A1 Chinh (2024)"
    location_id = Column(String(50), ForeignKey("locations.location_id"), nullable=True)
    status = Column(String(20), default="published") # published, draft
    last_updated = Column(DateTime(timezone=True), server_default=func.now())

class QRMappping(Base):
    __tablename__ = "qr_mappings"

    qr_id = Column(String(50), primary_key=True, index=True)
    content_id = Column(String(50), ForeignKey("cultural_articles.content_id"), nullable=True)
    location_id = Column(String(50), ForeignKey("locations.location_id"), nullable=True)
    landmark_name = Column(String(150), nullable=False)
    status = Column(String(20), default="active") # active, inactive
    last_verified = Column(DateTime(timezone=True), server_default=func.now())

class ItineraryApproval(Base):
    __tablename__ = "itinerary_approvals"

    id = Column(Integer, primary_key=True, index=True)
    activity_id = Column(String(50), nullable=False)
    day_number = Column(Integer, nullable=False)
    title = Column(String(200), nullable=False)
    proposed_time = Column(String(20), nullable=False)
    change_description = Column(Text, nullable=False)
    proposed_by = Column(String(100), nullable=False) # e.g. "Prof. Ramos", "Prof. Nguyen"
    status = Column(String(20), default="pending") # pending, approved, rejected
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class GuideQueryLog(Base):
    __tablename__ = "guide_query_logs"

    id = Column(Integer, primary_key=True, index=True)
    question = Column(Text, nullable=False)
    intent = Column(String(50), nullable=False) # schedule, culture, unavailable, offline
    response = Column(Text, nullable=False)
    retrieved_source = Column(String(100), nullable=True)
    is_grounded = Column(Boolean, default=True)
    steps = Column(JSON, nullable=True)
    processing_time_sec = Column(Float, default=0.8)
    feedback = Column(String(20), nullable=True) # thumbs_up, thumbs_down
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class ProgramSetting(Base):
    __tablename__ = "program_settings"

    key = Column(String(50), primary_key=True, index=True)
    value = Column(Text, nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

