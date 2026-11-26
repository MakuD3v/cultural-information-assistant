import os
import sys
import uuid
from fastapi import FastAPI, Depends, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List, Optional

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.database import get_db, engine, Base
from backend.models import (
    User, Location, ItineraryActivity, CulturalArticle,
    QRMappping, ItineraryApproval, GuideQueryLog, ProgramSetting
)
from backend.schemas import (
    UserLoginRequest, UserResponse, LocationModel,
    ItineraryActivityModel, ActivityCreateRequest, ActivityUpdateRequest,
    CulturalArticleModel, CulturalArticleCreateRequest,
    LocationCreateRequest, LocationUpdateRequest,
    BroadcastUpdateRequest, QRLookupRequest, GuideQuestionRequest,
    GuideResponse, FeedbackRequest, ApprovalActionRequest
)
from backend.grounding_engine import GroundingEngine

# Create tables if not existing
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Cultural Information Assistant API",
    description="Backend API for SorSU × CTU Can Tho Exchange Program Cultural Information Assistant",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ================= AUTHENTICATION =================

@app.post("/api/auth/login", response_model=UserResponse)
def login_with_invite_code(req: UserLoginRequest, db: Session = Depends(get_db)):
    raw = req.invite_code.strip()
    if not raw:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please enter your invite code or university email."
        )
    # Match strictly against PostgreSQL users by invite_code or university email
    user = db.query(User).filter(User.invite_code.ilike(raw)).first()
    if not user:
        user = db.query(User).filter(User.email.ilike(raw)).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid invite code or university email. Please check with your exchange coordinator."
        )
    return user

