import os
from pathlib import Path
from contextlib import asynccontextmanager
from datetime import date
import asyncpg
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from jose import JWTError, jwt

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
    app.state.db_pool = await asyncpg.create_pool(DATABASE_URL, min_size=1, max_size=5)
    # Ensure weekly plan table exists on startup
    async with app.state.db_pool.acquire() as _conn:
        await _conn.execute("""
            CREATE TABLE IF NOT EXISTS user_weekly_plan (
                id SERIAL PRIMARY KEY,
                user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                plan JSONB NOT NULL DEFAULT '{}'::jsonb,
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
            
            # Create a default game character for compatibility
            game_char = await connection.fetchrow(
                """
                INSERT INTO game_char (game_char_level, game_char_colour, game_char_type, 
                                       game_char_hp, game_char_attack, game_char_speed)
                VALUES (1, 'blue', 'a', 100, 10, 5)
                RETURNING game_char_id
                """
            )
            
            # Insert new user
            user = await connection.fetchrow(
                """
                INSERT INTO users (game_char_id, user_name, user_email, user_password)
                VALUES ($1, $2, $3, $4)
                RETURNING user_id, user_email, user_name
                """,
                game_char["game_char_id"],
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


@app.post("/api/users/questionnaire")
async def save_questionnaire(
    request: QuestionnaireRequest,
    user_id: int = Depends(get_current_user_id),
):
    """Save user's questionnaire responses"""
    try:
        async with app.state.db_pool.acquire() as connection:
            # Check if questionnaire already exists for this user
            existing = await connection.fetchval(
                "SELECT body_id FROM body_metrics WHERE user_id = $1",
                user_id
            )
            
            if existing:
                # Update existing questionnaire
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
                    request.goal,
                    'male',  # Default, can be extended later
                    request.experience,
                    request.location,
                    request.days_per_week,
                    request.session_length,
                    request.injuries,
                    request.diet_preference,
                    request.allergies,
                    user_id
                )
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
                    request.goal,
                    'male',  # Default
                    request.experience,
                    request.location,
                    request.days_per_week,
                    request.session_length,
                    request.injuries,
                    request.diet_preference,
                    request.allergies
                )
            
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
            
            return {
                "success": True,
                "message": "Questionnaire saved successfully",
                "user_id": user_id,
                "days_per_week_goal": request.days_per_week
            }
    except Exception as e:
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


@app.get("/api/users/profile")
async def get_user_profile(
    user_id: int = Depends(get_current_user_id),
):
    """Get user profile information"""
    try:
        async with app.state.db_pool.acquire() as connection:
            user = await connection.fetchrow(
                """
                SELECT user_id, user_email, user_name, user_surname
                FROM users
                WHERE user_id = $1
                """,
                user_id
            )
            
            if not user:
                raise HTTPException(status_code=404, detail="User not found")
            
            return {
                "user_id": user["user_id"],
                "email": user["user_email"],
                "username": user["user_name"],
                "surname": user["user_surname"]
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch profile: {str(e)}")


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


# ==================== WORKOUT ENDPOINTS ====================
class WeeklyPlanRequest(BaseModel):
    plan: dict


class WorkoutExercise(BaseModel):
    exer_id: int
    exer_name: str
    sets: int = 0
    reps: int = 0
    weight: float = 0
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
    """Save a completed workout for the user"""
    try:
        async with app.state.db_pool.acquire() as connection:
            # Insert the workout record
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
            
            # Insert each exercise in the workout
            for exc in request.exercises:
                await connection.execute(
                    """
                    INSERT INTO user_workout_exercise 
                    (workout_id, exer_id, sets, reps, weight, notes)
                    VALUES ($1, $2, $3, $4, $5, $6)
                    """,
                    workout_id,
                    exc.exer_id,
                    exc.sets,
                    exc.reps,
                    exc.weight,
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
                "exercises_count": len(request.exercises),
                "message": "Workout saved successfully"
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
                    SELECT exer_id, sets, reps, weight, notes
                    FROM user_workout_exercise
                    WHERE workout_id = $1
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
                SELECT exer_id, sets, reps, weight, notes
                FROM user_workout_exercise
                WHERE workout_id = $1
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
                raise HTTPException(status_code=404, detail="Streak not found")
            
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
                "workouts_this_week": streak["workouts_this_week"],
                "week_start_date": str(streak["week_start_date"]) if streak["week_start_date"] else None,
                "weekly_goal": profile or 3,  # Default to 3 if not set
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
            
            if not streak:
                raise HTTPException(status_code=404, detail="Streak not found")
            
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5001)