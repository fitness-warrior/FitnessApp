import pytest
from flutter_app.python.auth import create_access_token
from unittest.mock import AsyncMock

# ==================== FR25 & FR26: PROGRESS LINE GRAPH ====================

@pytest.mark.asyncio
async def test_tc032_get_exercise_progress_multiple(client, mock_conn):
    """TC-032: View progress graph after multiple workouts"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    # Mock progression data (3 workouts for exercise ID 1)
    mock_conn.fetch.return_value = [
        {"exer_name": "Bench Press", "date": "2024-05-10", "max_kg": 60.0},
        {"exer_name": "Bench Press", "date": "2024-05-12", "max_kg": 62.5},
        {"exer_name": "Bench Press", "date": "2024-05-14", "max_kg": 65.0}
    ]

    response = await client.get("/api/user/exercises-progress", headers=headers)

    assert response.status_code == 200
    data = response.json()
    assert "Bench Press" in data
    assert len(data["Bench Press"]) == 3

@pytest.mark.asyncio
async def test_tc033_get_exercise_progress_single(client, mock_conn):
    """TC-033: View graph with only one data point"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}

    mock_conn.fetch.return_value = [
        {"exer_name": "Squat", "date": "2024-05-14", "max_kg": 70.0}
    ]

    response = await client.get("/api/user/exercises-progress", headers=headers)

    assert response.status_code == 200
    data = response.json()
    assert "Squat" in data
    assert len(data["Squat"]) == 1

@pytest.mark.asyncio
async def test_tc034_get_exercise_progress_empty(client, mock_conn):
    """TC-034: View graph with no data"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}

    mock_conn.fetch.return_value = []

    response = await client.get("/api/user/exercises-progress", headers=headers)

    assert response.status_code == 200
    assert response.json() == {}

@pytest.mark.asyncio
async def test_tc035_get_exercise_progress_unauthorized(client):
    """TC-035: Unauthorized access to progress data"""
    response = await client.get("/api/user/exercises-progress")

    assert response.status_code == 401

@pytest.mark.asyncio
async def test_tc036_get_exercise_progress_multiple_exercises(client, mock_conn):
    """TC-036: View graph with multiple different exercises and dates"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}

    mock_conn.fetch.return_value = [
        {"exer_name": "Squat", "date": "2024-05-14", "max_kg": 70.0},
        {"exer_name": "Deadlift", "date": "2024-05-14", "max_kg": 100.0},
        {"exer_name": "Squat", "date": "2024-05-16", "max_kg": 75.0}
    ]

    response = await client.get("/api/user/exercises-progress", headers=headers)

    assert response.status_code == 200
    data = response.json()
    assert "Squat" in data
    assert "Deadlift" in data
    assert len(data["Squat"]) == 2
    assert len(data["Deadlift"]) == 1
