from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional

from database.exercise import ExerciseSelection

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


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=5001)
