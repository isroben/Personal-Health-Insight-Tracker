from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional, Dict
from datetime import datetime
import uuid
from ...core.auth import get_current_user
from ...core.firebase_config import get_db
from ...models.schemas import HealthLog, HealthLogCreate

router = APIRouter()

@router.post("/log-symptom", response_model=Dict)
async def log_symptom(log_data: HealthLogCreate, user=Depends(get_current_user)):
    """
    Creates a new health log entry in the user's private subcollection.
    Path: users/{uid}/logs/{log_id}
    """
    db = get_db()
    uid = user["uid"]
    log_id = str(uuid.uuid4())
    created_at = datetime.utcnow()
    
    log_dict = log_data.dict()
    log_dict.update({
        "id": log_id,
        "user_id": uid,
        "created_at": created_at.isoformat()
    })
    
    try:
        # Write to Subcollection: users/{uid}/logs/{log_id}
        user_log_ref = db.collection("users").document(uid).collection("logs").document(log_id)
        user_log_ref.set(log_dict)
        
        return {
            "status": "success",
            "data": {**log_dict, "created_at": created_at}
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Firestore error: {str(e)}")

@router.get("/health-history", response_model=Dict)
async def get_health_history(
    limit: int = Query(50, ge=1, le=500),
    user=Depends(get_current_user)
):
    """
    Retrieves the user's health log history from their private subcollection.
    """
    db = get_db()
    uid = user["uid"]
    
    try:
        # Query Subcollection: users/{uid}/logs
        logs_ref = db.collection("users").document(uid).collection("logs")
        
        # Subcollection queries are fast and don't strictly require a composite index 
        # unless filtering/ordering across DIFFERENT fields. 
        # Ordering by 'created_at' in a single subcollection is usually efficient.
        query = logs_ref.order_by(
            "created_at", direction="DESCENDING"
        ).limit(limit)
        
        docs = query.stream()
        logs = []
        for doc in docs:
            logs.append(doc.to_dict())
        
        return {
            "status": "success",
            "data": logs
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Firestore query error: {str(e)}")
