from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth
from .firebase_config import initialize_firebase

# Initialize Firebase on module load
initialize_firebase()

security = HTTPBearer()

async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """
    Dependency to verify the Firebase ID token in the Authorization header.
    Expects format: "Bearer <token>"
    """
    token = credentials.credentials
    try:
        # Verify the ID token and return decoding claims
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid or expired Firebase ID token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )

async def get_current_user(token_data: dict = Depends(verify_token)):
    """
    Dependency to get the authenticated user's metadata from the verified token.
    """
    return {
        "uid": token_data.get("uid"),
        "email": token_data.get("email"),
        "name": token_data.get("name")
    }
