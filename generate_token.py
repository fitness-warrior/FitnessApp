import os
import sys
from pathlib import Path
from jose import jwt

# Add backend directory to sys.path
sys.path.append(os.path.abspath('backend'))

from auth import create_access_token

# User 4 token
token = create_access_token(data={"sub": "4"})
print(f"export TOKEN='{token}'")
