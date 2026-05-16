from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
from pydantic import BaseModel
from asyncio import ensure_future

from database.exercise import ExerciseSelection
from database.chart_data import CollectedData
from database.workout_save import WorkoutSave

app = FastAPI(title="FitnessApp API")

# Development CORS — allow emulator and local browsers
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

svc = ExerciseSelection()
workout_svc = WorkoutSave()


class SetData(BaseModel):
    kg: str
    reps: str


class ExerciseEntry(BaseModel):
    exer_id: int = 0
    exer_name: str
    sets: List[SetData] = []


class SaveWorkoutRequest(BaseModel):
    exercises: List[ExerciseEntry]
    work_name: Optional[str] = None


@app.get("/api/exercises")
def list_exercises(
    name: Optional[str] = None,
    area: Optional[str] = None,
    type: Optional[str] = None,
    equipment: Optional[List[str]] = Query(None),
):
    """List exercises. `equipment` may be repeated or provided as CSV by the client."""
    try:
        # If equipment provided as single CSV string, split it
        eq = None
        if equipment:
            eq = []
            for item in equipment:
                if "," in item:
                    eq.extend([e.strip() for e in item.split(",") if e.strip()])
                else:
                    eq.append(item)

        results = svc.exer_filter(name=name, area=area, type=type, equipment=eq)
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/exercises/{exercise_id}")
def get_exercise(exercise_id: int):
    try:
        results = svc.exer_filter()
        for r in results:
            if r.get("id") == exercise_id:
                return r
        raise HTTPException(status_code=404, detail="Exercise not found")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/workouts")
def save_workout(body: SaveWorkoutRequest):
    try:
        exercises = [
            {
                "exer_id": ex.exer_id,
                "exer_name": ex.exer_name,
                "sets": [{"kg": s.kg, "reps": s.reps} for s in ex.sets],
            }
            for ex in body.exercises
        ]
        work_id = workout_svc.save_workout(exercises, work_name=body.work_name)
        return {"work_id": work_id, "message": "Workout saved"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/workouts")
def get_workouts():
    try:
        return workout_svc.get_workouts()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/workouts/{work_id}")
def get_workout_logs(work_id: int):
    try:
        return workout_svc.get_workout_logs(work_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/charts/options")
def get_chart_options(body_id: int):
    try:
        rows = CollectedData(body_id).find_user_done()

        cardio = []
        strength = []
        for exercise_name, exercise_type, _pb in rows:
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
            {"name": "weight", "measure": ["current", "past"]},
            {"name": "body type", "measure": ["body_type"]},
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/chart/weight/{body_id}")
def chart_weight(body_id: int):
    try:
        data = CollectedData(body_id).get_weight()
        if not data:
            return []
        current, past = data
        # Return as list of [label, value]
        return [["current", float(current or 0)], ["past", float(past or 0)]]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/chart/body-type/{body_id}")
def chart_body_type(body_id: int):
    try:
        rows = CollectedData(body_id).find_body_type()
        if not rows:
            return []
        # Convert list of dicts to list of [label, value], take top 4 and pad to 4
        pairs = [[r["body_area"], int(r["count"])] for r in rows]
        # Sort by count desc
        pairs.sort(key=lambda x: x[1], reverse=True)
        # Take up to 4
        pairs = pairs[:4]
        # Pad to 4 with zeros if needed
        while len(pairs) < 4:
            pairs.append(["", 0])
        return pairs
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=5000)
