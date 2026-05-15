import pytest
from auth import create_access_token

# ==================== STREAKS ====================
@pytest.mark.asyncio
async def test_tc058_get_streak_info(client, mock_conn):
    """TC-058: Get user's current and longest streak"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchrow.return_value = {
        "current_streak": 5,
        "longest_streak": 10,
        "streak_start_date": "2024-05-01",
        "last_workout_date": "2024-05-14",
        "workouts_this_week": 3,
        "week_start_date": "2024-05-13"
    }
    
    response = await client.get("/api/streak", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["current_streak"] == 5
    assert data["longest_streak"] == 10

@pytest.mark.asyncio
async def test_tc059_update_streak(client, mock_conn):
    """TC-059: Update the user's streak after a workout"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    # We mock fetchrow to bypass initial fetch if any, though /update might just return success
    mock_conn.fetchrow.return_value = {
        "current_streak": 6,
        "longest_streak": 10,
        "workouts_this_week": 4
    }
    
    response = await client.post("/api/streak/update", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True

# ==================== XP & STATS ====================
@pytest.mark.asyncio
async def test_tc064_get_user_stats(client, mock_conn):
    """TC-064: Get user's current XP and level"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchrow.return_value = {"xp": 150, "level": 2}
    
    response = await client.get("/api/user/stats", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["xp"] == 150
    assert data["level"] == 2

@pytest.mark.asyncio
async def test_tc065_add_user_xp_no_levelup(client, mock_conn):
    """TC-065: Add XP to user without causing a level up"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchrow.return_value = {"xp": 100, "level": 2}
    
    response = await client.post("/api/user/stats/xp", json={"amount": 50}, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["xp"] == 150
    assert data["level"] == 2
    assert data["leveled_up"] is False

@pytest.mark.asyncio
async def test_tc066_add_user_xp_with_levelup(client, mock_conn):
    """TC-066: Add XP to user causing a level up"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchrow.return_value = {"xp": 90, "level": 1}
    
    response = await client.post("/api/user/stats/xp", json={"amount": 20}, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["xp"] == 110
    assert data["level"] == 2
    assert data["leveled_up"] is True
