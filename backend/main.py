import os
import json
from pathlib import Path
from contextlib import asynccontextmanager
import asyncio
import time
from datetime import date
import asyncpg
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from jose import JWTError, jwt
from typing import Any

from auth import (
    SignupRequest,
    LoginRequest,
    create_access_token,
    hash_password,
    verify_password,
    SECRET_KEY,
    ALGORITHM,
)


# Force-load project root .env
ROOT_ENV = Path(__file__).resolve().parents[1] / ".env"
load_dotenv(ROOT_ENV)

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5432/fitapp",  # fallback only
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create DB pool with retry/backoff to tolerate transient DB recovery states
    max_wait = int(os.getenv("DB_CONNECT_TIMEOUT", "60"))
    backoff = 1
    start_ts = time.time()
    while True:
        try:
            app.state.db_pool = await asyncpg.create_pool(DATABASE_URL, min_size=1, max_size=5)
            break
        except Exception as e:
            # If we've waited long enough, re-raise to fail fast
            if time.time() - start_ts > max_wait:
                raise
            await asyncio.sleep(backoff)
            backoff = min(backoff * 2, 5)
    # Ensure weekly plan table exists on startup
    async with app.state.db_pool.acquire() as _conn:
        await _conn.execute("""
            ALTER TABLE IF EXISTS training
            ADD COLUMN IF NOT EXISTS user_id INT
        """)
        await _conn.execute("""
            ALTER TABLE IF EXISTS training_exercise
            ADD COLUMN IF NOT EXISTS sets INT,
            ADD COLUMN IF NOT EXISTS reps INT,
            ADD COLUMN IF NOT EXISTS weight FLOAT,
            ADD COLUMN IF NOT EXISTS notes TEXT
        """)
        await _conn.execute("""
            UPDATE training t
            SET user_id = bm.user_id
            FROM training_body tb
            JOIN body_metrics bm ON bm.body_id = tb.body_id
            WHERE t.train_id = tb.train_id
              AND t.user_id IS NULL
        """)
        await _conn.execute("""
            ALTER TABLE IF EXISTS body_metrics
            ADD COLUMN IF NOT EXISTS body_experience VARCHAR(20),
            ADD COLUMN IF NOT EXISTS body_location VARCHAR(20),
            ADD COLUMN IF NOT EXISTS body_days_per_week INT,
            ADD COLUMN IF NOT EXISTS body_session_length INT,
            ADD COLUMN IF NOT EXISTS body_injuries TEXT,
            ADD COLUMN IF NOT EXISTS body_diet_preference VARCHAR(50),
            ADD COLUMN IF NOT EXISTS body_allergies TEXT
        """)
        await _conn.execute("""
            CREATE TABLE IF NOT EXISTS user_weekly_plan (
                id SERIAL PRIMARY KEY,
                user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                plan JSONB NOT NULL DEFAULT '{}'::jsonb,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE (user_id)
            )
        """)
        await _conn.execute("""
            CREATE TABLE IF NOT EXISTS user_stats (
                id SERIAL PRIMARY KEY,
                user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                xp INT NOT NULL DEFAULT 0,
                level INT NOT NULL DEFAULT 1,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE (user_id)
            )
        """)
    try:
        yield
    finally:
        await app.state.db_pool.close()


