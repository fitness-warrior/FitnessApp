import pytest
import flutter_app.python.main as main
from flutter_app.python.auth import create_access_token


@pytest.mark.asyncio
async def test_tc050_save_questionnaire_create_new(client, mock_conn):
    """TC-050: Save a new questionnaire for a user who has no existing data"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}

    # No existing questionnaire, no profile, no streak row
    mock_conn.fetchval.side_effect = [None, None, None]
    main.generated_plan = {"generated": True}

    payload = {
        "age": 28,
        "height": 180.5,
        "weight": 82.0,
        "goal": "Build muscle",
        "experience": "intermediate",
        "location": "gym",
        "days_per_week": 4,
        "session_length": 60,
        "injuries": ["knee"],
        "diet_preference": "high protein",
        "allergies": ["nuts"]
    }

    response = await client.post("/api/users/questionnaire", json=payload, headers=headers)

    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["user_id"] == 1
    assert data["days_per_week_goal"] == 4
    assert data["generated_plan"] == {"generated": True}
    assert mock_conn.fetchval.call_count == 3


@pytest.mark.asyncio
async def test_tc051_save_questionnaire_update_existing(client, mock_conn):
    """TC-051: Save questionnaire when existing questionnaire data is present"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}

    # Existing questionnaire, existing profile, existing streak
    mock_conn.fetchval.side_effect = [1, 1, 1]
    main.generated_plan = {"generated": False}

    payload = {
        "age": 34,
        "height": 172.0,
        "weight": 75.0,
        "goal": "Lose fat",
        "experience": "beginner",
        "location": "home",
        "days_per_week": 3,
        "session_length": 45,
        "injuries": [],
        "diet_preference": "balanced",
        "allergies": []
    }

    response = await client.post("/api/users/questionnaire", json=payload, headers=headers)

    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["days_per_week_goal"] == 3
    assert data["generated_plan"] == {"generated": False}
    assert mock_conn.fetchval.call_count == 3


@pytest.mark.asyncio
async def test_tc052_get_questionnaire_existing(client, mock_conn):
    """TC-052: Retrieve an existing saved questionnaire"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}

    mock_conn.fetchrow.return_value = {
        "body_age": 30,
        "body_height": 175.0,
        "body_weight": 78.5,
        "body_goal": "Muscle Gain",
        "body_gender": "male",
        "body_experience": "intermediate",
        "body_location": "gym",
        "body_days_per_week": 5,
        "body_session_length": 60,
        "body_injuries": None,
        "body_diet_preference": "balanced",
        "body_allergies": None,
    }

    response = await client.get("/api/users/questionnaire", headers=headers)

    assert response.status_code == 200
    data = response.json()
    assert data["age"] == 30
    assert data["goal"] == "Muscle Gain"
    assert data["days_per_week"] == 5
    assert data["injuries"] == []
    assert data["allergies"] == []


@pytest.mark.asyncio
async def test_tc053_get_questionnaire_not_found(client, mock_conn):
    """TC-053: Questionnaire lookup returns 404 when no data exists"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}

    mock_conn.fetchrow.return_value = None

    response = await client.get("/api/users/questionnaire", headers=headers)

    assert response.status_code == 404
    assert response.json()["detail"] == "Questionnaire not found"
