import pytest
from flutter_app.python.auth import hash_password

# ==================== FR1: ACCOUNT CREATION TESTS ====================

@pytest.mark.asyncio
async def test_tc001_valid_registration(client, mock_conn):
    """TC-001: Entering valid details should successfully create an account"""
    mock_conn.fetchrow.side_effect = [
        None,  # No existing user
        {"user_id": 1, "user_email": "john@test.com", "user_name": "john"}  # Created user
    ]
    
    response = await client.post(
        "/api/auth/signup",
        json={
            "username": "john",
            "email": "john@test.com",
            "password": "password123"
        }
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["user"]["email"] == "john@test.com"
    assert data["user"]["username"] == "john"

@pytest.mark.asyncio
async def test_tc002_duplicate_email(client, mock_conn):
    """TC-002: System should prevent duplicate accounts"""
    mock_conn.fetchrow.side_effect = [{"user_id": 1}]  # Existing user
    
    response = await client.post(
        "/api/auth/signup",
        json={
            "username": "john",
            "email": "john@test.com",
            "password": "password123"
        }
    )
    
    assert response.status_code == 400
    assert response.json()["detail"] == "Email already registered"

@pytest.mark.asyncio
async def test_tc003_missing_email_field(client):
    """TC-003: Registration rejected for missing email"""
    response = await client.post(
        "/api/auth/signup",
        json={
            "username": "john",
            "password": "password123"
        }
    )
    
    assert response.status_code == 422

@pytest.mark.asyncio
async def test_tc004_missing_password_field(client):
    """TC-004: Registration rejected for missing password"""
    response = await client.post(
        "/api/auth/signup",
        json={
            "username": "john",
            "email": "john@test.com"
        }
    )
    
    assert response.status_code == 422

# ==================== FR2: LOGIN TESTS ====================

@pytest.mark.asyncio
async def test_tc005_valid_login(client, mock_conn):
    """TC-005: Correct credentials should successfully log in"""
    mock_conn.fetchrow.side_effect = [{
        "user_id": 1,
        "user_email": "john@test.com",
        "user_name": "john",
        "user_password": hash_password("password123")
    }]
    
    response = await client.post(
        "/api/auth/login",
        json={
            "email": "john@test.com",
            "password": "password123"
        }
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["user"]["email"] == "john@test.com"

@pytest.mark.asyncio
async def test_tc006_wrong_password(client, mock_conn):
    """TC-006: Incorrect password should be rejected"""
    mock_conn.fetchrow.side_effect = [{
        "user_id": 1,
        "user_email": "john@test.com",
        "user_name": "john",
        "user_password": hash_password("password123")
    }]
    
    response = await client.post(
        "/api/auth/login",
        json={
            "email": "john@test.com",
            "password": "wrongpassword"
        }
    )
    
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid password"

@pytest.mark.asyncio
async def test_tc007_unregistered_email(client, mock_conn):
    """TC-007: Non-existent email should return 'user not found'"""
    mock_conn.fetchrow.side_effect = [None]  # No user found
    
    response = await client.post(
        "/api/auth/login",
        json={
            "email": "notfound@test.com",
            "password": "password123"
        }
    )
    
    assert response.status_code == 404
    assert response.json()["detail"] == "User not found"

@pytest.mark.asyncio
async def test_tc008_empty_credentials(client, mock_conn):
    """TC-008: Empty submission should be rejected"""
    mock_conn.fetchrow.side_effect = [None]
    response = await client.post(
        "/api/auth/login",
        json={
            "email": "",
            "password": ""
        }
    )
    
    assert response.status_code in [401, 404, 422]
