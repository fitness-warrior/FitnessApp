import pytest
from flutter_app.python.auth import create_access_token
from unittest.mock import AsyncMock, MagicMock

# ==================== FR24: STORE FITNESS DATA ====================

@pytest.mark.asyncio
async def test_tc026_log_valid_workout(client, mock_conn):
    """TC-026: Log valid workout with exercises"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchrow.side_effect = [
        {"workout_id": 100}, 
        {"train_id": 1},
        {"current_streak": 1, "longest_streak": 1, "streak_start_date": None, "last_workout_date": None, "workouts_this_week": 0, "week_start_date": None}
    ]
    mock_conn.fetchval.side_effect = [1, "strength"]
    
    response = await client.post(
        "/api/workouts",
        headers=headers,
        json={
            "duration_minutes": 45,
            "notes": "Great session",
            "exercises": [
                {
                    "exer_id": 1,
                    "exer_name": "Bench Press",
                    "notes": "Focus on form",
                    "sets": [
                        {"reps": 10, "kg": 60.5}
                    ]
                }
            ]
        }
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["workout_id"] == 100

@pytest.mark.asyncio
async def test_tc027_log_workout_no_exercises(client, mock_conn):
    """TC-027: Log workout with no exercises"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchrow.side_effect = [
        {"workout_id": 101},
        {"current_streak": 1, "longest_streak": 1, "streak_start_date": None, "last_workout_date": None, "workouts_this_week": 0, "week_start_date": None}
    ]
    
    response = await client.post(
        "/api/workouts",
        headers=headers,
        json={
            "duration_minutes": 10,
            "notes": "Just stretching",
            "exercises": []
        }
    )
    
    assert response.status_code == 200
    assert response.json()["workout_id"] == 101

@pytest.mark.asyncio
async def test_tc028_unauthenticated_workout_save(client):
    """TC-028: Try to save workout without being logged in"""
    response = await client.post(
        "/api/workouts",
        json={"duration_minutes": 30, "exercises": []}
    )
    
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_tc029_retrieve_workout_history(client, mock_conn):
    """TC-029: Retrieve workout history"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetch.side_effect = [
        [{"workout_id": 1, "created_at": "2024-05-14", "duration_minutes": 60, "notes": ""}],
        [{"exer_id": 1, "exer_name": "Bench Press", "sets": 3, "reps": 10, "weight": 60, "notes": ""}]
    ]
    
    response = await client.get("/api/workouts", headers=headers)
    
    assert response.status_code == 200
    assert len(response.json()) > 0

@pytest.mark.asyncio
async def test_tc030_access_another_user_workout(client, mock_conn):
    """TC-030: Access another user's workout"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    # We use side_effect and ensure we return None when called
    mock_conn.fetchrow.side_effect = [None]
    
    response = await client.get("/api/workouts/999", headers=headers)
    
    assert response.status_code == 404
    assert response.json()["detail"] == "Workout not found"

@pytest.mark.asyncio
async def test_tc031_delete_own_workout(client, mock_conn):
    """TC-031: Delete own workout from history"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchval.side_effect = [1]
    
    response = await client.delete("/api/workouts/1", headers=headers)
    
    assert response.status_code == 200
    assert response.json()["message"] == "Workout deleted"
