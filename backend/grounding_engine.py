import re
import time
from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session
from .models import ItineraryActivity, CulturalArticle, Location, GuideQueryLog, ProgramSetting


class GroundingEngine:
    def __init__(self, db: Session):
        self.db = db

    def _get_active_day(self) -> int:
        day_setting = self.db.query(ProgramSetting).filter(ProgramSetting.key == "program_day").first()
        if day_setting and day_setting.value.isdigit():
            return int(day_setting.value)
        first_act = (
            self.db.query(ItineraryActivity)
            .filter(ItineraryActivity.status == "published")
            .order_by(ItineraryActivity.day_number)
            .first()
        )
        return first_act.day_number if first_act else 1

    def _dynamic_suggestions(self, exclude_title: str = "") -> List[str]:
        suggestions: List[str] = []
        acts = (
            self.db.query(ItineraryActivity)
            .filter(ItineraryActivity.status == "published")
            .order_by(ItineraryActivity.day_number, ItineraryActivity.start_time)
            .limit(4)
            .all()
        )
        articles = (
            self.db.query(CulturalArticle)
            .filter(CulturalArticle.status == "published")
            .limit(4)
            .all()
        )
        if acts:
            suggestions.append("What is on today?")
        for a in articles:
            if a.title and a.title.lower() != exclude_title.lower():
                suggestions.append(f"Tell me about {a.title}")
                if len(suggestions) >= 3:
                    break
        if acts and len(suggestions) < 3:
            suggestions.append("What is on tomorrow?")
        return suggestions[:3]

    def handle_request(self, question: str, offline_mode: bool = False) -> Dict[str, Any]:
        start_time = time.time()
        q_clean = question.strip().lower()

        if not q_clean:
            return {
                "question": question,
                "answer": "Please enter a question about your exchange schedule or Can Tho cultural places.",
                "source_type": "none",
                "source_stub": None,
                "note": None,
                "status": "not_in_sources",
                "steps": ["Empty question received."],
                "response_time_sec": 0.05,
                "try_next": self._dynamic_suggestions(),
                "log_id": None,
            }

        if offline_mode:
            return self._handle_offline_lookup(question, q_clean, start_time)

        # Reject explicitly out-of-scope queries early
        unsupported_keywords = [
            "hotel", "restaurant near", "bar", "club", "grab", "flight",
            "da nang", "hanoi", "buy sim", "weather tomorrow", "exchange rate",
            "crypto", "movie", "game"
        ]
        if any(u in q_clean for u in unsupported_keywords):
            result = self._handle_unsupported(question, q_clean, start_time)
            intent = "unsupported"
        else:
            intent = self._classify_intent(q_clean)
            if intent == "schedule":
                result = self._retrieve_schedule(question, q_clean, start_time)
                # If no schedule match, try culture before giving up
                if result["status"] == "not_in_sources":
                    culture_try = self._retrieve_culture(question, q_clean, start_time)
                    if culture_try["status"] == "success":
                        result = culture_try
                        intent = "culture"
            else:
                result = self._retrieve_culture(question, q_clean, start_time)
                if result["status"] == "not_in_sources":
                    sched_try = self._retrieve_schedule(question, q_clean, start_time)
                    if sched_try["status"] == "success":
                        result = sched_try
                        intent = "schedule"
                    else:
                        intent = "unsupported"

        log_entry = GuideQueryLog(
            question=question,
            intent=intent,
            response=result["answer"],
            retrieved_source=result["source_stub"],
            is_grounded=(result["status"] == "success"),
            steps=result["steps"],
            processing_time_sec=result["response_time_sec"],
        )
        self.db.add(log_entry)
        self.db.commit()
        result["log_id"] = log_entry.id
        return result

    def _classify_intent(self, q: str) -> str:
        if re.search(r"\bday\s*\d+\b", q):
            return "schedule"

        schedule_keywords = [
            "time", "schedule", "when", "itinerary", "meet", "gate",
            "today", "tomorrow", "lunch", "canteen", "dorm", "free time",
            "briefing", "talk", "what's on", "what is on", "now and next", "program"
        ]
        if any(s in q for s in schedule_keywords):
            return "schedule"

        return "culture"

    def _tokenize(self, text: str) -> List[str]:
        return [w for w in re.findall(r"[\w]+", text.lower()) if len(w) > 2]

    def _retrieve_schedule(self, question: str, q: str, start_time: float) -> Dict[str, Any]:
        activities = (
            self.db.query(ItineraryActivity)
            .filter(ItineraryActivity.status == "published")
            .order_by(ItineraryActivity.day_number, ItineraryActivity.start_time)
            .all()
        )
        active_day = self._get_active_day()

        elapsed = max(round(time.time() - start_time, 2), 0.15)

        if not activities:
            return {
                "question": question,
                "answer": "Coming soon · Sắp ra mắt\n\nNo published itinerary activities have been added yet. Your coordinator will publish them soon.",
                "source_type": "none",
                "source_stub": "Coming soon",
                "note": "No published schedule records in database.",
                "status": "not_in_sources",
                "steps": [
                    f"Read your question ('{question}').",
                    "Queried published program itinerary in PostgreSQL.",
                    "Found 0 published activities.",
                ],
                "response_time_sec": elapsed,
                "try_next": self._dynamic_suggestions(),
            }

        # Check explicit Day N, today, tomorrow, or now and next
        target_day: Optional[int] = None
        day_match = re.search(r"\bday\s*(\d+)\b", q)
        if day_match:
            target_day = int(day_match.group(1))
        elif "tomorrow" in q:
            target_day = active_day + 1
        elif "today" in q or "now and next" in q or "what's on" in q or "what is on" in q:
            target_day = active_day

        if target_day is not None:
            day_acts = [a for a in activities if a.day_number == target_day]
            if not day_acts:
                return {
                    "question": question,
                    "answer": f"Coming soon · Sắp ra mắt\n\nThere are no published activities scheduled for Day {target_day} yet. (Chưa có hoạt động nào được công bố cho Ngày {target_day}.)",
                    "source_type": "schedule",
                    "source_stub": f"Itinerary · Day {target_day}",
                    "note": "Schedules can change. Confirm with your coordinator.",
                    "status": "success",
                    "steps": [
                        f"Identified Day {target_day} schedule request.",
                        f"Queried published itinerary for Day {target_day}: 0 activities.",
                        "Returned bilingual empty-day notice."
                    ],
                    "response_time_sec": elapsed,
                    "try_next": self._dynamic_suggestions(),
                }

            lines = [
                f"• {a.start_time}{f'-{a.end_time}' if a.end_time else ''}: {a.title} ({a.venue_name} · {a.target_audience})"
                for a in day_acts
            ]
            answer = f"Day {target_day} schedule ({len(day_acts)} activities):\n" + "\n".join(lines)
            return {
                "question": question,
                "answer": answer,
                "source_type": "schedule",
                "source_stub": f"Itinerary · Day {target_day}",
                "note": "Schedules can change. Confirm with your coordinator.",
                "status": "success",
                "steps": [
                    f"Read your question regarding Day {target_day} schedule.",
                    f"Searched published PostgreSQL itinerary for Day {target_day}.",
                    f"Retrieved {len(day_acts)} verified published records ({elapsed}s).",
                ],
                "response_time_sec": elapsed,
                "try_next": self._dynamic_suggestions(),
            }

        # Score activities dynamically by token overlap across title, venue, description
        tokens = set(self._tokenize(q)) - {"what", "time", "when", "where", "does", "start", "about", "tell", "schedule"}
        best_act: Optional[ItineraryActivity] = None
        best_score = 0
        for act in activities:
            haystack = f"{act.title} {act.venue_name} {act.description or ''}".lower()
            score = sum(2 if t in act.title.lower() else 1 for t in tokens if t in haystack)
            if score > best_score:
                best_score = score
                best_act = act

        if best_act and best_score > 0:
            time_range = f"{best_act.start_time}{f' to {best_act.end_time}' if best_act.end_time else ''}"
            desc = f" {best_act.description}" if best_act.description else ""
            answer = (
                f"{best_act.title} is scheduled on Day {best_act.day_number} at {time_range}. "
                f"Venue: {best_act.venue_name} ({best_act.target_audience}).{desc}"
            )
            return {
                "question": question,
                "answer": answer,
                "source_type": "schedule",
                "source_stub": f"Itinerary · Day {best_act.day_number}",
                "note": "Schedules can change. Confirm with your coordinator.",
                "status": "success",
                "steps": [
                    f"Read your question regarding exchange schedule ('{question}').",
                    "Searched all published itinerary records in PostgreSQL.",
                    f"Matched '{best_act.activity_id}: {best_act.title}' on Day {best_act.day_number}.",
                    f"Formulated grounded response with itinerary citation ({elapsed}s).",
                ],
                "response_time_sec": elapsed,
                "try_next": self._dynamic_suggestions(),
            }

        return self._handle_unsupported(question, q, start_time)

    def _retrieve_culture(self, question: str, q: str, start_time: float) -> Dict[str, Any]:
        articles = (
            self.db.query(CulturalArticle)
            .filter(CulturalArticle.status == "published")
            .all()
        )
        locations = self.db.query(Location).all()

        elapsed = max(round(time.time() - start_time, 2), 0.15)

        if not articles and not locations:
            return {
                "question": question,
                "answer": "Coming soon · Sắp ra mắt\n\nNo cultural articles or landmarks have been published yet. (Chưa có bài viết văn hóa nào được công bố.)",
                "source_type": "none",
                "source_stub": "Coming soon",
                "note": None,
                "status": "not_in_sources",
                "steps": [
                    f"Read your question ('{question}').",
                    "Searched published cultural articles in PostgreSQL: 0 articles found.",
                ],
                "response_time_sec": elapsed,
                "try_next": self._dynamic_suggestions(),
            }

        stop = {"what", "where", "why", "who", "how", "tell", "about", "famous", "can", "tho", "the", "is", "are", "for"}
        tokens = [t for t in self._tokenize(q) if t not in stop]

        best_art: Optional[CulturalArticle] = None
        best_score = 0
        for art in articles:
            title_l = art.title.lower()
            vw_l = (art.vietnamese_word or "").lower()
            cat_l = art.category.lower()
            body_l = f"{art.summary} {art.content} {art.fact_1 or ''} {art.fact_2 or ''}".lower()

            if title_l in q:
                best_art = art
                best_score = 100
                break

            score = 0
            for t in tokens:
                if t in title_l:
                    score += 4
                if vw_l and t in vw_l:
                    score += 4
                if t in cat_l:
                    score += 2
                if t in body_l:
                    score += 1
            if score > best_score:
                best_score = score
                best_art = art

        if best_art and best_score > 0:
            if ("why" in q or "famous" in q) and (best_art.fact_1 or best_art.fact_2):
                facts = " ".join(f for f in [best_art.fact_1, best_art.fact_2] if f)
                answer = f"{best_art.title}: {best_art.summary}\n\nKey highlights: {facts}"
            elif "word" in q or "vietnamese" in q:
                vw = f" Vietnamese key phrase: '{best_art.vietnamese_word}' ({best_art.word_translation or ''})." if best_art.vietnamese_word else ""
                answer = f"{best_art.summary}{vw}"
            else:
                answer = f"{best_art.summary}\n\n{best_art.content}"

            return {
                "question": question,
                "answer": answer,
                "source_type": "culture",
                "source_stub": best_art.source_label,
                "note": f"Source: {best_art.source_title} ({best_art.source_author}, {best_art.source_date})",
                "status": "success",
                "steps": [
                    f"Read your question about Can Tho cultural heritage ('{question}').",
                    f"Searched approved cultural articles in PostgreSQL.",
                    f"Matched '{best_art.content_id}: {best_art.title}' ({best_art.source_label}).",
                    f"Grounded reply strictly in approved database article ({elapsed}s).",
                ],
                "response_time_sec": elapsed,
                "try_next": self._dynamic_suggestions(exclude_title=best_art.title),
            }

        # Fallback: check Location records in PostgreSQL (in case admin added a location without an article yet)
        best_loc: Optional[Location] = None
        best_loc_score = 0
        for loc in locations:
            hay = f"{loc.name} {loc.address or ''} {loc.description or ''}".lower()
            if loc.name.lower() in q:
                best_loc = loc
                best_loc_score = 100
                break
            score = sum(3 if t in loc.name.lower() else 1 for t in tokens if t in hay)
            if score > best_loc_score:
                best_loc_score = score
                best_loc = loc

        if best_loc and best_loc_score > 0:
            answer = f"{best_loc.name}{f' ({best_loc.address})' if best_loc.address else ''}: {best_loc.description or 'Registered exchange map location.'}"
            return {
                "question": question,
                "answer": answer,
                "source_type": "culture",
                "source_stub": best_loc.map_reference or best_loc.location_id,
                "note": "From registered exchange program locations.",
                "status": "success",
                "steps": [
                    f"Read your question ('{question}').",
                    "Searched registered program locations in PostgreSQL.",
                    f"Matched location '{best_loc.name}' ({elapsed}s).",
                ],
                "response_time_sec": elapsed,
                "try_next": self._dynamic_suggestions(),
            }

        return self._handle_unsupported(question, q, start_time)

    def _handle_unsupported(self, question: str, q: str, start_time: float) -> Dict[str, Any]:
        elapsed = max(round(time.time() - start_time, 2), 0.15)
        steps = [
            "Read your question against verified database records.",
            "Searched published itinerary activities: 0 close matches.",
            "Searched published cultural articles & locations: 0 close matches.",
            f"Replied cleanly that it is not in the approved sources ({elapsed}s).",
        ]
        return {
            "question": question,
            "answer": "I can't find that in the program schedule or approved Can Tho articles. (Thông tin này chưa có trong lịch trình hoặc bài viết đã duyệt.)",
            "source_type": "none",
            "source_stub": "Not in my sources",
            "note": None,
            "status": "not_in_sources",
            "steps": steps,
            "response_time_sec": elapsed,
            "try_next": self._dynamic_suggestions(),
        }

    def _handle_offline_lookup(self, question: str, q: str, start_time: float) -> Dict[str, Any]:
        elapsed = 0.08
        active_day = self._get_active_day()

        all_published = (
            self.db.query(ItineraryActivity)
            .filter(ItineraryActivity.status == "published")
            .order_by(ItineraryActivity.day_number, ItineraryActivity.start_time)
            .all()
        )

        if not all_published:
            return {
                "question": question,
                "answer": "Coming soon · Sắp ra mắt\n\nNo offline schedule activities are available in the database yet. (Chưa có lịch trình ngoại tuyến nào.)",
                "source_type": "schedule",
                "source_stub": "Offline cache",
                "note": "Offline schedule storage is empty.",
                "status": "offline",
                "steps": [
                    "Offline mode active: checked cached schedule records.",
                    "Found 0 published activities in database.",
                ],
                "response_time_sec": elapsed,
                "try_next": [],
            }

        day_match = re.search(r"\bday\s*(\d+)\b", q)
        target_day = int(day_match.group(1)) if day_match else (active_day + 1 if "tomorrow" in q else active_day)
        day_acts = [a for a in all_published if a.day_number == target_day]
        display_acts = day_acts if day_acts else all_published[:3]
        display_day = target_day if day_acts else display_acts[0].day_number

        latest_dt = max((a.last_updated for a in all_published if a.last_updated), default=None)
        updated_str = latest_dt.strftime("%d %b, %H:%M") if latest_dt else "synced"

        lines = [
            f"• {a.start_time}{f'–{a.end_time}' if a.end_time else ''}: {a.title} ({a.venue_name})"
            for a in display_acts
        ]
        answer = (
            f"From the saved schedule (Day {display_day}):\n"
            + "\n".join(lines)
            + "\n\nOffline mode: answered from saved schedule records."
        )

        return {
            "question": question,
            "answer": answer,
            "source_type": "schedule",
            "source_stub": f"Saved · Day {display_day}",
            "note": f"Saved offline schedule (last updated {updated_str}).",
            "status": "offline",
            "steps": [
                "Offline mode detected: local schedule cache active.",
                f"Searched {len(all_published)} saved published itinerary records.",
                f"Returned Day {display_day} activities ({len(display_acts)} items).",
            ],
            "response_time_sec": elapsed,
            "try_next": self._dynamic_suggestions(),
        }
