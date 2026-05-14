import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch
from httpx import AsyncClient, ASGITransport
import sys
import os

# Add the backend directory to sys.path so we can import main
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app

@pytest.fixture
def mock_conn():
    return AsyncMock()

@pytest.fixture
def mock_db_pool(mock_conn):
    pool = MagicMock()
    # Mock the async context manager returned by pool.acquire()
    pool.acquire.return_value.__aenter__ = AsyncMock(return_value=mock_conn)
    pool.acquire.return_value.__aexit__ = AsyncMock()
    return pool

@pytest.fixture
async def client(mock_db_pool):
    # Explicitly set app state db_pool to bypass lifespan issues in tests
    app.state.db_pool = mock_db_pool
    
    # We use ASGITransport for FastAPI
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac

@pytest.fixture(scope="session")
def event_loop():
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
    yield loop
    loop.close()
