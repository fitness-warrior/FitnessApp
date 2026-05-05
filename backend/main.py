import os
from pathlib import Path
from contextlib import asynccontextmanager
import asyncpg
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from auth import (
    SignupRequest,
    LoginRequest,
    create_access_token,
    hash_password,
    verify_password,
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