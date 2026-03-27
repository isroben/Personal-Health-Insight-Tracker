from fastapi import APIRouter, Depends, HTTPException
from typing import Dict
from ...core.auth import get_current_user
from ...core.firebase_config import get_db
from ...models.schemas import UserProfile, UserProfileBase

router = APIRouter()

@router.get("/user-profile", response_model=Dict)
async def get_user_profile(user=Depends(get_current_user)):
    """
    Retrieves the user's profile from Firestore.
    """
    db = get_db()
    uid = user["uid"]
    
    try:
        # Query Firestore: users/{uid}
        doc_ref = db.collection("users").document(uid)
        doc = doc_ref.get()
        
        if not doc.exists:
            # First login: create a basic profile based on OAuth info
            new_profile = {
                "uid": uid,
                "display_name": user.get("name") or "New User",
                "email": user.get("email") or "",
                "photo_url": user.get("picture") or None,
                "age": None,
                "height_cm": None,
                "weight_kg": None,
                "primary_condition": None
            }
            doc_ref.set(new_profile)
            return {"status": "success", "data": new_profile}
            
        return {"status": "success", "data": doc.to_dict()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Firestore error: {str(e)}")

@router.post("/user-profile", response_model=Dict)
async def update_user_profile(profile_data: UserProfileBase, user=Depends(get_current_user)):
    """
    Updates the user's profile in Firestore.
    """
    db = get_db()
    uid = user["uid"]
    
    profile_dict = profile_data.dict()
    profile_dict.update({"uid": uid})
    
    try:
        # Merge-write to Firestore: users/{uid}
        db.collection("users").document(uid).set(profile_dict, merge=True)
        return {"status": "success", "data": profile_dict}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Firestore error: {str(e)}")
