import pytest
from auth import create_access_token
from unittest.mock import AsyncMock

@pytest.mark.asyncio
async def test_tc036_create_task_valid(client, mock_conn):
    """FR13: Create valid task"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchrow.return_value = {
        "id": 101, "name": "Morning Run", "goal": "lose_weight", "frequency": "daily"
    }
    
    payload = {"task_name": "Morning Run", "goal": "lose_weight", "frequency": "daily"}
    response = await client.post("/api/user/tasks", json=payload, headers=headers)
    
    assert response.status_code == 200
    assert response.json()["name"] == "Morning Run"

@pytest.mark.asyncio
async def test_tc037_create_task_no_name(client, mock_conn):
    """FR13: Create task with no name"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    payload = {"task_name": None, "goal": "lose_weight"}
    response = await client.post("/api/user/tasks", json=payload, headers=headers)
    
    assert response.status_code == 400
    assert response.json()["detail"] == "Please enter a task name"

@pytest.mark.asyncio
async def test_tc038_create_task_no_goal(client, mock_conn):
    """FR13: Create task with no goal linked"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    payload = {"task_name": "Evening Walk", "goal": None}
    response = await client.post("/api/user/tasks", json=payload, headers=headers)
    
    assert response.status_code == 400
    assert response.json()["detail"] == "Please link task to a goal"

@pytest.mark.asyncio
async def test_tc039_edit_task_name(client, mock_conn):
    """FR14: Edit existing task name"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchval.return_value = 101
    
    payload = {"task_name": "Evening Run", "goal": "lose_weight"}
    response = await client.put("/api/user/tasks/101", json=payload, headers=headers)
    
    assert response.status_code == 200
    assert response.json()["status"] == "success"

@pytest.mark.asyncio
async def test_tc040_edit_task_goal(client, mock_conn):
    """FR14: Edit task goal"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchval.return_value = 101
    
    payload = {"task_name": "Morning Run", "goal": "gain_muscle"}
    response = await client.put("/api/user/tasks/101", json=payload, headers=headers)
    
    assert response.status_code == 200
    assert response.json()["status"] == "success"

@pytest.mark.asyncio
async def test_tc041_complete_task_success(client, mock_conn):
    """FR15: Mark task as complete"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchrow.side_effect = [
        {"name": "Morning Run"}, 
        None # Streak check
    ]
    mock_conn.fetchval.return_value = None # Not completed today
    
    response = await client.post("/api/user/tasks/101/complete", headers=headers)
    
    assert response.status_code == 200
    assert response.json()["status"] == "success"

@pytest.mark.asyncio
async def test_tc042_complete_task_duplicate(client, mock_conn):
    """FR15: Complete same task twice in one day"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchrow.return_value = {"name": "Morning Run"}
    mock_conn.fetchval.return_value = 505 # Already completed
    
    response = await client.post("/api/user/tasks/101/complete", headers=headers)
    
    assert response.status_code == 200
    assert response.json()["status"] == "already_completed"
