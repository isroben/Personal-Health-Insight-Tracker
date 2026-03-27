from fastapi import APIRouter, Depends, Query, HTTPException
from typing import List, Optional, Dict
from datetime import datetime, timedelta
from ...core.auth import get_current_user
from ...core.firebase_config import get_db
from ...models.schemas import WeeklyReport, Insight

router = APIRouter()

@router.get("/insights", response_model=Dict)
async def get_insights(user=Depends(get_current_user)):
    """
    Returns health insights based on the user's recent logs.
    """
    db = get_db()
    uid = user["uid"]
    
    try:
        # Fetch last 30 logs to generate insights
        logs_ref = db.collection("users").document(uid).collection("logs")
        docs = logs_ref.order_by("created_at", direction="DESCENDING").limit(30).stream()
        logs = [doc.to_dict() for doc in docs]
        
        insights = []
        if not logs:
            return {"status": "success", "data": []}

        # 1. Check for high stress correlation
        avg_stress = sum(l.get("stress_level", 5) for l in logs) / len(logs)
        if avg_stress > 7:
            insights.append({
                "id": "stress_alert",
                "title": "High Stress Levels Detected",
                "description": "Your average stress level is elevated. Consider relaxation techniques.",
                "type": "trend",
                "confidence": 0.85,
                "confidence_label": "High",
                "generated_at": datetime.utcnow().isoformat()
            })

        # 2. Check for hydration
        avg_water = sum(l.get("water_intake", 0.0) for l in logs) / len(logs)
        if avg_water < 1.5:
            insights.append({
                "id": "hydration_tip",
                "title": "Increase Water Intake",
                "description": f"You're averaging {avg_water:.1f}L per day. Target 2.0L for better recovery.",
                "type": "recommendation",
                "confidence": 0.9,
                "confidence_label": "Very High",
                "generated_at": datetime.utcnow().isoformat()
            })

        return {"status": "success", "data": insights}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Insights error: {str(e)}")

@router.get("/weekly-report", response_model=Dict)
async def get_weekly_report(
    week_start: Optional[datetime] = None,
    user=Depends(get_current_user)
):
    """
    Returns the aggregated weekly health report.
    """
    db = get_db()
    uid = user["uid"]
    
    now = datetime.utcnow()
    ws = week_start or (now - timedelta(days=7))
    
    try:
        # Fetch logs for the specific week
        logs_ref = db.collection("users").document(uid).collection("logs")
        # Note: In production, use ws.isoformat() for start/end boundaries
        docs = logs_ref.where("created_at", ">=", ws.isoformat()).stream()
        logs = [doc.to_dict() for doc in docs]
        
        if not logs:
            return {"status": "success", "data": {"total_logs": 0}}

        total = len(logs)
        symptoms = [l.get("symptom") for l in logs if l.get("symptom")]
        freq: Dict[str, int] = {}
        for s in symptoms:
            if s:
                freq[s] = freq.get(s, 0) + 1
            
        # Robust averaging helpers
        def get_avg(field: str, default_val: float) -> float:
            vals = [float(l.get(field, default_val)) for l in logs]
            return sum(vals) / len(vals) if vals else default_val

        # Sort symptoms safely
        sorted_keys: List[str] = sorted(freq.keys(), key=lambda x: freq[x], reverse=True)
        top_3: List[str] = sorted_keys[:3]

        report_data = {
            "week_start": ws.isoformat(),
            "total_logs": total,
            "top_symptoms": top_3,
            "symptom_frequencies": freq,
            "avg_sleep_hours": get_avg("sleep_hours", 0.0),
            "avg_water_intake_litres": get_avg("water_intake", 0.0),
            "avg_stress_level": get_avg("stress_level", 5.0),
            "wellness_score": 75.0, # Placeholder for complex logic
        }
        
        return {"status": "success", "data": report_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Report error: {str(e)}")
