import pytest
from auth import create_access_token
from unittest.mock import AsyncMock

@pytest.mark.asyncio
async def test_create_task_valid(client, mock_conn):
    """FR13 - Create Custom Tasks: Create valid task"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    # Mock database return for task creation
    mock_conn.fetchrow.return_value = {
        "id": 101, 
        "name": "Morning Run", 
        "goal": "lose_weight", 
        "frequency": "daily"
    }
    
    payload = {
        "name": "Morning Run",
        "goal": "lose_weight",
        "frequency": "daily"
    }
    
    response = await client.post("/api/user/tasks", json=payload, headers=headers)
    
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Morning Run"
    assert data["id"] == 101