@app.get("/api/auth/profile/{user_id}", response_model=UserResponse)
def get_user_profile(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# ================= ITINERARY (PARTICIPANT) =================

@app.get("/api/itinerary", response_model=List[ItineraryActivityModel])
def get_itinerary(
    day: Optional[int] = None,
    audience: Optional[str] = None,
    include_drafts: bool = False,
    db: Session = Depends(get_db)
):
    query = db.query(ItineraryActivity)
    if not include_drafts:
        query = query.filter(ItineraryActivity.status == "published")
    if day:
        query = query.filter(ItineraryActivity.day_number == day)
    if audience and audience != "Everyone":
        query = query.filter(
            (ItineraryActivity.target_audience == audience) | 
            (ItineraryActivity.target_audience == "Everyone")
        )
    return query.order_by(ItineraryActivity.day_number, ItineraryActivity.start_time).all()

def _get_program_version(db: Session) -> int:
    ver_setting = db.query(ProgramSetting).filter(ProgramSetting.key == "itinerary_version").first()
    if ver_setting and ver_setting.value.isdigit():
        return int(ver_setting.value)
    max_ver = db.query(ItineraryActivity.version).order_by(ItineraryActivity.version.desc()).first()
    return max_ver[0] if max_ver and max_ver[0] else 1

@app.get("/api/itinerary/sync-offline")
def sync_offline_schedule(db: Session = Depends(get_db)):
    """Returns the full published schedule package for local caching (NFR-05)"""
    activities = db.query(ItineraryActivity).filter(
        ItineraryActivity.status == "published"
    ).order_by(ItineraryActivity.day_number, ItineraryActivity.start_time).all()

    latest_dt = None
    for a in activities:
        if a.last_updated and (latest_dt is None or a.last_updated > latest_dt):
            latest_dt = a.last_updated

    last_updated_str = latest_dt.strftime("%d %b, %H:%M") if latest_dt else ""
    version_num = _get_program_version(db)

    return {
        "program_title": "SorSU × CTU Exchange Program",
        "last_updated": last_updated_str,
        "version": version_num,
        "total_activities": len(activities),
        "activities": [ItineraryActivityModel.from_orm(a) for a in activities]
    }

@app.get("/api/itinerary/{activity_id}", response_model=ItineraryActivityModel)
def get_activity_detail(activity_id: str, db: Session = Depends(get_db)):
    activity = db.query(ItineraryActivity).filter(
        ItineraryActivity.activity_id == activity_id
    ).first()
    if not activity:
        raise HTTPException(status_code=404, detail="Activity not found")
    return activity

# ================= CULTURAL CONTENT =================

@app.get("/api/culture/articles", response_model=List[CulturalArticleModel])
def get_cultural_articles(
    category: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(CulturalArticle).filter(CulturalArticle.status == "published")
    if category and category.lower() != "all":
        query = query.filter(CulturalArticle.category.ilike(category))
    if search:
        search_filter = f"%{search}%"
        query = query.filter(
            (CulturalArticle.title.ilike(search_filter)) |
            (CulturalArticle.summary.ilike(search_filter)) |
            (CulturalArticle.content.ilike(search_filter))
        )
    return query.all()

@app.get("/api/culture/articles/{content_id}", response_model=CulturalArticleModel)
def get_cultural_article_detail(content_id: str, db: Session = Depends(get_db)):
    article = db.query(CulturalArticle).filter(
        CulturalArticle.content_id == content_id,
        CulturalArticle.status == "published"
    ).first()
    if not article:
        raise HTTPException(status_code=404, detail="Cultural article not found or not published")
    return article

# ================= MAP & LOCATIONS =================

@app.get("/api/locations", response_model=List[LocationModel])
def get_locations(db: Session = Depends(get_db)):
    return db.query(Location).all()

@app.get("/api/locations/{location_id}", response_model=LocationModel)
def get_location_detail(location_id: str, db: Session = Depends(get_db)):
    loc = db.query(Location).filter(Location.location_id == location_id).first()
    if not loc:
        raise HTTPException(status_code=404, detail="Location not found")
    return loc

# ================= SCAN & QR CODE =================

@app.post("/api/qr/resolve")
def resolve_qr_code(req: QRLookupRequest, db: Session = Depends(get_db)):
    qr_id = req.qr_id.strip()
    mapping = db.query(QRMappping).filter(
        QRMappping.qr_id == qr_id,
        QRMappping.status == "active"
    ).first()

    if not mapping:
        raise HTTPException(
            status_code=404,
            detail="QR code not recognized or inactive. Only approved program QR codes are supported."
        )

    article = db.query(CulturalArticle).filter(
        CulturalArticle.content_id == mapping.content_id,
        CulturalArticle.status == "published"
    ).first()

    location = db.query(Location).filter(
        Location.location_id == mapping.location_id
    ).first()

    return {
        "qr_id": mapping.qr_id,
        "landmark_name": mapping.landmark_name,
        "matched": True,
        "article": CulturalArticleModel.from_orm(article) if article else None,
        "location": LocationModel.from_orm(location) if location else None
    }

# ================= AI AUTOMATED GUIDE =================

@app.post("/api/guide/ask", response_model=GuideResponse)
def ask_the_guide(req: GuideQuestionRequest, db: Session = Depends(get_db)):
    engine = GroundingEngine(db)
    return engine.handle_request(req.question, offline_mode=req.offline_mode or False)

@app.post("/api/guide/feedback")
def submit_guide_feedback(req: FeedbackRequest, db: Session = Depends(get_db)):
    log = db.query(GuideQueryLog).filter(GuideQueryLog.id == req.log_id).first()
    if log:
        log.feedback = req.feedback
        db.commit()
        return {"status": "success", "message": "Feedback recorded"}
    return {"status": "not_found"}

# ================= ADMIN DASHBOARD & PLANNER =================

@app.get("/api/admin/dashboard")
def get_admin_dashboard(db: Session = Depends(get_db)):
    total_activities = db.query(ItineraryActivity).count()
    published_count = db.query(ItineraryActivity).filter(ItineraryActivity.status == "published").count()
    draft_count = db.query(ItineraryActivity).filter(ItineraryActivity.status == "draft").count()
    pending_approvals = db.query(ItineraryApproval).filter(ItineraryApproval.status == "pending").count()
    total_users = db.query(User).count()
    cultural_articles_count = db.query(CulturalArticle).filter(CulturalArticle.status == "published").count()
    total_locations = db.query(Location).count()

    version_num = _get_program_version(db)
    next_version_num = version_num + 1 if draft_count > 0 else version_num

    msg_setting = db.query(ProgramSetting).filter(ProgramSetting.key == "coordinator_message").first()
    time_setting = db.query(ProgramSetting).filter(ProgramSetting.key == "coordinator_time").first()
    day_setting = db.query(ProgramSetting).filter(ProgramSetting.key == "program_day").first()

    return {
        "program_title": "SorSU × CTU Exchange - Can Tho Program",
        "current_version": f"Draft · v{version_num}" if draft_count > 0 else f"Published · v{version_num}",
        "published_version": f"v{version_num}",
        "next_version": f"v{next_version_num}",
        "metrics": {
            "total_activities": total_activities,
            "published_activities": published_count,
            "draft_activities": draft_count,
            "pending_approvals": pending_approvals,
            "registered_participants": total_users,
            "approved_articles": cultural_articles_count,
            "total_locations": total_locations
        },
        "coordinator_note": msg_setting.value if msg_setting else "",
        "coordinator_time": time_setting.value if time_setting else "",
        "program_day": int(day_setting.value) if day_setting and day_setting.value.isdigit() else 1
    }

@app.get("/api/admin/approvals")
def get_admin_approvals(status: Optional[str] = "pending", db: Session = Depends(get_db)):
    """Returns faculty change requests across all days"""
    query = db.query(ItineraryApproval)
    if status and status != "all":
        query = query.filter(ItineraryApproval.status == status)
    approvals = query.order_by(ItineraryApproval.day_number, ItineraryApproval.id).all()
    return [
        {
            "id": app.id,
            "activity_id": app.activity_id,
            "day_number": app.day_number,
            "title": app.title,
            "proposed_time": app.proposed_time,
            "change_description": app.change_description,
            "proposed_by": app.proposed_by,
            "status": app.status
        } for app in approvals
    ]

@app.get("/api/admin/planner")
def get_admin_planner(day: int = 3, db: Session = Depends(get_db)):
    """Returns activities for planner including drafts and drag-reordering"""
    activities = db.query(ItineraryActivity).filter(
        ItineraryActivity.day_number == day
    ).order_by(ItineraryActivity.display_order, ItineraryActivity.start_time).all()

    approvals = db.query(ItineraryApproval).filter(
        ItineraryApproval.status == "pending"
    ).all()

    return {
        "day": day,
        "total_activities": len(activities),
        "activities": [ItineraryActivityModel.from_orm(a) for a in activities],
        "pending_reviews": [
            {
                "id": app.id,
                "activity_id": app.activity_id,
                "day_number": app.day_number,
                "title": app.title,
                "proposed_time": app.proposed_time,
                "change_description": app.change_description,
                "proposed_by": app.proposed_by
            } for app in approvals
        ]
    }

@app.post("/api/admin/planner/activity")
def create_planner_activity(req: ActivityCreateRequest, db: Session = Depends(get_db)):
    day_count = db.query(ItineraryActivity).filter(ItineraryActivity.day_number == req.day_number).count()
    new_id = f"ACT-D{req.day_number}-{uuid.uuid4().hex[:6].upper()}"
    version_num = _get_program_version(db)

    activity = ItineraryActivity(
        activity_id=new_id,
        day_number=req.day_number,
        date=req.date,
        start_time=req.start_time,
        end_time=req.end_time,
        title=req.title,
        venue_name=req.venue_name,
        target_audience=req.target_audience,
        description=req.description,
        location_id=req.location_id,
        status=req.status if req.status in ["draft", "published"] else "draft",
        version=version_num,
        display_order=day_count + 1
    )
    db.add(activity)
    db.commit()
    db.refresh(activity)
    return activity

@app.put("/api/admin/planner/activity/{activity_id}")
def update_planner_activity(
    activity_id: str,
    req: ActivityUpdateRequest,
    db: Session = Depends(get_db)
):
    activity = db.query(ItineraryActivity).filter(
        ItineraryActivity.activity_id == activity_id
    ).first()
    if not activity:
        raise HTTPException(status_code=404, detail="Activity not found")

    if req.day_number is not None:
        activity.day_number = req.day_number
    if req.date is not None:
        activity.date = req.date
    if req.start_time is not None:
        activity.start_time = req.start_time
    if req.end_time is not None:
        activity.end_time = req.end_time
    if req.title is not None:
        activity.title = req.title
    if req.venue_name is not None:
        activity.venue_name = req.venue_name
    if req.target_audience is not None:
        activity.target_audience = req.target_audience
    if req.description is not None:
        activity.description = req.description
    if req.location_id is not None:
        activity.location_id = req.location_id or None
    if req.status is not None:
        activity.status = req.status

    db.commit()
    db.refresh(activity)
    return activity

@app.post("/api/admin/planner/publish")
def publish_itinerary_version(db: Session = Depends(get_db)):
    """Publishes all current drafts into the next official published version"""
    drafts = db.query(ItineraryActivity).filter(ItineraryActivity.status == "draft").all()
    count = len(drafts)
    current_ver = _get_program_version(db)
    new_ver = current_ver + 1 if count > 0 else current_ver

    for d in drafts:
        d.status = "published"
        d.version = new_ver

    ver_setting = db.query(ProgramSetting).filter(ProgramSetting.key == "itinerary_version").first()
    if not ver_setting:
        db.add(ProgramSetting(key="itinerary_version", value=str(new_ver)))
    else:
        ver_setting.value = str(new_ver)

    db.commit()
    return {
        "status": "success",
        "message": f"Successfully published version v{new_ver} with {count} updated activities.",
        "published_version": f"v{new_ver}",
        "published_count": count
    }

@app.delete("/api/admin/planner/discard")
def discard_itinerary_drafts(db: Session = Depends(get_db)):
    """Deletes all unpublished draft activities"""
    deleted_count = db.query(ItineraryActivity).filter(ItineraryActivity.status == "draft").delete()
    db.commit()
    return {
        "status": "success",
        "message": f"Discarded {deleted_count} unpublished draft activities.",
        "deleted_count": deleted_count
    }

@app.post("/api/admin/approvals/action")
def act_on_approval(req: ApprovalActionRequest, db: Session = Depends(get_db)):
    approval = db.query(ItineraryApproval).filter(ItineraryApproval.id == req.approval_id).first()
    if not approval:
        raise HTTPException(status_code=404, detail="Approval request not found")

    if req.action == "approve":
        approval.status = "approved"
        act = db.query(ItineraryActivity).filter(ItineraryActivity.activity_id == approval.activity_id).first()
        if act:
            if "-" in approval.proposed_time:
                parts = [p.strip() for p in approval.proposed_time.split("-")]
                if len(parts) == 2 and parts[1]:
                    act.end_time = parts[1]
            if act.status == "draft":
                act.status = "published"
    else:
        approval.status = "rejected"

    db.commit()
    return {"status": "success", "new_status": approval.status}

# ================= COORDINATOR BROADCAST NOTICE =================

@app.get("/api/broadcast")
def get_broadcast_notice(db: Session = Depends(get_db)):
    msg_setting = db.query(ProgramSetting).filter(ProgramSetting.key == "coordinator_message").first()
    time_setting = db.query(ProgramSetting).filter(ProgramSetting.key == "coordinator_time").first()
    day_setting = db.query(ProgramSetting).filter(ProgramSetting.key == "program_day").first()

    return {
        "message": msg_setting.value if msg_setting else "",
        "time_label": time_setting.value if time_setting else "",
        "day_number": int(day_setting.value) if day_setting and day_setting.value.isdigit() else 1
    }

@app.post("/api/admin/broadcast")
def update_broadcast_notice(req: BroadcastUpdateRequest, db: Session = Depends(get_db)):
    def set_val(k, v):
        item = db.query(ProgramSetting).filter(ProgramSetting.key == k).first()
        if not item:
            item = ProgramSetting(key=k, value=str(v))
            db.add(item)
        else:
            item.value = str(v)

    set_val("coordinator_message", req.message.strip())
    set_val("coordinator_time", (req.time_label or "").strip())
    if req.day_number:
        set_val("program_day", req.day_number)
    db.commit()
    return {"status": "success", "message": "Broadcast notice updated"}

# ================= ADMIN ITINERARY DELETE =================

@app.delete("/api/admin/planner/activity/{activity_id}")
def delete_planner_activity(activity_id: str, db: Session = Depends(get_db)):
    activity = db.query(ItineraryActivity).filter(
        ItineraryActivity.activity_id == activity_id
    ).first()
    if not activity:
        raise HTTPException(status_code=404, detail="Activity not found")
    db.delete(activity)
    db.commit()
    return {"status": "success", "message": f"Activity {activity_id} deleted"}

# ================= ADMIN CULTURAL ARTICLES CRUD =================

@app.get("/api/culture/latest", response_model=Optional[CulturalArticleModel])
def get_latest_cultural_article(db: Session = Depends(get_db)):
    article = db.query(CulturalArticle).filter(
        CulturalArticle.status == "published"
    ).order_by(CulturalArticle.last_updated.desc()).first()
    return article

@app.get("/api/admin/culture", response_model=List[CulturalArticleModel])
def get_admin_cultural_articles(
    category: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(CulturalArticle)
    if category and category.lower() != "all":
        query = query.filter(CulturalArticle.category.ilike(category))
    return query.order_by(CulturalArticle.last_updated.desc()).all()

@app.post("/api/admin/culture")
def create_cultural_article(req: CulturalArticleCreateRequest, db: Session = Depends(get_db)):
    new_id = f"ART-{uuid.uuid4().hex[:6].upper()}"

    article = CulturalArticle(
        content_id=new_id,
        title=req.title,
        category=req.category,
        summary=req.summary,
        content=req.content,
        fact_1=req.fact_1,
        fact_2=req.fact_2,
        vietnamese_word=req.vietnamese_word,
        word_translation=req.word_translation,
        source_title=req.source_title,
        source_author=req.source_author,
        source_date=req.source_date,
        source_label=req.source_label,
        location_id=req.location_id or None,
        status=req.status
    )
    db.add(article)
    db.commit()
    db.refresh(article)
    return article

@app.put("/api/admin/culture/{content_id}")
def update_cultural_article(content_id: str, req: CulturalArticleCreateRequest, db: Session = Depends(get_db)):
    article = db.query(CulturalArticle).filter(CulturalArticle.content_id == content_id).first()
    if not article:
        raise HTTPException(status_code=404, detail="Cultural article not found")

    article.title = req.title
    article.category = req.category
    article.summary = req.summary
    article.content = req.content
    article.fact_1 = req.fact_1
    article.fact_2 = req.fact_2
    article.vietnamese_word = req.vietnamese_word
    article.word_translation = req.word_translation
    article.source_title = req.source_title
    article.source_author = req.source_author
    article.source_date = req.source_date
    article.source_label = req.source_label
    article.location_id = req.location_id or None
    article.status = req.status

    db.commit()
    db.refresh(article)
    return article

@app.delete("/api/admin/culture/{content_id}")
def delete_cultural_article(content_id: str, db: Session = Depends(get_db)):
    article = db.query(CulturalArticle).filter(CulturalArticle.content_id == content_id).first()
    if not article:
        raise HTTPException(status_code=404, detail="Cultural article not found")

    db.query(QRMappping).filter(QRMappping.content_id == content_id).delete()
    db.delete(article)
    db.commit()
    return {"status": "success", "message": f"Article {content_id} deleted"}

# ================= ADMIN LOCATIONS CRUD =================

@app.post("/api/admin/locations")
def create_location(req: LocationCreateRequest, db: Session = Depends(get_db)):
    loc_id = req.location_id.strip() or f"LOC-{uuid.uuid4().hex[:6].upper()}"
    existing = db.query(Location).filter(Location.location_id == loc_id).first()
    if existing:
        raise HTTPException(status_code=400, detail="Location ID already exists")

    loc = Location(
        location_id=loc_id,
        name=req.name,
        address=req.address,
        latitude=req.latitude,
        longitude=req.longitude,
        map_reference=req.map_reference,
        description=req.description
    )
    db.add(loc)
    db.commit()
    db.refresh(loc)
    return loc

@app.put("/api/admin/locations/{location_id}")
def update_location(location_id: str, req: LocationUpdateRequest, db: Session = Depends(get_db)):
    loc = db.query(Location).filter(Location.location_id == location_id).first()
    if not loc:
        raise HTTPException(status_code=404, detail="Location not found")

    if req.name is not None:
        loc.name = req.name
    if req.address is not None:
        loc.address = req.address
    if req.latitude is not None:
        loc.latitude = req.latitude
    if req.longitude is not None:
        loc.longitude = req.longitude
    if req.map_reference is not None:
        loc.map_reference = req.map_reference
    if req.description is not None:
        loc.description = req.description

    db.commit()
    db.refresh(loc)
    return loc

@app.delete("/api/admin/locations/{location_id}")
def delete_location(location_id: str, db: Session = Depends(get_db)):
    loc = db.query(Location).filter(Location.location_id == location_id).first()
    if not loc:
        raise HTTPException(status_code=404, detail="Location not found")

    # Detach foreign key references cleanly before deletion
    db.query(ItineraryActivity).filter(ItineraryActivity.location_id == location_id).update({"location_id": None})
    db.query(CulturalArticle).filter(CulturalArticle.location_id == location_id).update({"location_id": None})
    db.query(QRMappping).filter(QRMappping.location_id == location_id).delete()

    db.delete(loc)
    db.commit()
    return {"status": "success", "message": f"Location {location_id} deleted"}

@app.get("/")
def get_root():
    return {
        "title": "SorSU × CTU Exchange Program - Cultural Information Assistant",
        "mobile_app_url": "/app/",
        "admin_console_url": "/admin/",
        "api_docs_url": "/docs",
        "technology_stack": {
            "backend": "Python (FastAPI)",
            "database": "PostgreSQL (cultural_db)",
            "mobile_frontend": "Flutter (Dart)",
            "admin_console": "JavaScript"
        }
    }

# Mount static files if web directory exists
web_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "web_app")
if os.path.exists(web_dir):
    app.mount("/app", StaticFiles(directory=web_dir, html=True), name="web_app")

admin_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "admin_app")
if os.path.exists(admin_dir):
    app.mount("/admin", StaticFiles(directory=admin_dir, html=True), name="admin_app")
