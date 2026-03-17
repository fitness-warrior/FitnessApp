from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Sample exercise data (replace with your database later)
sample_exercises = [
    {
        "id": 1,
        "name": "Push-ups",
        "area": "Chest",
        "type": "Strength",
        "equipment": ["None"],
        "description": "Basic push-up exercise"
    },
    {
        "id": 2,
        "name": "Squats",
        "area": "Legs",
        "type": "Strength", 
        "equipment": ["None"],
        "description": "Basic squat exercise"
    },
    {
        "id": 3,
        "name": "Plank",
        "area": "Core",
        "type": "Strength",
        "equipment": ["None"],
        "description": "Core strengthening exercise"
    }
]

@app.get("/api/exercises")
async def get_exercises(name: str = None, area: str = None, type: str = None, equipment: str = None):
    filtered = sample_exercises
    
    if name:
        filtered = [ex for ex in filtered if name.lower() in ex["name"].lower()]
    if area:
        filtered = [ex for ex in filtered if area.lower() in ex["area"].lower()]
    if type:
        filtered = [ex for ex in filtered if type.lower() in ex["type"].lower()]
    
    return filtered

@app.get("/api/exercises/{exercise_id}")
async def get_exercise(exercise_id: int):
    exercise = next((ex for ex in sample_exercises if ex["id"] == exercise_id), None)
    if exercise:
        return exercise
    return {"error": "Exercise not found"}

@app.get("/api/exercises/search")
async def search_exercises(q: str):
    results = [ex for ex in sample_exercises if q.lower() in ex["name"].lower() or q.lower() in ex["description"].lower()]
    return results

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5001)