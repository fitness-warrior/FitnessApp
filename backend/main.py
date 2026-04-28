import os
from pathlib import Path
from contextlib import asynccontextmanager

import asyncpg
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware


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