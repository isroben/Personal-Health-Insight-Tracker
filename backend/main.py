import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.endpoints import logs, profile, insights
from app.core.firebase_config import initialize_firebase

# Initialize the FastAPI app
app = FastAPI(
    title="Health Insight Tracker API",
    description="Backend API for the Health Insight Tracker Flutter App",
    version="1.0.0"
)

# CORS Configuration: allow the Flutter app to talk to the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, restrict this to your app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Firebase Admin SDK
initialize_firebase()

# Register API Routers
app.include_router(profile.router, tags=["Profile"], prefix="/api/v1")
app.include_router(logs.router, tags=["Health Logs"], prefix="/api/v1")
app.include_router(insights.router, tags=["Insights"], prefix="/api/v1")

@app.get("/")
async def root():
    """ Health check endpoint """
    return {
        "status": "online", 
        "message": "Health Tracker API is successfully running",
        "documentation": "/docs"
    }

if __name__ == "__main__":
    # Run the server
    # Host 0.0.0.0 allows connections from other devices on the same network
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
