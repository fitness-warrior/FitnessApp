"""Authentication utilities and endpoints for FitnessApp"""
import os
from datetime import datetime, timedelta
from pydantic import BaseModel
from passlib.context import CryptContext
from jose import jwt

# ==================== CONFIGURATION ====================
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ==================== PASSWORD FUNCTIONS ====================
def hash_password(password: str) -> str:
    """Hash a password using bcrypt"""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash"""
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict, expires_delta: timedelta | None = None):
    """Create a JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


# ==================== PYDANTIC MODELS ====================
class SignupRequest(BaseModel):
    """Request model for user signup"""
    email: str
    username: str
    password: str


class LoginRequest(BaseModel):
    """Request model for user login"""
    email: str
    password: str


class UserResponse(BaseModel):
    """Response model for user data"""
    user_id: int
    email: str
    username: str
