import pytest
from unittest.mock import AsyncMock, patch
from auth import create_access_token
from datetime import date, timedelta

@pytest.mark.asyncio
async def test_create_task_valid(client, mock_conn):
    """FR13: Create valid task"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchrow.return_value = {
        "id": 101, "name": "Morning Run", "goal": "lose_weight", "frequency": "daily"
    }
    
    payload = {"name": "Morning Run", "goal": "lose_weight", "frequency": "daily"}
    response = await client.post("/api/user/tasks", json=payload, headers=headers)
    
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Morning Run"
    assert data["goal"] == "lose_weight"

@pytest.mark.asyncio
async def test_create_task_no_name(client, mock_conn):
    """FR13: Create task with no name (rejected)"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    payload = {"name": "", "goal": "lose_weight"}
    response = await client.post("/api/user/tasks", json=payload, headers=headers)
    
    assert response.status_code == 400
    assert response.json()["detail"] == "Please enter a task name"

@pytest.mark.asyncio
async def test_create_task_no_goal(client, mock_conn):
    """FR13: Create task with no goal (rejected)"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    payload = {"name": "Evening Walk", "goal": ""}
    response = await client.post("/api/user/tasks", json=payload, headers=headers)
    
    assert response.status_code == 400
    assert response.json()["detail"] == "Please link task to a goal"

@pytest.mark.asyncio
async def test_edit_task_name(client, mock_conn):
    """FR14: Edit existing task name"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    # Mock ownership check
    mock_conn.fetchval.return_value = 101
    
    payload = {"name": "Evening Run", "goal": "lose_weight"}
    response = await client.put("/api/user/tasks/101", json=payload, headers=headers)
    
    assert response.status_code == 200
    assert response.json()["status"] == "success"
    # Verify SQL called
    mock_conn.execute.assert_called()

@pytest.mark.asyncio
async def test_complete_task_success(client, mock_conn):
    """FR15 & FR16: Mark task as complete and update streak"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    # 1. Mock task ownership
    mock_conn.fetchrow.side_effect = [
        {"name": "Morning Run"}, # Task ownership check
        None # Streak check (simulating first time)
    ]
    # 2. Mock double-completion check (not done yet)
    mock_conn.fetchval.return_value = None
    
    response = await client.post("/api/user/tasks/101/complete", headers=headers)
    
    assert response.status_code == 200
    assert response.json()["status"] == "success"
    # Verify completion recorded
    mock_conn.execute.assert_any_call("INSERT INTO user_task_completions (task_id) VALUES ($1)", 101)

@pytest.mark.asyncio
async def test_complete_task_duplicate(client, mock_conn):
    """FR15: Complete same task twice in one day (prevented)"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchrow.return_value = {"name": "Morning Run"}
    # Mock double-completion check (already done)
    mock_conn.fetchval.return_value = 505 
    
    response = await client.post("/api/user/tasks/101/complete", headers=headers)
    
    assert response.status_code == 200 # App logic returns 200 with status message
    assert response.json()["status"] == "already_completed"

@pytest.mark.asyncio
async def test_complete_task_streak_increment(client, mock_conn):
    """FR16: Completed tasks update streak (consecutive)"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    today = date.today()
    yesterday = today - timedelta(days=1)
    
    # Mock data for streak update
    mock_conn.fetchrow.side_effect = [
        {"name": "Daily Pushups"}, # Task check
        {"streak_id": 1, "last_workout_date": yesterday, "current_streak": 5} # Streak check
    ]
    mock_conn.fetchval.return_value = None # Completion check
    
    response = await client.post("/api/user/tasks/102/complete", headers=headers)
    
    assert response.status_code == 200
    # Verify streak increment SQL was executed
    mock_conn.execute.assert_any_call(
        "\n                            UPDATE user_streak SET current_streak = current_streak + 1, last_workout_date = $1 WHERE user_id = $2\n                        ", 
        today, 1
    )