app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:60107",  # current Flutter web port
        "http://localhost:5000",
        "http://localhost:3000",
        "http://127.0.0.1:60107",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:3000",
    ],
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================== AUTH ENDPOINTS ====================
@app.post("/api/auth/signup")
async def signup(request: SignupRequest):
    """Register a new user"""
    try:
        async with app.state.db_pool.acquire() as connection:
            # Check if user already exists
            existing_user = await connection.fetchrow(
                "SELECT user_id FROM users WHERE user_email = $1",
                request.email
            )
            if existing_user:
                raise HTTPException(status_code=400, detail="Email already registered")

            # Hash password
            hashed_password = hash_password(request.password)
            
            # Insert new user
            user = await connection.fetchrow(
                """
                INSERT INTO users (user_name, user_email, user_password)
                VALUES ($1, $2, $3)
                RETURNING user_id, user_email, user_name
                """,
                request.username,
                request.email,
                hashed_password
            )

            # Create access token
            access_token = create_access_token(data={"sub": str(user["user_id"])})

            return {
                "access_token": access_token,
                "token_type": "bearer",
                "user": {
                    "user_id": user["user_id"],
                    "email": user["user_email"],
                    "username": user["user_name"]
                }
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Signup failed: {str(e)}")


@app.post("/api/auth/login")
async def login(request: LoginRequest):
    """Log in an existing user"""
    try:
        async with app.state.db_pool.acquire() as connection:
            # Find user by email
            user = await connection.fetchrow(
                "SELECT user_id, user_email, user_name, user_password FROM users WHERE user_email = $1",
                request.email
            )
            
            if not user:
                raise HTTPException(status_code=404, detail="User not found")
            
            # Verify password
            if not verify_password(request.password, user["user_password"]):
                raise HTTPException(status_code=401, detail="Invalid password")

            # Create access token
            access_token = create_access_token(data={"sub": str(user["user_id"])})

            return {
                "access_token": access_token,
                "token_type": "bearer",
                "user": {
                    "user_id": user["user_id"],
                    "email": user["user_email"],
                    "username": user["user_name"]
                }
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Login failed: {str(e)}")


# ==================== DEPENDENCY: Get Current User ====================
async def get_current_user_id(authorization: str = Header(None)) -> int:
    """Extract user ID from JWT token in Authorization header"""
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing authorization header")
    
    try:
        token = authorization.replace("Bearer ", "")
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return int(user_id)
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")


# ==================== USER ENDPOINTS ====================
class QuestionnaireRequest(BaseModel):
    age: int
    height: float
    weight: float
    goal: str
    experience: str
    location: str
    days_per_week: int
    session_length: int
    injuries: list
    diet_preference: str
    allergies: list


WEEK_DAYS = [
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
    "sunday",
]

DAY_LABELS = {
    "monday": "Monday",
    "tuesday": "Tuesday",
    "wednesday": "Wednesday",
    "thursday": "Thursday",
    "friday": "Friday",
    "saturday": "Saturday",
    "sunday": "Sunday",
}


def _clamp_int(value: int, minimum: int, maximum: int) -> int:
    return max(minimum, min(maximum, value))


def _round_to_increment(value: float, increment: float = 2.5) -> float:
    if value <= 0:
        return 0.0
    return round(value / increment) * increment


def _slugify(value: str) -> str:
    return " ".join(value.strip().split()).lower()


def _normalize_list(values: Any) -> list[str]:
    if not values:
        return []
    if isinstance(values, str):
        return [values]
    if isinstance(values, list):
        return [str(item) for item in values if str(item).strip()]
    return [str(values)]


def _infer_equipment(location: str, preference_notes: list[str] | None = None) -> list[str]:
    location_l = _slugify(location)
    notes = " ".join((preference_notes or [])).lower()

    if "home" in location_l:
        equipment = ["bodyweight", "dumbbell", "mat"]
    elif "gym" in location_l:
        equipment = ["machine", "dumbbell", "barbell", "cable", "kettlebell"]
    else:
        equipment = ["bodyweight"]

    if "dumbbell" in notes and "dumbbell" not in equipment:
        equipment.append("dumbbell")
    if "machine" in notes and "machine" not in equipment:
        equipment.append("machine")

    return equipment


def _infer_goal_slug(goal: str) -> str:
    g = _slugify(goal)
    if any(word in g for word in ["lose", "fat", "cut"]):
        return "fat_loss"
    if any(word in g for word in ["gain", "build", "muscle", "hypertrophy"]):
        return "muscle_gain"
    if any(word in g for word in ["strength", "strong"]):
        return "strength"
    if any(word in g for word in ["endurance", "cardio", "stamina"]):
        return "endurance"
    return "general_fitness"


def _infer_experience_slug(experience: str) -> str:
    e = _slugify(experience)
    if "advanced" in e:
        return "advanced"
    if "intermediate" in e:
        return "intermediate"
    return "beginner"


def _infer_injury_areas(injuries: list[str]) -> set[str]:
    result: set[str] = set()
    for injury in injuries:
        s = _slugify(injury)
        if not s or s == "none":
            continue
        if "shoulder" in s:
            result.update({"shoulder", "chest", "triceps"})
        if "elbow" in s or "wrist" in s:
            result.update({"arms", "triceps", "biceps", "shoulder"})
        if "back" in s:
            result.update({"back", "lower back", "core"})
        if "knee" in s:
            result.update({"legs", "quadriceps", "hamstrings", "calves", "glutes"})
        if "hip" in s:
            result.update({"hips", "glutes", "legs"})
        if "ankle" in s:
            result.update({"calves", "legs", "jump"})
    return result


def _matches_any(value: str, keywords: list[str]) -> bool:
    value_l = value.lower()
    return any(keyword in value_l for keyword in keywords)


def _exercise_row_to_dict(row: asyncpg.Record | dict[str, Any]) -> dict[str, Any]:
    if isinstance(row, dict):
        return row
    return {
        "exer_id": row["exer_id"],
        "exer_name": row["exer_name"],
        "exer_body_area": row["exer_body_area"] or "Unknown",
        "exer_type": row["exer_type"] or "strength",
        "exer_equip": row["exer_equip"] or "",
        "exer_descrip": row["exer_descrip"] or "",
        "exer_vid": row["exer_vid"] or "",
    }


def _exercise_is_safe(exercise: dict[str, Any], avoided_areas: set[str], equipment_keywords: list[str]) -> bool:
    body_area = _slugify(str(exercise.get("exer_body_area", "")))
    name = _slugify(str(exercise.get("exer_name", "")))
    equipment = _slugify(str(exercise.get("exer_equip", "")))

    if avoided_areas:
        if any(area in body_area or area in name for area in avoided_areas):
            return False

    if equipment_keywords:
        if not any(keyword in equipment for keyword in equipment_keywords):
            return False

    risky_terms = ["jump", "burpee", "snatch", "clean", "deadlift", "upright row", "overhead press"]
    if any(term in name for term in risky_terms):
        return False

    return True


def _exercise_score(
    exercise: dict[str, Any],
    desired_areas: list[str],
    preferred_equipment: list[str],
    goal_slug: str,
    role: str,
) -> float:
    body_area = _slugify(str(exercise.get("exer_body_area", "")))
    name = _slugify(str(exercise.get("exer_name", "")))
    equipment = _slugify(str(exercise.get("exer_equip", "")))
    ex_type = _slugify(str(exercise.get("exer_type", "")))

    score = 0.0
    for area in desired_areas:
        area_l = _slugify(area)
        if area_l and (area_l in body_area or area_l in name):
            score += 3.0

    for item in preferred_equipment:
        item_l = _slugify(item)
        if item_l and item_l in equipment:
            score += 2.0

    if goal_slug in {"strength", "muscle_gain"} and ex_type != "cardio":
        score += 1.5
    if goal_slug in {"fat_loss", "endurance"} and ex_type == "cardio":
        score += 2.5
    if role == "compound" and ex_type != "cardio":
        score += 1.5
    if role == "cardio" and ex_type == "cardio":
        score += 4.0

    # Bias towards safer, simpler exercises for new users.
    if goal_slug == "general_fitness" and ex_type != "cardio":
        score += 0.5

    return score


def _round_sets_value(value: float) -> float:
    return _round_to_increment(max(0.0, value))


def _estimate_1rm(exercise: dict[str, Any], body_weight: float, experience_slug: str, role: str) -> float:
    body_area = _slugify(str(exercise.get("exer_body_area", "")))
    is_lower = any(term in body_area for term in ["leg", "glute", "hamstring", "quadricep", "calf", "hip"])
    is_upper = any(term in body_area for term in ["chest", "back", "shoulder", "arm"])

    # Base multiplier of bodyweight to approximate 1RM (very rough)
    if is_lower:
        base_mult = 1.6
    elif is_upper:
        base_mult = 1.0
    else:
        base_mult = 0.9

    exp_mult = 0.85 if experience_slug == "beginner" else 1.0 if experience_slug == "intermediate" else 1.1

    est_1rm = body_weight * base_mult * exp_mult

    # Slightly boost compound movements
    if role == "compound":
        est_1rm *= 1.05

    return _round_to_increment(max(0.0, est_1rm))


def _estimate_starting_weight(
    exercise: dict[str, Any],
    experience_slug: str,
    body_weight: float,
    role: str,
) -> float:
    ex_type = _slugify(str(exercise.get("exer_type", "")))
    name = _slugify(str(exercise.get("exer_name", "")))
    equipment = _slugify(str(exercise.get("exer_equip", "")))

    # Cardio / bodyweight / isometric -> no numeric kg
    if "cardio" in ex_type or any(term in equipment for term in ["bodyweight", "none"]) or any(
        term in name for term in ["plank", "hold", "wall sit", "isometric"]
    ):
        return 0.0

    est_1rm = _estimate_1rm(exercise, body_weight, experience_slug, role)

    # Target working % depending on goal/role
    # default working percentage for first program
    if role == "compound":
        target_pct = 0.70  # ~70% of 1RM for initial working sets
    elif role == "accessory":
        target_pct = 0.60
    else:
        target_pct = 0.60

    # Slightly adjust by experience
    if experience_slug == "beginner":
        target_pct *= 0.9
    elif experience_slug == "advanced":
        target_pct *= 1.05

    starting = est_1rm * target_pct
    return _round_to_increment(max(0.0, starting))


def _rep_range(goal_slug: str, experience_slug: str, role: str) -> tuple[int, int]:
    if goal_slug == "strength":
        return (4, 6) if role == "compound" else (6, 8)
    if goal_slug == "muscle_gain":
        return (6, 10) if role == "compound" else (10, 12)
    if goal_slug == "fat_loss":
        return (10, 14) if role == "compound" else (12, 16)
    if goal_slug == "endurance":
        return (12, 18) if role == "compound" else (15, 20)
    return (8, 12) if role == "compound" else (10, 15)


def _build_set_series(
    weight: float,
    goal_slug: str,
    experience_slug: str,
    role: str,
    is_cardio: bool,
    session_length: int,
) -> list[dict[str, Any]]:
    if is_cardio:
        duration = 18 if session_length <= 30 else 24 if session_length <= 45 else 30
        if goal_slug in {"fat_loss", "endurance"}:
            duration += 5
        return [
            {"time": duration, "calories": 0},
            {"time": max(10, duration - 5), "calories": 0},
        ]

    # choose reps based on goal and role
    rep_min, rep_max = _rep_range(goal_slug, experience_slug, role)
    # prefer a working rep in upper half of range
    working_reps = max(rep_min, (rep_min + rep_max) // 2)

    # number of working sets depending on experience/role/session length
    if experience_slug == "beginner":
        working_sets = 2 if role != "compound" else 3
    elif experience_slug == "intermediate":
        working_sets = 3
    else:
        working_sets = 4 if role == "compound" and session_length >= 45 else 3

    series: list[dict[str, Any]] = []

    # Warmup sets for compounds (percentages of working weight)
    if role == "compound" and working_sets >= 3:
        # warmups expressed as % of target working weight, with higher reps
        series.append({"kg": _round_to_increment(weight * 0.5), "reps": max(8, working_reps + 2)})
        series.append({"kg": _round_to_increment(weight * 0.7), "reps": max(5, working_reps)})
        # small pause before working sets
    # Working sets - slight drop across sets for beginners/intermediate
    for i in range(working_sets):
        # small progressive drop for beginners (to preserve form), slight increase for advanced
        if experience_slug == "beginner":
            set_weight = _round_to_increment(weight * (0.95 - 0.03 * i))
        elif experience_slug == "advanced":
            set_weight = _round_to_increment(weight * (1.0 + 0.02 * i))
        else:
            set_weight = _round_to_increment(weight)
        series.append({"kg": set_weight, "reps": working_reps})

    return series


def _routine_blueprint(days_per_week: int, goal_slug: str) -> list[dict[str, Any]]:
    days = _clamp_int(days_per_week, 3, 6)

    if days == 3:
        return [
            {"name": "Full Body A", "category": "full_body"},
            {"name": "Full Body B", "category": "full_body"},
            {"name": "Low-Impact Conditioning", "category": "conditioning"},
        ]
    if days == 4:
        return [
            {"name": "Upper Body Push", "category": "upper_push"},
            {"name": "Lower Body Strength", "category": "lower_body"},
            {"name": "Upper Body Pull", "category": "upper_pull"},
            {"name": "Core & Conditioning", "category": "conditioning"},
        ]
    if days == 5:
        return [
            {"name": "Upper Body Push", "category": "upper_push"},
            {"name": "Lower Body Strength", "category": "lower_body"},
            {"name": "Upper Body Pull", "category": "upper_pull"},
            {"name": "Full Body Strength", "category": "full_body"},
            {"name": "Low-Impact Conditioning", "category": "conditioning"},
        ]

    return [
        {"name": "Upper Body Push", "category": "upper_push"},
        {"name": "Lower Body Strength", "category": "lower_body"},
        {"name": "Upper Body Pull", "category": "upper_pull"},
        {"name": "Lower Body Accessory", "category": "lower_accessory"},
        {"name": "Full Body Strength", "category": "full_body"},
        {"name": "Core & Conditioning", "category": "conditioning"},
    ]


def _adjust_category_for_injuries(category: str, avoided_areas: set[str]) -> str:
    avoided = avoided_areas
    upper_avoided = any(area in avoided for area in {"shoulder", "chest", "triceps", "biceps", "back", "arms"})
    lower_avoided = any(area in avoided for area in {"legs", "quadriceps", "hamstrings", "calves", "glutes", "hips"})

    if category in {"upper_push", "upper_pull"} and upper_avoided and not lower_avoided:
        return "lower_body"
    if category in {"lower_body", "lower_accessory"} and lower_avoided and not upper_avoided:
        return "upper_push"
    if category == "full_body":
        if upper_avoided and not lower_avoided:
            return "lower_body"
        if lower_avoided and not upper_avoided:
            return "upper_push"
        if upper_avoided and lower_avoided:
            return "conditioning"
    return category


def _category_focus(category: str) -> tuple[list[str], list[str], list[str], list[str]]:
    if category == "upper_push":
        return ["Chest", "Shoulders", "Triceps"], ["dumbbell", "machine", "cable", "bodyweight"], ["compound", "accessory", "core", "accessory"], ["shoulder", "elbow"]
    if category == "upper_pull":
        return ["Back", "Biceps", "Rear Delts"], ["dumbbell", "machine", "cable", "bodyweight"], ["compound", "accessory", "core", "accessory"], ["back", "shoulder"]
    if category == "lower_body":
        return ["Quadriceps", "Hamstrings", "Glutes", "Calves"], ["machine", "dumbbell", "barbell", "bodyweight"], ["compound", "compound", "accessory", "accessory"], ["knee", "hip", "ankle"]
    if category == "lower_accessory":
        return ["Glutes", "Hamstrings", "Calves", "Quadriceps"], ["dumbbell", "machine", "bodyweight"], ["accessory", "accessory", "core", "core"], ["knee", "hip", "ankle"]
    if category == "conditioning":
        return ["Cardio", "Core", "Full Body"], ["bodyweight", "machine", "dumbbell"], ["cardio", "compound", "accessory", "core"], []
    return ["Chest", "Back", "Quadriceps", "Hamstrings", "Glutes", "Core"], ["dumbbell", "machine", "barbell", "cable", "bodyweight"], ["compound", "compound", "accessory", "accessory", "core"], []


def _pick_exercises_for_routine(
    exercises: list[dict[str, Any]],
    category: str,
    goal_slug: str,
    experience_slug: str,
    body_weight: float,
    session_length: int,
    avoided_areas: set[str],
) -> list[dict[str, Any]]:
    desired_areas, preferred_equipment, roles, extra_avoids = _category_focus(category)
    avoided = set(avoided_areas)
    avoided.update(_slugify(area) for area in extra_avoids)

    safe = [
        ex for ex in exercises
        if _exercise_is_safe(ex, avoided, preferred_equipment)
    ]

    selected: list[dict[str, Any]] = []
    used_ids: set[int] = set()

    def choose(role: str, allow_cardio: bool = False) -> dict[str, Any] | None:
        candidates = [
            ex for ex in safe
            if ex.get("exer_id") not in used_ids
            and (allow_cardio or _slugify(str(ex.get("exer_type", ""))) != "cardio")
        ]
        candidates.sort(
            key=lambda ex: _exercise_score(ex, desired_areas, preferred_equipment, goal_slug, role),
            reverse=True,
        )
        return candidates[0] if candidates else None

    for role in roles:
        cardio_role = role == "cardio"
        choice = choose("compound" if role == "compound" else "cardio" if cardio_role else "accessory", allow_cardio=cardio_role)
        if choice is None and role != "cardio":
            choice = choose("accessory")
        if choice is None:
            continue
        used_ids.add(int(choice.get("exer_id", 0) or 0))
        selected.append(choice)

    # Ensure minimum exercise count.
    fallback_pool = [
        ex for ex in safe
        if ex.get("exer_id") not in used_ids
    ]
    fallback_pool.sort(
        key=lambda ex: _exercise_score(ex, desired_areas, preferred_equipment, goal_slug, "accessory"),
        reverse=True,
    )
    while len(selected) < 5 and fallback_pool:
        choice = fallback_pool.pop(0)
        used_ids.add(int(choice.get("exer_id", 0) or 0))
        selected.append(choice)

    return selected[:8]


def _weekday_assignments(days_per_week: int) -> list[str]:
    days = _clamp_int(days_per_week, 3, 6)
    if days == 3:
        return ["monday", "wednesday", "friday"]
    if days == 4:
        return ["monday", "tuesday", "thursday", "saturday"]
    if days == 5:
        return ["monday", "tuesday", "thursday", "friday", "saturday"]
    return ["monday", "tuesday", "wednesday", "friday", "saturday", "sunday"]


async def _load_questionnaire_profile(connection, user_id: int) -> dict[str, Any]:
    questionnaire = await connection.fetchrow(
        """
        SELECT body_age, body_height, body_weight, body_goal, body_gender,
               body_experience, body_location, body_days_per_week,
               body_session_length, body_injuries, body_diet_preference,
               body_allergies
        FROM body_metrics
        WHERE user_id = $1
        """,
        user_id,
    )
    if not questionnaire:
        raise HTTPException(status_code=404, detail="Questionnaire not found")

    return {
        "age": int(questionnaire["body_age"] or 0),
        "height": float(questionnaire["body_height"] or 0),
        "weight": float(questionnaire["body_weight"] or 0),
        "goal": str(questionnaire["body_goal"] or "general_fitness"),
        "gender": str(questionnaire["body_gender"] or ""),
        "experience": str(questionnaire["body_experience"] or "beginner"),
        "location": str(questionnaire["body_location"] or "Home"),
        "days_per_week": int(questionnaire["body_days_per_week"] or 3),
        "session_length": int(questionnaire["body_session_length"] or 30),
        "injuries": _normalize_list(questionnaire["body_injuries"]),
        "diet_preference": str(questionnaire["body_diet_preference"] or ""),
        "allergies": _normalize_list(questionnaire["body_allergies"]),
    }


async def _generate_weekly_plan_for_user(connection, user_id: int) -> dict[str, Any]:
    profile = await _load_questionnaire_profile(connection, user_id)

    exercise_rows = await connection.fetch(
        """
        SELECT exer_id, exer_name, exer_body_area, exer_type::text AS exer_type,
               COALESCE(exer_equip::text, '') AS exer_equip,
               COALESCE(exer_descrip, '') AS exer_descrip,
               COALESCE(exer_vid, '') AS exer_vid
        FROM exercise
        ORDER BY exer_id
        """
    )
    exercises = [_exercise_row_to_dict(row) for row in exercise_rows]

    goal_slug = _infer_goal_slug(profile["goal"])
    experience_slug = _infer_experience_slug(profile["experience"])
    equipment_keywords = _infer_equipment(profile["location"], [profile["goal"], profile["experience"]])
    avoided_areas = _infer_injury_areas(profile["injuries"])
    days = _clamp_int(profile["days_per_week"], 3, 6)
    session_length = _clamp_int(profile["session_length"], 20, 90)
    routine_specs = _routine_blueprint(days, goal_slug)
    assigned_days = _weekday_assignments(days)

    # Map the assigned days to a stable routine list, adjusting for injuries.
    week_plan: dict[str, list[str]] = {day: [] for day in WEEK_DAYS}
    routines: list[dict[str, Any]] = []

    name_map = {
        "upper_push": "Upper Body Push",
        "upper_pull": "Upper Body Pull",
        "lower_body": "Lower Body Strength",
        "lower_accessory": "Lower Body Accessory",
        "full_body": "Full Body Strength",
        "conditioning": "Low-Impact Conditioning",
    }

    for index, spec in enumerate(routine_specs):
        category = _adjust_category_for_injuries(spec["category"], avoided_areas)
        routine_name = name_map.get(category, spec["name"])

        # If the routine name is duplicated because of injury substitutions,
        # make it unique while preserving the focus.
        if any(r["name"] == routine_name for r in routines):
            routine_name = f"{routine_name} {index + 1}"

        selected = _pick_exercises_for_routine(
            exercises=exercises,
            category=category,
            goal_slug=goal_slug,
            experience_slug=experience_slug,
            body_weight=profile["weight"],
            session_length=session_length,
            avoided_areas=avoided_areas,
        )

        # Assign weights and sets.
        generated_exercises: list[dict[str, Any]] = []
        for exercise in selected:
            ex_type = _slugify(str(exercise.get("exer_type", "strength")))
            is_cardio = ex_type == "cardio"
            role = "cardio" if is_cardio else (
                "compound" if any(word in _slugify(str(exercise.get("exer_body_area", ""))) for word in ["chest", "back", "quadriceps", "hamstrings", "glutes"]) else "accessory"
            )
            starting_weight = _estimate_starting_weight(exercise, experience_slug, profile["weight"], role)
            sets = _build_set_series(
                weight=starting_weight,
                goal_slug=goal_slug,
                experience_slug=experience_slug,
                role=role,
                is_cardio=is_cardio,
                session_length=session_length,
            )
            generated_exercises.append({
                "exer_id": int(exercise.get("exer_id") or 0),
                "exer_name": exercise.get("exer_name") or "Unknown Exercise",
                "exer_type": "cardio" if is_cardio else "strength",
                "exer_body_area": exercise.get("exer_body_area") or "General",
                "exer_equip": exercise.get("exer_equip") or "Bodyweight",
                "sets": sets,
            })

        estimated_duration = _clamp_int(
            max(20, int(len(generated_exercises) * 8 + (5 if goal_slug in {"fat_loss", "endurance"} else 0))),
            20,
            session_length,
        )

        routines.append({
            "name": routine_name,
            "goal": goal_slug,
            "estimated_duration_minutes": estimated_duration,
            "exercises": generated_exercises,
        })

        if index < len(assigned_days):
            week_plan[assigned_days[index]] = [routine_name]

    generated_plan = {
        "week_plan": week_plan,
        "routines": routines,
        "generated_from": {
            "age": profile["age"],
            "height": profile["height"],
            "weight": profile["weight"],
            "goal": profile["goal"],
            "experience": profile["experience"],
            "location": profile["location"],
            "days_per_week": days,
            "session_length": session_length,
            "injuries": profile["injuries"],
        },
    }

    plan_str = json.dumps(generated_plan)
    await connection.execute(
        """
        INSERT INTO user_weekly_plan (user_id, plan, updated_at)
        VALUES ($1, $2::jsonb, NOW())
        ON CONFLICT (user_id) DO UPDATE
            SET plan = $2::jsonb, updated_at = NOW()
        """,
        user_id,
        plan_str,
    )

    return generated_plan


def _map_body_goal(goal: str) -> str:
    normalized = (goal or "").strip().lower()
    if "lose" in normalized:
        return "Fat Loss"
    if "build" in normalized:
        return "Muscle Gain"
    if "stay" in normalized:
        return "General Fitness"
    if "gain" in normalized:
        return "Muscle Gain"
    return "General Fitness"


@app.post("/api/users/questionnaire")
async def save_questionnaire(
    request: QuestionnaireRequest,
    user_id: int = Depends(get_current_user_id),
):
    """Save user's questionnaire responses (idempotent: creates or updates body_metrics)"""
    print(f"[QUESTIONNAIRE] User {user_id} submitted: age={request.age}, height={request.height}, weight={request.weight}, goal={request.goal}, experience={request.experience}")
    try:
        async with app.state.db_pool.acquire() as connection:
            # Check if questionnaire already exists for this user
            existing = await connection.fetchval(
                "SELECT body_id FROM body_metrics WHERE user_id = $1",
                user_id
            )
            print(f"[QUESTIONNAIRE] Existing body_id for user {user_id}: {existing}")
            
            if existing:
                # Update existing questionnaire (idempotent - just refreshes data)
                print(f"[QUESTIONNAIRE] Updating existing body_metrics for user {user_id}")
                await connection.execute(
                    """
                    UPDATE body_metrics
                    SET body_age = $1, body_height = $2, body_weight = $3,
                        body_goal = $4, body_gender = $5,
                        body_experience = $6, body_location = $7,
                        body_days_per_week = $8, body_session_length = $9,
                        body_injuries = $10, body_diet_preference = $11,
                        body_allergies = $12
                    WHERE user_id = $13
                    """,
                    request.age,
                    request.height,
                    request.weight,
                    _map_body_goal(request.goal),
                    'male',
                    request.experience,
                    request.location,
                    request.days_per_week,
                    request.session_length,
                    request.injuries,
                    request.diet_preference,
                    request.allergies,
                    user_id
                )
                print(f"[QUESTIONNAIRE] Successfully updated body_metrics for user {user_id}")
            else:
                # Create new body metrics entry
                await connection.execute(
                    """
                    INSERT INTO body_metrics 
                    (user_id, body_age, body_height, body_weight, body_goal, body_gender,
                     body_experience, body_location, body_days_per_week, body_session_length,
                     body_injuries, body_diet_preference, body_allergies)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
                    """,
                    user_id,
                    request.age,
                    request.height,
                    request.weight,
                    _map_body_goal(request.goal),
                    'male',
                    request.experience,
                    request.location,
                    request.days_per_week,
                    request.session_length,
                    request.injuries,
                    request.diet_preference,
                    request.allergies
                )
            generated_plan = await _generate_weekly_plan_for_user(connection, user_id)
            print(f"[QUESTIONNAIRE] Successfully inserted new body_metrics for user {user_id}")
            
            # Save fitness profile with weekly gym days goal
            profile_exists = await connection.fetchval(
                "SELECT profile_id FROM user_fitness_profile WHERE user_id = $1",
                user_id
            )
            
            if profile_exists:
                await connection.execute(
                    """
                    UPDATE user_fitness_profile
                    SET days_per_week_goal = $1
                    WHERE user_id = $2
                    """,
                    request.days_per_week,
                    user_id
                )
            else:
                await connection.execute(
                    """
                    INSERT INTO user_fitness_profile (user_id, days_per_week_goal)
                    VALUES ($1, $2)
                    """,
                    user_id,
                    request.days_per_week
                )
            
            # Initialize streak if not exists
            streak_exists = await connection.fetchval(
                "SELECT streak_id FROM user_streak WHERE user_id = $1",
                user_id
            )
            
            if not streak_exists:
                today = date.today()
                await connection.execute(
                    """
                    INSERT INTO user_streak 
                    (user_id, current_streak, longest_streak, week_start_date)
                    VALUES ($1, 0, 0, $2)
                    """,
                    user_id,
                    today
                )
            
            print(f"[QUESTIONNAIRE] All data saved successfully for user {user_id}")
            return {
                "success": True,
                "message": "Questionnaire saved successfully",
                "user_id": user_id,
                "days_per_week_goal": request.days_per_week,
                "generated_plan": generated_plan,
            }
    except Exception as e:
        print(f"[QUESTIONNAIRE] Error saving for user {user_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to save questionnaire: {str(e)}")


@app.get("/api/users/questionnaire")
async def get_questionnaire(
    user_id: int = Depends(get_current_user_id),
):
    """Get user's saved questionnaire responses"""
    try:
        async with app.state.db_pool.acquire() as connection:
            result = await connection.fetchrow(
                """
                SELECT body_age, body_height, body_weight, body_goal, body_gender,
                       body_experience, body_location, body_days_per_week,
                       body_session_length, body_injuries, body_diet_preference,
                       body_allergies
                FROM body_metrics
                WHERE user_id = $1
                """,
                user_id
            )
            
            if not result:
                raise HTTPException(status_code=404, detail="Questionnaire not found")
            
            return {
                "age": result["body_age"],
                "height": result["body_height"],
                "weight": result["body_weight"],
                "goal": result["body_goal"],
                "gender": result["body_gender"],
                "experience": result["body_experience"],
                "location": result["body_location"],
                "days_per_week": result["body_days_per_week"],
                "session_length": result["body_session_length"],
                "injuries": result["body_injuries"] or [],
                "diet_preference": result["body_diet_preference"],
                "allergies": result["body_allergies"] or []
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch questionnaire: {str(e)}")


@app.post("/api/users/workout-plan/generate")
async def generate_workout_plan(
    user_id: int = Depends(get_current_user_id),
):
    """Generate a weekly workout plan from the user's saved questionnaire."""
    try:
        async with app.state.db_pool.acquire() as connection:
            plan = await _generate_weekly_plan_for_user(connection, user_id)
            return {
                "success": True,
                "plan": plan,
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate workout plan: {str(e)}")


@app.get("/api/users/profile")
async def get_user_profile(
    user_id: int = Depends(get_current_user_id),
):
    """Get user profile information"""
    try:
        async with app.state.db_pool.acquire() as connection:
            user = await connection.fetchrow(
                """
                SELECT u.user_id, u.user_email, u.user_name, u.user_surname, bm.body_id
                FROM users u
                LEFT JOIN body_metrics bm ON bm.user_id = u.user_id
                WHERE u.user_id = $1
                """,
                user_id
            )
            
            if not user:
                raise HTTPException(status_code=404, detail="User not found")
            
            return {
                "user_id": user["user_id"],
                "email": user["user_email"],
                "username": user["user_name"],
                "surname": user["user_surname"],
                "body_id": user["body_id"]
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch profile: {str(e)}")


@app.get("/api/charts/options")
async def get_chart_options(
    user_id: int = Depends(get_current_user_id),
):
    """Return chart picker options grouped by cardio and strength exercises."""
    try:
        async with app.state.db_pool.acquire() as connection:
            body_id = await connection.fetchval(
                "SELECT body_id FROM body_metrics WHERE user_id = $1",
                user_id,
            )

            if not body_id:
                raise HTTPException(status_code=404, detail="Body metrics not found")

            rows = await connection.fetch(
                """
                SELECT e.exer_name, e.exer_type, pe.plan_exer_PB
                FROM exercise e
                JOIN plan_exercise pe ON pe.exer_id = e.exer_id
                JOIN training_exercise te ON te.exer_id = e.exer_id
                JOIN training t ON t.train_id = te.train_id
                JOIN training_body tb ON tb.train_id = t.train_id
                WHERE tb.body_id = $1
                  AND t.train_data IS NOT NULL
                                ORDER BY
                                    CASE WHEN e.exer_type = 'cardio' THEN 0 ELSE 1 END,
                                    pe.plan_exer_PB DESC
                """,
                body_id,
            )

            cardio = []
            strength = []

            for row in rows:
                exercise_name = row["exer_name"]
                exercise_type = row["exer_type"]
                if exercise_type == "cardio" and exercise_name not in cardio:
                    cardio.append(exercise_name)
                elif exercise_type == "strength" and exercise_name not in strength:
                    strength.append(exercise_name)

            return [
                {"name": "track callories", "measure": ["total", "just intake", "just cardio"]},
                {"name": "cardio speed", "measure": cardio},
                {"name": "cardio enduance", "measure": cardio},
                {"name": "total weight lifted", "measure": strength},
                {"name": "weight personal bests", "measure": strength},
            ]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch chart options: {str(e)}")


@app.put("/api/users/profile")
async def update_user_profile(
    data: dict,
    user_id: int = Depends(get_current_user_id),
):
    """Update user profile information"""
    try:
        async with app.state.db_pool.acquire() as connection:
            updates = []
            values = []
            param_count = 1
            
            if "username" in data:
                param_count += 1
                updates.append(f"user_name = ${param_count - 1}")
                values.append(data["username"])
            
            if "surname" in data:
                param_count += 1
                updates.append(f"user_surname = ${param_count - 1}")
                values.append(data["surname"])
            
            if not updates:
                return {"message": "No updates provided"}
            
            values.append(user_id)
            update_clause = ", ".join(updates)
            
            await connection.execute(
                f"UPDATE users SET {update_clause} WHERE user_id = ${param_count}",
                *values
            )
            
            return {"success": True, "message": "Profile updated"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update profile: {str(e)}")


# ==================== USER STATS ENDPOINTS ====================

@app.get("/api/user/stats")
async def get_user_stats(user_id: int = Depends(get_current_user_id)):
    """Get user's XP and level stats"""
    try:
        async with app.state.db_pool.acquire() as connection:
            stats = await connection.fetchrow(
                "SELECT xp, level FROM user_stats WHERE user_id = $1",
                user_id
            )
            
            if not stats:
                # Initialize stats if they don't exist
                await connection.execute(
                    "INSERT INTO user_stats (user_id, xp, level) VALUES ($1, 0, 1) ON CONFLICT (user_id) DO NOTHING",
                    user_id
                )
                return {"xp": 0, "level": 1}
            
            return {"xp": stats["xp"], "level": stats["level"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch stats: {str(e)}")


class XPRequest(BaseModel):
    amount: int


@app.post("/api/user/stats/xp")
async def add_user_xp(
    request: XPRequest,
    user_id: int = Depends(get_current_user_id)
):
    """Add XP to user and update level if necessary"""
    try:
        async with app.state.db_pool.acquire() as connection:
            # Get current stats
            stats = await connection.fetchrow(
                "SELECT xp, level FROM user_stats WHERE user_id = $1",
                user_id
            )
            
            if not stats:
                current_xp = 0
                current_level = 1
            else:
                current_xp = stats["xp"]
                current_level = stats["level"]
            
            new_xp = current_xp + request.amount
            
            # Simple level calculation: 100 XP per level
            new_level = (new_xp // 100) + 1
            
            await connection.execute(
                """
                INSERT INTO user_stats (user_id, xp, level, updated_at)
                VALUES ($1, $2, $3, NOW())
                ON CONFLICT (user_id) DO UPDATE
                SET xp = $2, level = $3, updated_at = NOW()
                """,
                user_id, new_xp, new_level
            )
            
            return {
                "success": True,
                "xp": new_xp,
                "level": new_level,
                "leveled_up": new_level > current_level
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add XP: {str(e)}")


# ==================== WORKOUT ENDPOINTS ====================
class WeeklyPlanRequest(BaseModel):
    plan: dict


class SetData(BaseModel):
    reps: int = 0
    kg: float = 0
    time: int = 0
    distance: float = 0


class WorkoutExercise(BaseModel):
    exer_id: int
    exer_name: str
    sets: list[SetData] = []  # Array of individual set data
    notes: str = ""


class WorkoutRequest(BaseModel):
    exercises: list[WorkoutExercise]
    duration_minutes: int = 0
    notes: str = ""


@app.post("/api/workouts")
async def save_workout(
    request: WorkoutRequest,
    user_id: int = Depends(get_current_user_id),
):
    """Save a completed workout for the user - one training row per exercise"""
    try:
        async with app.state.db_pool.acquire() as connection:
            # Keep the existing workout tables in sync for compatibility.
            workout = await connection.fetchrow(
                """
                INSERT INTO user_workout (user_id, created_at, duration_minutes, notes)
                VALUES ($1, NOW(), $2, $3)
                RETURNING workout_id
                """,
                user_id,
                request.duration_minutes,
                request.notes
            )
            workout_id = workout["workout_id"]

            body_id = await connection.fetchval(
                "SELECT body_id FROM body_metrics WHERE user_id = $1",
                user_id,
            )

            # Insert each exercise's individual sets into training table (one row per set)
            for exc in request.exercises:
                # Get exercise type (strength vs cardio)
                exer_type = await connection.fetchval(
                    "SELECT exer_type FROM exercise WHERE exer_id = $1",
                    exc.exer_id
                )

                # Iterate through each set of this exercise
                for set_num, set_data in enumerate(exc.sets, start=1):
                    # Map metrics based on exercise type
                    train_mins = 0
                    train_reps = 0
                    train_effort = 0.0

                    if exer_type == "strength":
                        # Strength: train_reps = reps performed, train_effort = weight in kg
                        train_reps = set_data.reps or 0
                        train_effort = float(set_data.kg or 0.0)
                    elif exer_type == "cardio":
                        # Cardio: train_mins = time in minutes, train_effort = distance in km
                        train_mins = int(set_data.time or 0)
                        train_effort = float(set_data.distance or 0.0)
                    else:
                        # Default: treat as strength
                        train_reps = set_data.reps or 0
                        train_effort = float(set_data.kg or 0.0)

                    # Insert one training row per set
                    training = await connection.fetchrow(
                        """
                        INSERT INTO training (user_id, train_data, train_mins, train_reps, train_effort)
                        VALUES ($1, NOW(), $2, $3, $4)
                        RETURNING train_id
                        """,
                        user_id,
                        train_mins,
                        train_reps,
                        train_effort,
                    )
                    train_id = training["train_id"]

                    # Insert training_exercise link with set number
                    await connection.execute(
                        """
                        INSERT INTO training_exercise (train_id, exer_id, sets, reps, weight, notes)
                        VALUES ($1, $2, $3, $4, $5, $6)
                        """,
                        train_id,
                        exc.exer_id,
                        set_num,  # Set number (1, 2, 3, etc.)
                        set_data.time if exer_type == "cardio" else set_data.reps,
                        set_data.distance if exer_type == "cardio" else set_data.kg,
                        exc.notes,
                    )

                    if body_id is not None:
                        await connection.execute(
                            """
                            INSERT INTO training_body (train_id, body_id)
                            VALUES ($1, $2)
                            """,
                            train_id,
                            body_id,
                        )

                # Also maintain user_workout_exercise for compatibility
                await connection.execute(
                    """
                    INSERT INTO user_workout_exercise 
                    (workout_id, exer_id, sets, reps, weight, notes)
                    VALUES ($1, $2, $3, $4, $5, $6)
                    """,
                    workout_id,
                    exc.exer_id,
                    len(exc.sets),  # Total number of sets for this exercise
                    exc.sets[0].time if exc.sets and exer_type == "cardio" else (exc.sets[0].reps if exc.sets else 0),
                    exc.sets[0].distance if exc.sets and exer_type == "cardio" else (exc.sets[0].kg if exc.sets else 0.0),
                    exc.notes
                )

            # --- begin: populate training tables for analytics ---
            # Get body_id for this user
            body = await connection.fetchrow(
                "SELECT body_id FROM body_metrics WHERE user_id = $1",
                user_id
            )

            if body:
                body_id = body["body_id"]

                # Aggregate reps and compute an effort value
                total_reps = 0
                exercise_effort_sum = 0.0
                valid_exercises = 0

                for exc in request.exercises:
                    sets = exc.sets or 0
                    reps = exc.reps or 0
                    weight = exc.weight or 0.0

                    if sets > 0 and reps > 0:
                        total_reps += sets * reps
                        effort = (weight if weight > 0 else 5.0) * reps * sets
                        exercise_effort_sum += effort
                        valid_exercises += 1

                avg_effort = (exercise_effort_sum / valid_exercises) if valid_exercises > 0 else 0.0

                # Insert into training
                training = await connection.fetchrow(
                    """
                    INSERT INTO training (train_data, train_mins, train_reps, train_effort)
                    VALUES (NOW(), $1, $2, $3)
                    RETURNING train_id
                    """,
                    request.duration_minutes,
                    total_reps,
                    avg_effort
                )
                train_id = training["train_id"]

                # Link exercises
                for exc in request.exercises:
                    await connection.execute(
                        "INSERT INTO training_exercise (train_id, exer_id) VALUES ($1, $2)",
                        train_id,
                        exc.exer_id
                    )

                # Link body
                await connection.execute(
                    "INSERT INTO training_body (train_id, body_id) VALUES ($1, $2)",
                    train_id,
                    body_id
                )
            # --- end ---
            
            # Update streak automatically
            from datetime import date, timedelta
            today = date.today()
            
            streak = await connection.fetchrow(
                """
                SELECT 
                    current_streak,
                    longest_streak,
                    streak_start_date,
                    last_workout_date,
                    workouts_this_week,
                    week_start_date
                FROM user_streak
                WHERE user_id = $1
                """,
                user_id
            )
            
            if streak and streak["last_workout_date"] != today:
                # Only update if not already worked out today
                last_workout = streak["last_workout_date"]
                current_streak = streak["current_streak"]
                longest_streak = streak["longest_streak"]
                week_start = streak["week_start_date"]
                workouts_this_week = streak["workouts_this_week"]
                
                # Check if it's a new week
                if week_start:
                    days_since_week_start = (today - week_start).days
                    if days_since_week_start >= 7:
                        workouts_this_week = 0
                        week_start = today - timedelta(days=today.weekday())
                else:
                    week_start = today - timedelta(days=today.weekday())
                
                workouts_this_week += 1
                
                # Update streak logic
                if last_workout and (today - last_workout).days == 1:
                    current_streak += 1
                elif last_workout and (today - last_workout).days > 1:
                    current_streak = 1
                else:
                    current_streak = 1
                
                if current_streak > longest_streak:
                    longest_streak = current_streak
                
                streak_start_date = streak["streak_start_date"]
                if current_streak == 1:
                    streak_start_date = today
                
                await connection.execute(
                    """
                    UPDATE user_streak
                    SET 
                        current_streak = $1,
                        longest_streak = $2,
                        streak_start_date = $3,
                        last_workout_date = $4,
                        workouts_this_week = $5,
                        week_start_date = $6,
                        updated_at = NOW()
                    WHERE user_id = $7
                    """,
                    current_streak,
                    longest_streak,
                    streak_start_date,
                    today,
                    workouts_this_week,
                    week_start,
                    user_id
                )
            
            return {
                "success": True,
                "workout_id": workout_id,
                "total_sets": sum(len(exc.sets) for exc in request.exercises),
                "exercises_count": len(request.exercises),
                "message": "Workout saved successfully - one training row per set"
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save workout: {str(e)}")


@app.get("/api/workouts")
async def get_workouts(
    limit: int = 50,
    user_id: int = Depends(get_current_user_id),
):
    """Get user's workout history"""
    try:
        async with app.state.db_pool.acquire() as connection:
            workouts = await connection.fetch(
                """
                SELECT workout_id, created_at, duration_minutes, notes
                FROM user_workout
                WHERE user_id = $1
                ORDER BY created_at DESC
                LIMIT $2
                """,
                user_id,
                limit
            )
            
            result = []
            for w in workouts:
                exercises = await connection.fetch(
                    """
                    SELECT uwe.exer_id, e.exer_name, uwe.sets, uwe.reps, uwe.weight, uwe.notes
                    FROM user_workout_exercise uwe
                    JOIN exercise e ON e.exer_id = uwe.exer_id
                    WHERE uwe.workout_id = $1
                    """,
                    w["workout_id"]
                )
                
                result.append({
                    "workout_id": w["workout_id"],
                    "created_at": str(w["created_at"]),
                    "duration_minutes": w["duration_minutes"],
                    "notes": w["notes"],
                    "exercises": [
                        {
                            "exer_id": e["exer_id"],
                            "name": e["exer_name"],
                            "sets": e["sets"],
                            "reps": e["reps"],
                            "weight": e["weight"],
                            "notes": e["notes"]
                        }
                        for e in exercises
                    ]
                })
            
            return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch workouts: {str(e)}")


@app.get("/api/workouts/{workout_id}")
async def get_workout(
    workout_id: int,
    user_id: int = Depends(get_current_user_id),
):
    """Get a specific workout by ID"""
    try:
        async with app.state.db_pool.acquire() as connection:
            workout = await connection.fetchrow(
                """
                SELECT * FROM user_workout
                WHERE workout_id = $1 AND user_id = $2
                """,
                workout_id,
                user_id
            )
            
            if not workout:
                raise HTTPException(status_code=404, detail="Workout not found")
            
            exercises = await connection.fetch(
                """
                SELECT uwe.exer_id, e.exer_name, uwe.sets, uwe.reps, uwe.weight, uwe.notes
                FROM user_workout_exercise uwe
                JOIN exercise e ON e.exer_id = uwe.exer_id
                WHERE uwe.workout_id = $1
                """,
                workout_id
            )
            
            return {
                "workout_id": workout["workout_id"],
                "created_at": str(workout["created_at"]),
                "duration_minutes": workout["duration_minutes"],
                "notes": workout["notes"],
                "exercises": [
                    {
                        "exer_id": e["exer_id"],
                        "name": e["exer_name"],
                        "sets": e["sets"],
                        "reps": e["reps"],
                        "weight": e["weight"],
                        "notes": e["notes"]
                    }
                    for e in exercises
                ]
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch workout: {str(e)}")


@app.delete("/api/workouts/{workout_id}")
async def delete_workout(
    workout_id: int,
    user_id: int = Depends(get_current_user_id),
):
    """Delete a saved workout"""
    try:
        async with app.state.db_pool.acquire() as connection:
            # Check if workout belongs to user
            workout = await connection.fetchval(
                "SELECT workout_id FROM user_workout WHERE workout_id = $1 AND user_id = $2",
                workout_id,
                user_id
            )
            
            if not workout:
                raise HTTPException(status_code=404, detail="Workout not found")
            
            # Delete workout (cascade will delete exercises)
            await connection.execute(
                "DELETE FROM user_workout WHERE workout_id = $1",
                workout_id
            )
            
            return {"success": True, "message": "Workout deleted"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete workout: {str(e)}")


# ==================== STREAK ENDPOINTS ====================

@app.get("/api/streak")
async def get_streak(user_id: int = Depends(get_current_user_id)):
    """Get user's current streak information"""
    try:
        async with app.state.db_pool.acquire() as connection:
            streak = await connection.fetchrow(
                """
                SELECT 
                    current_streak,
                    longest_streak,
                    streak_start_date,
                    last_workout_date,
                    workouts_this_week,
                    week_start_date
                FROM user_streak
                WHERE user_id = $1
                """,
                user_id
            )
            
          
            if not streak:
                from datetime import date as _date
                _today = _date.today()
                await connection.execute(
                    """
                    INSERT INTO user_streak
                    (user_id, current_streak, longest_streak, workouts_this_week, week_start_date)
                    VALUES ($1, 0, 0, 0, $2)
                    ON CONFLICT DO NOTHING
                    """,
                    user_id, _today
                )
                streak = {"current_streak": 0, "longest_streak": 0,
                          "streak_start_date": None, "last_workout_date": None,
                          "workouts_this_week": 0, "week_start_date": str(_today)}

            # Fetch the user's weekly goal
            profile = await connection.fetchval(
                "SELECT days_per_week_goal FROM user_fitness_profile WHERE user_id = $1",
                user_id
            )

            return {
                "current_streak": streak["current_streak"],
                "longest_streak": streak["longest_streak"],
                "streak_start_date": str(streak["streak_start_date"]) if streak["streak_start_date"] else None,
                "last_workout_date": str(streak["last_workout_date"]) if streak["last_workout_date"] else None,
                "workouts_this_week": streak["workouts_this_week"] or 0,
                "week_start_date": str(streak["week_start_date"]) if streak["week_start_date"] else None,
                "weekly_goal": profile or 3,
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch streak: {str(e)}")


@app.post("/api/streak/update")
async def update_streak(user_id: int = Depends(get_current_user_id)):
    """Update streak after a workout is completed"""
    try:
        from datetime import date, timedelta
        
        async with app.state.db_pool.acquire() as connection:
            today = date.today()
            
            # Get current streak data
            streak = await connection.fetchrow(
                """
                SELECT 
                    current_streak,
                    longest_streak,
                    streak_start_date,
                    last_workout_date,
                    workouts_this_week,
                    week_start_date
                FROM user_streak
                WHERE user_id = $1
                """,
                user_id
            )
            
            # Auto-create streak row instead of 404-ing
            if not streak:
                week_start_auto = today - timedelta(days=today.weekday())
                await connection.execute(
                    """
                    INSERT INTO user_streak
                    (user_id, current_streak, longest_streak, workouts_this_week, week_start_date)
                    VALUES ($1, 0, 0, 0, $2)
                    ON CONFLICT DO NOTHING
                    """,
                    user_id, week_start_auto
                )
                streak = await connection.fetchrow(
                    """
                    SELECT current_streak, longest_streak, streak_start_date,
                           last_workout_date, workouts_this_week, week_start_date
                    FROM user_streak WHERE user_id = $1
                    """,
                    user_id
                )
                if not streak:
                    raise HTTPException(status_code=500, detail="Failed to create streak record")
            
            last_workout = streak["last_workout_date"]
            current_streak = streak["current_streak"]
            longest_streak = streak["longest_streak"]
            week_start = streak["week_start_date"]
            workouts_this_week = streak["workouts_this_week"]
            
            # Check if it's a new week (week starts on Sunday/Monday logic)
            # Simple approach: if week_start is not this week, reset weekly counter
            if week_start:
                days_since_week_start = (today - week_start).days
                if days_since_week_start >= 7:
                    # New week, reset counter
                    workouts_this_week = 0
                    week_start = today - timedelta(days=today.weekday())  # Start of this week (Monday)
            else:
                week_start = today - timedelta(days=today.weekday())
            
            # Check if this is a new workout today
            if last_workout == today:
                # Already worked out today, don't update streak
                return {
                    "message": "Already worked out today",
                    "current_streak": current_streak,
                    "workouts_this_week": workouts_this_week
                }
            
            # Update workouts this week
            workouts_this_week += 1
            
            # Update streak logic
            if last_workout and (today - last_workout).days == 1:
                # Consecutive day - extend streak
                current_streak += 1
            elif last_workout and (today - last_workout).days > 1:
                # Streak broken - restart
                current_streak = 1
            else:
                # First workout or coming back after a break
                current_streak = 1
            
            # Update longest streak if current is longer
            if current_streak > longest_streak:
                longest_streak = current_streak
            
            # Update streak if current is 1 (start date of new streak)
            streak_start_date = streak["streak_start_date"]
            if current_streak == 1:
                streak_start_date = today
            
            # Update database
            await connection.execute(
                """
                UPDATE user_streak
                SET 
                    current_streak = $1,
                    longest_streak = $2,
                    streak_start_date = $3,
                    last_workout_date = $4,
                    workouts_this_week = $5,
                    week_start_date = $6,
                    updated_at = NOW()
                WHERE user_id = $7
                """,
                current_streak,
                longest_streak,
                streak_start_date,
                today,
                workouts_this_week,
                week_start,
                user_id
            )
            
            # Get weekly goal to check if user hit goal
            profile = await connection.fetchval(
                "SELECT days_per_week_goal FROM user_fitness_profile WHERE user_id = $1",
                user_id
            )
            weekly_goal = profile or 3
            goal_met = workouts_this_week >= weekly_goal
            
            return {
                "success": True,
                "message": "Streak updated",
                "current_streak": current_streak,
                "longest_streak": longest_streak,
                "workouts_this_week": workouts_this_week,
                "weekly_goal": weekly_goal,
                "goal_met": goal_met,
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update streak: {str(e)}")


# ==================== MEAL PLAN ENDPOINTS ====================
class MealPlanRequest(BaseModel):
    plan_date: date
    plan: dict


@app.get("/api/meals")
async def get_meal_plan(plan_date: date, user_id: int = Depends(get_current_user_id)):
    """Fetch the user's meal plan for a given date (returns empty plan if none)."""
    try:
        async with app.state.db_pool.acquire() as connection:
            row = await connection.fetchrow(
                """
                SELECT plan, created_at, updated_at
                FROM user_meal_plan
                WHERE user_id = $1 AND plan_date = $2
                """,
                user_id,
                plan_date,
            )

            if not row:
                return {"plan_date": str(plan_date), "plan": {}}

            import json
            plan_data = row["plan"]
            if isinstance(plan_data, str):
                plan_data = json.loads(plan_data)
                
            return {"plan_date": str(plan_date), "plan": plan_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch meal plan: {str(e)}")


@app.post("/api/meals")
async def save_meal_plan(request: MealPlanRequest, user_id: int = Depends(get_current_user_id)):
    """Upsert the user's meal plan for a given date."""
    try:
        async with app.state.db_pool.acquire() as connection:
            existing = await connection.fetchval(
                "SELECT user_meal_plan_id FROM user_meal_plan WHERE user_id = $1 AND plan_date = $2",
                user_id,
                request.plan_date,
            )

            import json
            plan_str = json.dumps(request.plan)

            if existing:
                await connection.execute(
                    """
                    UPDATE user_meal_plan
                    SET plan = $1::jsonb, updated_at = NOW()
                    WHERE user_meal_plan_id = $2
                    """,
                    plan_str,
                    existing,
                )
            else:
                await connection.execute(
                    """
                    INSERT INTO user_meal_plan (user_id, plan_date, plan)
                    VALUES ($1, $2, $3::jsonb)
                    """,
                    user_id,
                    request.plan_date,
                    plan_str,
                )

            return {"success": True, "plan_date": str(request.plan_date)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save meal plan: {str(e)}")


# ==================== WEEKLY PLAN ENDPOINTS ====================

@app.get("/api/weekly-plan")
async def get_weekly_plan(user_id: int = Depends(get_current_user_id)):
    """Get the user's weekly workout plan (day -> list of routine names)."""
    try:
        import json
        async with app.state.db_pool.acquire() as connection:
            row = await connection.fetchrow(
                "SELECT plan FROM user_weekly_plan WHERE user_id = $1",
                user_id,
            )
            if not row:
                return {"plan": {}}
            plan_data = row["plan"]
            if isinstance(plan_data, str):
                plan_data = json.loads(plan_data)
            return {"plan": plan_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch weekly plan: {str(e)}")


@app.post("/api/weekly-plan")
async def save_weekly_plan(request: WeeklyPlanRequest, user_id: int = Depends(get_current_user_id)):
    """Upsert the user's weekly workout plan."""
    try:
        import json
        plan_str = json.dumps(request.plan)
        async with app.state.db_pool.acquire() as connection:
            await connection.execute("""
                INSERT INTO user_weekly_plan (user_id, plan, updated_at)
                VALUES ($1, $2::jsonb, NOW())
                ON CONFLICT (user_id) DO UPDATE
                    SET plan = $2::jsonb, updated_at = NOW()
            """, user_id, plan_str)
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save weekly plan: {str(e)}")


def format_exercise(row: asyncpg.Record) -> dict:
    return {
        "id": row["id"],
        "name": row["name"],
        "area": row["area"],
        "type": row["type"],
        "equipment": [row["equipment"]],
        "description": row["description"],
        "video": row["video"],
    }

@app.get("/api/exercises")
async def get_exercises(name: str = None, area: str = None, type: str = None, equipment: str = None):
    filters = []
    values = []

    if name:
        values.append(f"%{name}%")
        filters.append(f"exer_name ILIKE ${len(values)}")
    if area:
        values.append(f"%{area}%")
        filters.append(f"exer_body_area ILIKE ${len(values)}")
    if type:
        values.append(f"%{type}%")
        filters.append(f"exer_type::text ILIKE ${len(values)}")
    if equipment:
        values.append(equipment)
        filters.append(f"exer_equip::text = ${len(values)}")

    where_clause = f"WHERE {' AND '.join(filters)}" if filters else ""
    query = f"""
        SELECT
            exer_id AS id,
            exer_name AS name,
            exer_body_area AS area,
            exer_type::text AS type,
            exer_equip::text AS equipment,
            exer_descrip AS description,
            exer_vid AS video
        FROM exercise
        {where_clause}
        ORDER BY exer_id
    """

    async with app.state.db_pool.acquire() as connection:
        rows = await connection.fetch(query, *values)

    return [format_exercise(row) for row in rows]


@app.get("/api/exercises/search")
async def search_exercises(q: str):
    query = """
        SELECT
            exer_id AS id,
            exer_name AS name,
            exer_body_area AS area,
            exer_type::text AS type,
            exer_equip::text AS equipment,
            exer_descrip AS description,
            exer_vid AS video
        FROM exercise
        WHERE exer_name ILIKE $1 OR COALESCE(exer_descrip, '') ILIKE $1
        ORDER BY exer_id
    """

    async with app.state.db_pool.acquire() as connection:
        rows = await connection.fetch(query, f"%{q}%")

    return [format_exercise(row) for row in rows]

@app.get("/api/exercises/{exercise_id}")
async def get_exercise(exercise_id: int):
    query = """
        SELECT
            exer_id AS id,
            exer_name AS name,
            exer_body_area AS area,
            exer_type::text AS type,
            exer_equip::text AS equipment,
            exer_descrip AS description,
            exer_vid AS video
        FROM exercise
        WHERE exer_id = $1
    """

    async with app.state.db_pool.acquire() as connection:
        row = await connection.fetchrow(query, exercise_id)

    if not row:
        raise HTTPException(status_code=404, detail="Exercise not found")

    return format_exercise(row)


# ==================== CHART DATA ENDPOINTS ====================

@app.get("/chart/weight/{body_id}")
async def get_chart_weight(body_id: int, user_id: int = Depends(get_current_user_id)):
    try:
        async with app.state.db_pool.acquire() as connection:
            row = await connection.fetchrow(
                "SELECT body_weight, body_past_weight FROM body_metrics WHERE body_id = $1",
                body_id
            )
            if not row:
                return []
            return [
                ["current", row["body_weight"]],
                ["past", row["body_past_weight"] or row["body_weight"]]
            ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/chart/body-type/{body_id}")
async def get_chart_body_type(body_id: int, user_id: int = Depends(get_current_user_id)):
    try:
        async with app.state.db_pool.acquire() as connection:
            rows = await connection.fetch("""
                SELECT e.exer_body_area, COUNT(*) AS area_count
                FROM training t
                JOIN training_body tb ON tb.train_id = t.train_id
                JOIN training_exercise te ON te.train_id = t.train_id
                JOIN exercise e ON e.exer_id = te.exer_id
                WHERE tb.body_id = $1
                  AND t.train_data IS NOT NULL
                GROUP BY e.exer_body_area
                ORDER BY area_count DESC
            """, body_id)
            return [[row["exer_body_area"], row["area_count"]] for row in rows]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/chart/cardio-speed/{body_id}/{exercise_name}")
async def get_chart_cardio_speed(body_id: int, exercise_name: str, user_id: int = Depends(get_current_user_id)):
    try:
        async with app.state.db_pool.acquire() as connection:
            rows = await connection.fetch("""
                SELECT t.train_data, t.train_mins, t.train_effort
                FROM training t
                JOIN training_body tb ON tb.train_id = t.train_id
                JOIN training_exercise te ON te.train_id = t.train_id
                JOIN exercise e ON e.exer_id = te.exer_id
                WHERE tb.body_id = $1 AND e.exer_name = $2 AND t.train_mins > 0
                ORDER BY t.train_data ASC
                LIMIT 7
            """, body_id, exercise_name)
            
            return [[row["train_data"].strftime("%Y-%m-%d"), (row["train_effort"] * 1000) / row["train_mins"]] for row in rows]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/chart/cardio-endurance/{body_id}/{exercise_name}")
async def get_chart_cardio_endurance(body_id: int, exercise_name: str, user_id: int = Depends(get_current_user_id)):
    try:
        async with app.state.db_pool.acquire() as connection:
            rows = await connection.fetch("""
                SELECT t.train_data, t.train_effort
                FROM training t
                JOIN training_body tb ON tb.train_id = t.train_id
                JOIN training_exercise te ON te.train_id = t.train_id
                JOIN exercise e ON e.exer_id = te.exer_id
                WHERE tb.body_id = $1 AND e.exer_name = $2
                ORDER BY t.train_data ASC
                LIMIT 7
            """, body_id, exercise_name)
            return [[row["train_data"].strftime("%Y-%m-%d"), row["train_effort"]] for row in rows]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/chart/strength-total/{body_id}/{exercise_name}")
async def get_chart_strength_total(body_id: int, exercise_name: str, user_id: int = Depends(get_current_user_id)):
    try:
        async with app.state.db_pool.acquire() as connection:
            rows = await connection.fetch("""
                SELECT t.train_data, t.train_effort, t.train_reps
                FROM training t
                JOIN training_body tb ON tb.train_id = t.train_id
                JOIN training_exercise te ON te.train_id = t.train_id
                JOIN exercise e ON e.exer_id = te.exer_id
                WHERE tb.body_id = $1 AND e.exer_name = $2
                ORDER BY t.train_data ASC
                LIMIT 7
            """, body_id, exercise_name)
            return [[row["train_data"].strftime("%Y-%m-%d"), row["train_effort"] * (row["train_reps"] or 0)] for row in rows]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/chart/daily-cardio-calories/{body_id}")
async def get_chart_daily_cardio_calories(body_id: int, user_id: int = Depends(get_current_user_id)):
    try:
        async with app.state.db_pool.acquire() as connection:
            rows = await connection.fetch("""
                SELECT t.train_data, t.train_mins, bm.body_weight, e.exer_met
                FROM training t
                JOIN training_body tb ON tb.train_id = t.train_id
                JOIN training_exercise te ON te.train_id = t.train_id
                JOIN exercise e ON e.exer_id = te.exer_id
                JOIN body_metrics bm ON bm.body_id = tb.body_id
                WHERE tb.body_id = $1 AND e.exer_type = 'cardio'
                ORDER BY t.train_data ASC
            """, body_id)
            
            daily_cals = {}
            for row in rows:
                day = row["train_data"].strftime("%Y-%m-%d")
                cals = row["exer_met"] * row["body_weight"] * ((row["train_mins"] or 0) / 60.0)
                daily_cals[day] = daily_cals.get(day, 0) + cals
            
            return [[day, daily_cals[day]] for day in sorted(daily_cals.keys())][-7:]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5001)