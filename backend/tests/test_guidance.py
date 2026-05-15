import pytest
from auth import create_access_token

@pytest.mark.asyncio
async def test_tc037_get_exercise_with_video(client, mock_conn):
    """TC-037: Retrieving an exercise with video guidance"""
    mock_conn.fetchrow.return_value = {
        "id": 1,
        "name": "Bench Press",
        "area": "chest",
        "type": "strength",
        "equipment": "barbell",
        "description": "A classic chest exercise.",
        "video": "https://www.youtube.com/watch?v=gRVjAtPip0Y"
    }

    response = await client.get("/api/exercises/1")
    assert response.status_code == 200
    data = response.json()
    assert data["video"] == "https://www.youtube.com/watch?v=gRVjAtPip0Y"

@pytest.mark.asyncio
async def test_tc038_get_exercise_without_video(client, mock_conn):
    """TC-038: Retrieving an exercise that has no video guidance"""
    mock_conn.fetchrow.return_value = {
        "id": 2,
        "name": "Pushups",
        "area": "chest",
        "type": "strength",
        "equipment": "bodyweight",
        "description": "A bodyweight chest exercise.",
        "video": None
    }

    response = await client.get("/api/exercises/2")
    assert response.status_code == 200
    assert response.json()["video"] is None

@pytest.mark.asyncio
async def test_tc039_search_exercises_by_name(client, mock_conn):
    """TC-039: Searching exercises by valid name"""
    mock_conn.fetch.return_value = [
        {"id": 1, "name": "Bench Press", "area": "chest", "type": "strength", "equipment": "barbell", "description": "", "video": ""}
    ]

    response = await client.get("/api/exercises?name=Bench")
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["name"] == "Bench Press"

@pytest.mark.asyncio
async def test_tc040_search_exercises_no_results(client, mock_conn):
    """TC-040: Searching exercises yields no results"""
    mock_conn.fetch.return_value = []

    response = await client.get("/api/exercises?name=UnknownXYZ")
    assert response.status_code == 200
    assert len(response.json()) == 0

@pytest.mark.asyncio
async def test_tc041_get_exercise_invalid_id(client, mock_conn):
    """TC-041: Retrieving exercise with invalid/non-existent ID"""
    mock_conn.fetchrow.return_value = None

    response = await client.get("/api/exercises/9999")
    assert response.status_code == 404
    assert "not found" in response.json()["detail"].lower()
