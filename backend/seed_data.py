import os
import sys
from datetime import datetime

# Add parent directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.database import SessionLocal, engine, Base
from backend.models import (
    User, Location, ItineraryActivity, CulturalArticle, 
    QRMappping, ItineraryApproval, GuideQueryLog, ProgramSetting
)

def init_db():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    # Clear existing data for clean seed
    db.query(ProgramSetting).delete()
    db.query(GuideQueryLog).delete()
    db.query(ItineraryApproval).delete()
    db.query(QRMappping).delete()
    db.query(CulturalArticle).delete()
    db.query(ItineraryActivity).delete()
    db.query(Location).delete()
    db.query(User).delete()
    db.commit()

    print("Cleared existing tables. Seeding initial data...")

    # 1. Seed Users
    users = [
        User(
            invite_code="SORSU-STU-01",
            full_name="Mika Reyes",
            email="mika.reyes@sorsu.edu.ph",
            role="student",
            cohort="SorSU · Cohort A",
            avatar_initials="MR"
        ),
        User(
            invite_code="SORSU-PROF-01",
            full_name="Dr. Eduardo Santos",
            email="e.santos@sorsu.edu.ph",
            role="professor",
            cohort="SorSU Faculty Delegation",
            avatar_initials="ES"
        ),
        User(
            invite_code="ADMIN-CTU-01",
            full_name="Admin SorSU & CTU Coordinator",
            email="coordinator@ctu.edu.vn",
            role="admin",
            cohort="SorSU × CTU Joint Secretariat",
            avatar_initials="AD"
        ),
        User(
            invite_code="CTU-BUDDY-01",
            full_name="Nguyen Van Nam",
            email="nam.nv@ctu.edu.vn",
            role="student",
            cohort="CTU Host Student Partner",
            avatar_initials="NN"
        )
    ]
    db.add_all(users)
    db.commit()

    # 2. Seed Locations
    locations = [
        Location(
            location_id="LOC-CTU-GATE",
            name="CTU Main Gate",
            address="Campus II, 3/2 Street, Ninh Kieu, Can Tho",
            latitude=10.0299,
            longitude=105.7706,
            map_reference="CTU main gate",
            description="The primary assembly point for the SorSU delegation before departing for off-campus field excursions."
        ),
        Location(
            location_id="LOC-CAI-RANG",
            name="Cai Rang Floating Market",
            address="Hai Ba Trung / Can Tho River, Cai Rang, Can Tho",
            latitude=10.0055,
            longitude=105.7461,
            map_reference="Cai Rang market",
            description="The most famous wholesale floating market in the Mekong Delta where goods and produce are hung on 'bẹo' poles."
        ),
        Location(
            location_id="LOC-BINH-THUY",
            name="Binh Thuy Ancient House",
            address="144 Bui Huu Nghia, Binh Thuy, Can Tho",
            latitude=10.0617,
            longitude=105.7533,
            map_reference="Binh Thuy house",
            description="An exquisite 1870 French-colonial and Vietnamese heritage home of the Duong family, featured in international films."
        ),
        Location(
            location_id="LOC-HALL-B",
            name="Hall B, Can Tho University",
            address="Building B, Campus II, Can Tho University",
            latitude=10.0315,
            longitude=105.7689,
            map_reference="Hall B",
            description="Air-conditioned lecture and seminar hall for cultural exchange lectures and bilateral academic talks."
        ),
        Location(
            location_id="LOC-CTU-CANTEEN",
            name="CTU Canteen",
            address="Student Center Ground Floor, Campus II, CTU",
            latitude=10.0305,
            longitude=105.7698,
            map_reference="CTU canteen",
            description="Dining hall serving authentic Mekong river delta lunch dishes for participants and staff."
        ),
        Location(
            location_id="LOC-DORMITORY",
            name="CTU International Dormitory",
            address="Campus II Dormitory Block C, Can Tho",
            latitude=10.0280,
            longitude=105.7720,
            map_reference="Dormitory",
            description="Residential quarters for the visiting SorSU exchange delegates."
        ),
        Location(
            location_id="LOC-NINH-KIEU",
            name="Ninh Kieu Wharf",
            address="Hai Ba Trung Street, Tan An, Ninh Kieu, Can Tho",
            latitude=10.0338,
            longitude=105.7876,
            map_reference="Ninh Kieu wharf",
            description="Historic riverside promenade at the confluence of Hau River and Can Tho River."
        )
    ]
    db.add_all(locations)
    db.commit()

    # 3. Seed Itinerary Activities (Draft v4 / Published v4)
    activities = [
        # Day 1
        ItineraryActivity(
            activity_id="ACT-D1-01",
            day_number=1,
            date="2026-11-18",
            start_time="09:00",
            end_time="11:30",
            title="Delegation Arrival & Campus Welcome",
            venue_name="CTU Main Gate · Campus II",
            target_audience="Everyone",
            description="Official welcome reception by CTU Directorate and distribution of program materials and ID badges.",
            location_id="LOC-CTU-GATE",
            status="published",
            version=4,
            display_order=1
        ),
        ItineraryActivity(
            activity_id="ACT-D1-02",
            day_number=1,
            date="2026-11-18",
            start_time="14:00",
            end_time="16:30",
            title="Orientation & Safety Briefing",
            venue_name="Hall B · CTU",
            target_audience="Everyone",
            description="Overview of the 20-day SorSU x CTU exchange program schedule, health protocols, and cultural guidelines.",
            location_id="LOC-HALL-B",
            status="published",
            version=4,
            display_order=2
        ),
        # Day 2
        ItineraryActivity(
            activity_id="ACT-D2-01",
            day_number=2,
            date="2026-11-19",
            start_time="08:30",
            end_time="11:30",
            title="Campus Tour & Library Archive Walk",
            venue_name="CTU Learning Resource Center",
            target_audience="Everyone",
            description="Guided exploration of CTU research facilities and the Mekong River cultural studies archive.",
            location_id="LOC-HALL-B",
            status="published",
            version=4,
            display_order=1
        ),
        ItineraryActivity(
            activity_id="ACT-D2-02",
            day_number=2,
            date="2026-11-19",
            start_time="13:30",
            end_time="17:00",
            title="Academic Exchange Workshop I",
            venue_name="Hall B · SorSU only",
            target_audience="SorSU only",
            description="Joint research presentation on cross-border higher education and regional sustainability.",
            location_id="LOC-HALL-B",
            status="published",
            version=4,
            display_order=2
        ),
        # Day 3 (Matches the mockup in PDF pages 3, 4, 7, 13)
        ItineraryActivity(
            activity_id="ACT-D3-01",
            day_number=3,
            date="2026-11-20",
            start_time="07:30",
            end_time="11:30",
            title="Cai Rang floating market visit",
            venue_name="CTU main gate · Everyone",
            target_audience="Everyone",
            description="Early morning river excursion to Cai Rang floating market. Meet at CTU main gate at 07:30. Boat leaves at 07:45 sharp. Life jackets are required.",
            location_id="LOC-CAI-RANG",
            status="published",
            version=4,
            display_order=1
        ),
        ItineraryActivity(
            activity_id="ACT-D3-02",
            day_number=3,
            date="2026-11-20",
            start_time="12:00",
            end_time="13:30",
            title="Lunch",
            venue_name="CTU canteen · Everyone",
            target_audience="Everyone",
            description="Buffet lunch featuring Southern Vietnamese cuisine and seasonal Mekong tropical fruits.",
            location_id="LOC-CTU-CANTEEN",
            status="published",
            version=4,
            display_order=2
        ),
        ItineraryActivity(
            activity_id="ACT-D3-03",
            day_number=3,
            date="2026-11-20",
            start_time="14:00",
            end_time="16:00",
            title="Cultural talk",
            venue_name="Hall B · SorSU only",
            target_audience="SorSU only",
            description="Interactive lecture on the architectural evolution and family heritage of Can Tho ancient estates.",
            location_id="LOC-HALL-B",
            status="published",
            version=4,
            display_order=3
        ),
        ItineraryActivity(
            activity_id="ACT-D3-04",
            day_number=3,
            date="2026-11-20",
            start_time="18:00",
            end_time="20:00",
            title="Free time",
            venue_name="Dormitory · Everyone",
            target_audience="Everyone",
            description="Rest and independent study. Participants may explore nearby university student cafes or rest in dorms.",
            location_id="LOC-DORMITORY",
            status="published",
            version=4,
            display_order=4
        ),
        # Draft activity for Day 3 seen on admin page 13
        ItineraryActivity(
            activity_id="ACT-D3-05-DRAFT",
            day_number=3,
            date="2026-11-20",
            start_time="18:00",
            end_time="19:00",
            title="Staff briefing",
            venue_name="Staff Room 102 · Staff only",
            target_audience="Staff only",
            description="Administrative coordination meeting for SorSU faculty and CTU coordinators.",
            location_id="LOC-HALL-B",
            status="draft",
            version=4,
            display_order=5
        ),
        # Day 4
        ItineraryActivity(
            activity_id="ACT-D4-01",
            day_number=4,
            date="2026-11-21",
            start_time="08:30",
            end_time="12:00",
            title="Binh Thuy Ancient House Field Study",
            venue_name="Binh Thuy house · Everyone",
            target_audience="Everyone",
            description="On-site study of 19th-century French-Vietnamese architectural synthesis and family archive inspection.",
            location_id="LOC-BINH-THUY",
            status="published",
            version=4,
            display_order=1
        ),
        ItineraryActivity(
            activity_id="ACT-D4-02",
            day_number=4,
            date="2026-11-21",
            start_time="14:30",
            end_time="17:00",
            title="Traditional Music & Folk Performance",
            venue_name="Hall B · CTU",
            target_audience="Everyone",
            description="Live demonstration of UNESCO-recognized Đờn Ca Tài Tử southern musical instruments.",
            location_id="LOC-HALL-B",
            status="published",
            version=4,
            display_order=2
        )
    ]
    db.add_all(activities)
    db.commit()

    # 4. Seed Cultural Articles (6 approved articles matching Chapter 1, 2 and mockup)
    articles = [
        CulturalArticle(
            content_id="ART-001",
            title="Cai Rang floating market",
            category="Markets",
            summary="A short summary written from the approved article appears here. It never adds facts that are not in the source.",
            content="Cai Rang floating market is the largest and most characteristic water-borne trading center in the Mekong Delta. Established in the early 20th century, hundreds of boats gather before sunrise along the Can Tho River to wholesale seasonal agricultural produce. Vendors utilize a bamboo pole called 'cây bẹo' at the prow to hang samples of their goods, allowing buyers from afar to identify cargo without shouting.",
            fact_1="Boats display agricultural goods atop tall bamboo poles called 'cây bẹo' to advertise products across the river without vocal shouting.",
            fact_2="Trading activities peak between 06:00 and 08:30 AM before high temperatures and river traffic shift.",
            vietnamese_word="chợ nổi",
            word_translation="floating market",
            source_title="Can Tho Cultural Geography and Riverine Heritage",
            source_author="Chinh, N. V.",
            source_date="2024",
            source_label="A1 Chinh (2024)",
            location_id="LOC-CAI-RANG",
            status="published"
        ),
        CulturalArticle(
            content_id="ART-002",
            title="Binh Thuy Ancient House",
            category="Heritage",
            summary="A short summary from the approved article appears here, written only from that source.",
            content="Constructed in 1870 by the Duong family, the Binh Thuy Ancient House embodies a rare five-bay architectural synthesis of traditional Southern Vietnamese wooden framing and European neoclassical French exterior motifs. The building preserves century-old ironwood pillars, imported French floor tiles, and a prominent altar honoring ancestors. It served as a prominent filming location for the 1992 film 'L'Amant'.",
            fact_1="The residence combines European classical colonnades and archways with an interior five-compartment Southern Vietnamese timber altar framework.",
            fact_2="Over 150 rare antique artifacts and a famous collection of Mekong orchids are preserved within the courtyard.",
            vietnamese_word="nhà cổ",
            word_translation="ancient house",
            source_title="Architectural Synthesis in the Mekong Basin",
            source_author="Chinh, N. V. & Le, T. H.",
            source_date="2024",
            source_label="A1 Chinh (2024)",
            location_id="LOC-BINH-THUY",
            status="published"
        ),
        CulturalArticle(
            content_id="ART-003",
            title="Đờn Ca Tài Tử (Southern Folk Music)",
            category="Music",
            summary="UNESCO-recognized intangible cultural heritage musical art of the Southern Vietnamese river communities.",
            content="Đờn Ca Tài Tử is a musical art form developed in the Mekong Delta in the late 19th century. Rooted in court music and chamber poetry, it uses string instruments such as the đàn kìm (moon lute), đàn tranh (zither), and modified Spanish guitar (guitar phím lõm) to express heartfelt emotions of delta inhabitants.",
            fact_1="Recognized by UNESCO in 2013 as Intangible Cultural Heritage of Humanity.",
            fact_2="Musicians often perform spontaneously on river boats or verandahs after daily agricultural work.",
            vietnamese_word="đờn ca tài tử",
            word_translation="southern chamber folk music",
            source_title="Mekong Folk Arts and Intangible Heritage Records",
            source_author="Nguyen, T. P.",
            source_date="2023",
            source_label="B2 Nguyen (2023)",
            location_id="LOC-HALL-B",
            status="published"
        ),
        CulturalArticle(
            content_id="ART-004",
            title="Bánh Xèo & Mekong River Gastronomy",
            category="Food",
            summary="Traditional savory crispy turmeric pancakes served with over twenty varieties of wild river herbs.",
            content="Can Tho style Bánh Xèo is renowned for its large, paper-thin golden crepe infused with coconut milk and turmeric, folded over river shrimp, pork belly, bean sprouts, and mung beans. It is customarily eaten wrapped in wild forest leaves (lá cách, cải bẹ xanh) dipped into seasoned sweet-and-sour fish sauce with pickled carrots.",
            fact_1="Accompanied by more than 15 varieties of wild medicinal delta herbs and river greens.",
            fact_2="The batter includes freshly pressed coconut milk to create crispy yet tender edges.",
            vietnamese_word="bánh xèo",
            word_translation="sizzling savory pancake",
            source_title="Can Tho Culinary Identity and Delta Agro-Culture",
            source_author="Tran, M. D.",
            source_date="2024",
            source_label="C3 Tran (2024)",
            location_id="LOC-CTU-CANTEEN",
            status="published"
        ),
        CulturalArticle(
            content_id="ART-005",
            title="Ninh Kieu Wharf & Hau River Confluence",
            category="Heritage",
            summary="Historic port and civic promenade embodying Can Tho's nickname as the Western Capital.",
            content="Positioned on the right bank of the Hau River, Ninh Kieu Wharf has stood as the maritime and trading heartbeat of Can Tho since the 19th century. Today it hosts the illuminated pedestrian walking bridge, night markets, and serves as the gateway for river transport connecting the nine estuaries of the Mekong.",
            fact_1="Named in 1957 after the historic 1426 Ninh Kieu battle victory in Vietnamese history.",
            fact_2="Marks the hydrological meeting point of Can Tho River and the primary Hau River shipping channel.",
            vietnamese_word="bến tàu",
            word_translation="boat pier / wharf",
            source_title="Waterfront Cities of the Lower Mekong",
            source_author="Vu, D. K.",
            source_date="2022",
            source_label="D4 Vu (2022)",
            location_id="LOC-NINH-KIEU",
            status="published"
        ),
        CulturalArticle(
            content_id="ART-006",
            title="Khmer Pagodas of Can Tho",
            category="Words",
            summary="Sacred Theravada Buddhist centers reflecting the peaceful co-existence of Kinh and Khmer communities.",
            content="Can Tho houses significant Theravada Buddhist pagodas such as Chùa Munirangsyaram, built in 1946. Featuring soaring multi-tiered gables, ornate golden statues of Garuda and Naga serpents, these pagodas serve as educational and community centers celebrating major festivals like Chol Chnam Thmay and Ok Om Bok.",
            fact_1="Chùa Munirangsyaram is built according to Angkorian Theravada architectural canons in the center of Ninh Kieu.",
            fact_2="Acts as a cultural school teaching the ancient Khmer script and Buddhist philosophical texts.",
            vietnamese_word="chùa",
            word_translation="pagoda / temple",
            source_title="Multi-ethnic Heritage in the Southwest Region",
            source_author="Chinh, N. V.",
            source_date="2024",
            source_label="A1 Chinh (2024)",
            location_id="LOC-HALL-B",
            status="published"
        )
    ]
    db.add_all(articles)
    db.commit()

    # 5. Seed QR Mappings
    qr_mappings = [
        QRMappping(
            qr_id="QR-BINH-THUY-01",
            content_id="ART-002",
            location_id="LOC-BINH-THUY",
            landmark_name="Binh Thuy Ancient House",
            status="active"
        ),
        QRMappping(
            qr_id="QR-CAI-RANG-01",
            content_id="ART-001",
            location_id="LOC-CAI-RANG",
            landmark_name="Cai Rang Floating Market",
            status="active"
        ),
        QRMappping(
            qr_id="QR-CTU-GATE-01",
            content_id="ART-003",
            location_id="LOC-CTU-GATE",
            landmark_name="CTU Main Gate & Cultural Assembly",
            status="active"
        )
    ]
    db.add_all(qr_mappings)
    db.commit()

    # 6. Seed Admin Approvals (Matching PDF page 13: "2 changes from professors are waiting for your review")
    approvals = [
        ItineraryApproval(
            activity_id="ACT-D3-03",
            day_number=3,
            title="Cultural talk - Extend Q&A by 15 mins",
            proposed_time="14:00 - 16:15",
            change_description="Prof. Santos requests extending the Hall B discussion session to allow SorSU students to present their preliminary comparative reflections.",
            proposed_by="Prof. Eduardo Santos",
            status="pending"
        ),
        ItineraryApproval(
            activity_id="ACT-D3-05-DRAFT",
            day_number=3,
            title="Staff briefing inclusion in official schedule",
            proposed_time="18:00 - 19:00",
            change_description="Prof. Nguyen requests adding an official 45-minute faculty sync session regarding Day 4 field study transportation.",
            proposed_by="Prof. Nguyen Van Nam",
            status="pending"
        )
    ]
    db.add_all(approvals)
    db.commit()

    # 7. Seed Program Settings (Broadcast message)
    settings = [
        ProgramSetting(key="coordinator_message", value="Meet at the main gate 10 minutes early."),
        ProgramSetting(key="coordinator_time", value="06:10"),
        ProgramSetting(key="program_day", value="3")
    ]
    db.add_all(settings)
    db.commit()

    print("Seeding completed successfully!")
    db.close()

if __name__ == "__main__":
    init_db()
