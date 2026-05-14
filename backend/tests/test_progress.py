import pytest
from auth import create_access_token
from unittest.mock import AsyncMock

# ==================== FR25 & FR26: PROGRESS LINE GRAPH ====================

@pytest.mark.asyncio
async def test_tc032_get_exercise_progress_multiple(client, mock_conn):
    """TC-032: View progress graph after multiple workouts"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    # Mock progression data (3 workouts for exercise ID 1)
    mock_conn.fetch.return_value = [
        {"date": "2024-05-10", "weight": 60.0, "reps": 10, "sets": 3},
        {"date": "2024-05-12", "weight": 62.5, "reps": 10, "sets": 3},
        {"date": "2024-05-14", "weight": 65.0, "reps": 10, "sets": 3}
    ]
    
    response = await client.get("/api/exercises/1/progress", headers=headers)
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 3
    assert data[0]["weight"] == 60.0
    assert data[2]["weight"] == 65.0
    assert data[0]["date"] == "2024-05-10"

@pytest.mark.asyncio
async def test_tc033_get_exercise_progress_single(client, mock_conn):
    """TC-033: View graph with only one data point"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetch.return_value = [
        {"date": "2024-05-14", "weight": 70.0, "reps": 5, "sets": 5}
    ]
    
    response = await client.get("/api/exercises/1/progress", headers=headers)
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["weight"] == 70.0

@pytest.mark.asyncio
async def test_tc034_get_exercise_progress_empty(client, mock_conn):
    """TC-034: View graph with no data"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetch.return_value = []
    
    response = await client.get("/api/exercises/99/progress", headers=headers)
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 0

@pytest.mark.asyncio
async def test_tc035_get_exercise_progress_unauthorized(client):
    """TC-035: Unauthorized access to progress data"""
    response = await client.get("/api/exercises/1/progress")
    
    assert response.status_code == 401
