import pytest
from fastapi import HTTPException
from auth import create_access_token
import main


@pytest.mark.asyncio
async def test_tc054_get_current_user_id_missing_header():
    """TC-054: Missing Authorization header should return 401"""
    with pytest.raises(HTTPException) as exc_info:
        await main.get_current_user_id(authorization=None)

    assert exc_info.value.status_code == 401
    assert exc_info.value.detail == "Missing authorization header"


@pytest.mark.asyncio
async def test_tc055_get_current_user_id_invalid_jwt():
    """TC-055: Invalid JWT should return 401"""
    with pytest.raises(HTTPException) as exc_info:
        await main.get_current_user_id(authorization="Bearer invalid.token.value")

    assert exc_info.value.status_code == 401
    assert exc_info.value.detail == "Invalid token"


@pytest.mark.asyncio
async def test_tc056_get_current_user_id_valid_token():
    """TC-056: Valid JWT should return the expected user_id"""
    token = create_access_token(data={"sub": "42"})
    authorization = f"Bearer {token}"

    result = await main.get_current_user_id(authorization=authorization)

    assert result == 42


def test_tc057_map_body_goal_variants():
    """TC-057: _map_body_goal should normalize common goals correctly"""
    assert main._map_body_goal("Lose weight") == "Fat Loss"
    assert main._map_body_goal("build strength") == "Muscle Gain"
    assert main._map_body_goal("Gain mass") == "Muscle Gain"
    assert main._map_body_goal("Stay healthy") == "General Fitness"
    assert main._map_body_goal("unknown goal") == "General Fitness"
