import os
import json
from pathlib import Path
from contextlib import asynccontextmanager
import asyncio
import time
from datetime import date, timedelta
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
        await _conn.execute("""
            CREATE TABLE IF NOT EXISTS user_hidden_charts (
                id SERIAL PRIMARY KEY,
                user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                chart_name TEXT NOT NULL,
                option TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE (user_id, chart_name, option)
            )
        """)
        # FR13 - Create Custom Tasks
        await _conn.execute("""
            CREATE TABLE IF NOT EXISTS user_tasks (
                id SERIAL PRIMARY KEY,
                user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                name TEXT NOT NULL,
                goal TEXT NOT NULL,
                frequency TEXT NOT NULL DEFAULT 'daily',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        await _conn.execute("""
            CREATE TABLE IF NOT EXISTS user_task_completions (
                id SERIAL PRIMARY KEY,
                task_id INT NOT NULL REFERENCES user_tasks(id) ON DELETE CASCADE,
                completed_at DATE NOT NULL DEFAULT CURRENT_DATE,
                UNIQUE (task_id, completed_at)
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

# Task Models
class TaskRequest(BaseModel):
    task_name: str | None
    goal: str | None
    frequency: str = "daily"


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
                {"name": "track calories", "measure": ["total", "just intake", "just cardio"]},
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


@app.get("/api/user/workout-volume")
async def get_workout_volume(user_id: int = Depends(get_current_user_id)):
    """Get total volume per workout session"""
    try:
        async with app.state.db_pool.acquire() as connection:
            rows = await connection.fetch(
                """
                SELECT 
                    t.train_id as id,
                    t.train_data::date::text as date,
                    SUM(te.weight * te.reps * te.sets) as total_kg
                FROM training t
                JOIN training_exercise te ON te.train_id = t.train_id
                WHERE t.user_id = $1
                GROUP BY t.train_id, t.train_data::date
                ORDER BY t.train_data::date ASC
                """,
                user_id
            )
            return [{"id": r["id"], "date": r["date"], "total_kg": float(r["total_kg"] or 0)} for r in rows]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch workout volume: {str(e)}")


@app.get("/api/user/exercises-progress")
async def get_all_exercises_progress(user_id: int = Depends(get_current_user_id)):
    """Get history for ALL exercises the user has performed"""
    try:
        async with app.state.db_pool.acquire() as connection:
            rows = await connection.fetch(
                """
                SELECT 
                    e.exer_name,
                    t.train_data::date::text as date,
                    MAX(te.weight) as max_kg
                FROM training t
                JOIN training_exercise te ON te.train_id = t.train_id
                JOIN exercise e ON e.exer_id = te.exer_id
                WHERE t.user_id = $1
                GROUP BY e.exer_name, t.train_data::date
                HAVING MAX(te.weight) > 0
                ORDER BY e.exer_name, t.train_data::date ASC
                """,
                user_id
            )
            # Group by exercise name
            result = {}
            for r in rows:
                ex_name = r['exer_name']
                if ex_name not in result:
                    result[ex_name] = []
                result[ex_name].append([r['date'], float(r['max_kg'] or 0.0)])
            return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch exercise progress: {str(e)}")


@app.get("/api/user/hidden-charts")
async def get_hidden_charts(user_id: int = Depends(get_current_user_id)):
    """Fetch all charts the user has hidden"""
    try:
        async with app.state.db_pool.acquire() as connection:
            rows = await connection.fetch(
                "SELECT chart_name, option FROM user_hidden_charts WHERE user_id = $1",
                user_id
            )
            return [{"chart_name": r["chart_name"], "option": r["option"]} for r in rows]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch hidden charts: {str(e)}")


class HiddenChartRequest(BaseModel):
    chart_name: str
    option: str


@app.post("/api/user/hidden-charts")
async def hide_chart(request: HiddenChartRequest, user_id: int = Depends(get_current_user_id)):
    """Mark a chart as hidden"""
    try:
        async with app.state.db_pool.acquire() as connection:
            await connection.execute(
                """
                INSERT INTO user_hidden_charts (user_id, chart_name, option)
                VALUES ($1, $2, $3)
                ON CONFLICT (user_id, chart_name, option) DO NOTHING
                """,
                user_id,
                request.chart_name,
                request.option
            )
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to hide chart: {str(e)}")


@app.delete("/api/user/hidden-charts")
async def unhide_chart(chart_name: str, option: str, user_id: int = Depends(get_current_user_id)):
    """Remove a chart from the hidden list"""
    try:
        async with app.state.db_pool.acquire() as connection:
            await connection.execute(
                "DELETE FROM user_hidden_charts WHERE user_id = $1 AND chart_name = $2 AND option = $3",
                user_id,
                chart_name,
                option
            )
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to unhide chart: {str(e)}")

# ==================== TASK ENDPOINTS ====================
@app.post("/api/user/tasks")
async def create_task(request: TaskRequest, user_id: int = Depends(get_current_user_id)):
    """Create a new custom task (FR13)"""
    if not request.task_name or not request.task_name.strip():
        raise HTTPException(status_code=400, detail="Please enter a task name")
    if not request.goal or not request.goal.strip():
        raise HTTPException(status_code=400, detail="Please link task to a goal")
    
    try:
        async with app.state.db_pool.acquire() as conn:
            row = await conn.fetchrow("""
                INSERT INTO user_tasks (user_id, name, goal, frequency)
                VALUES ($1, $2, $3, $4)
                RETURNING id, name, goal, frequency
            """, user_id, request.task_name.strip(), request.goal.strip(), request.frequency)
            return dict(row)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create task: {str(e)}")

@app.put("/api/user/tasks/{task_id}")
async def update_task(task_id: int, request: TaskRequest, user_id: int = Depends(get_current_user_id)):
    """Update an existing task (FR14)"""
    try:
        async with app.state.db_pool.acquire() as conn:
            # Verify ownership
            existing = await conn.fetchval("SELECT id FROM user_tasks WHERE id = $1 AND user_id = $2", task_id, user_id)
            if not existing:
                raise HTTPException(status_code=404, detail="Task not found")
            
            await conn.execute("""
                UPDATE user_tasks
                SET name = $1, goal = $2, frequency = $3
                WHERE id = $4
            """, request.task_name.strip(), request.goal.strip(), request.frequency, task_id)
            return {"status": "success"}
    except HTTPException: raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update task: {str(e)}")

@app.post("/api/user/tasks/{task_id}/complete")
async def complete_task(task_id: int, user_id: int = Depends(get_current_user_id)):
    """Mark task as complete today (FR15)"""
    try:
        async with app.state.db_pool.acquire() as conn:
            # 1. Verify ownership
            task = await conn.fetchrow("SELECT name FROM user_tasks WHERE id = $1 AND user_id = $2", task_id, user_id)
            if not task:
                raise HTTPException(status_code=404, detail="Task not found")
            
            # 2. Prevent double completion
            already_done = await conn.fetchval("SELECT id FROM user_task_completions WHERE task_id = $1 AND completed_at = CURRENT_DATE", task_id)
            if already_done:
                return {"status": "already_completed", "message": "Task already marked complete today"}

            # 3. Record completion
            await conn.execute("INSERT INTO user_task_completions (task_id) VALUES ($1)", task_id)
            
            # 4. Update Daily Streak (FR16)
            streak = await conn.fetchrow("SELECT streak_id, last_workout_date, current_streak FROM user_streak WHERE user_id = $1", user_id)
            today = date.today()
            
            if not streak:
                await conn.execute("""
                    INSERT INTO user_streak (user_id, current_streak, last_workout_date, streak_start_date)
                    VALUES ($1, 1, $2, $2)
                """, user_id, today)
            else:
                last_date = streak['last_workout_date']
                if last_date != today:
                    if last_date == today - timedelta(days=1):
                        # Consecutive day
                        await conn.execute("""
                            UPDATE user_streak 
                            SET current_streak = current_streak + 1, 
                                last_workout_date = $1 
                            WHERE user_id = $2
                        """, today, user_id)
                    else:
                        # Gap in activity - reset streak to 1
                        await conn.execute("""
                            UPDATE user_streak 
                            SET current_streak = 1, 
                                last_workout_date = $1 
                            WHERE user_id = $2
                        """, today, user_id)
            
            return {"status": "success", "message": f"Task '{task['name']}' completed!"}
    except HTTPException: raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to complete task: {str(e)}")

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


# ==================== RECIPE ENDPOINTS ====================
def _recipe_row_to_dict(row: asyncpg.Record) -> dict[str, Any]:
    calories = row["recipe_calories"]
    return {
        "recipe_id": row["recipe_id"],
        "recipe_meal_name": row["recipe_meal_name"],
        "recipe_ingredients": row["recipe_ingredients"] or "",
        "recipe_allergy_info": row["recipe_allergy_info"] or "",
        "recipe_calories": float(calories) if calories is not None else 0.0,
        "recipe_diet_type": row["recipe_diet_type"] or "",
        "recipe_instructions": row["recipe_instructions"] or "",
        "recipe_image_url": row["recipe_image_url"] or "",
    }


@app.get("/api/recipes")
async def list_recipes():
    query = """
        SELECT
            recipe_id,
            recipe_meal_name,
            recipe_ingredients,
            recipe_allergy_info,
            recipe_calories,
            recipe_diet_type,
            recipe_instructions,
            recipe_image_url
        FROM recipe
        ORDER BY recipe_meal_name
    """

    async with app.state.db_pool.acquire() as connection:
        rows = await connection.fetch(query)

    return [_recipe_row_to_dict(row) for row in rows]


@app.get("/api/recipes/{recipe_id}")
async def get_recipe(recipe_id: int):
    query = """
        SELECT
            recipe_id,
            recipe_meal_name,
            recipe_ingredients,
            recipe_allergy_info,
            recipe_calories,
            recipe_diet_type,
            recipe_instructions,
            recipe_image_url
        FROM recipe
        WHERE recipe_id = $1
    """

    async with app.state.db_pool.acquire() as connection:
        row = await connection.fetchrow(query, recipe_id)

    if not row:
        raise HTTPException(status_code=404, detail="Recipe not found")

    return _recipe_row_to_dict(row)


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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5001)