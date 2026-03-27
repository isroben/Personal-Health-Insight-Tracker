import os
import firebase_admin
from firebase_admin import credentials, auth, firestore
from dotenv import load_dotenv

load_dotenv()

def initialize_firebase():
    """
    Initializes the Firebase Admin SDK using a service account JSON file.
    Expects FIREBASE_SERVICE_ACCOUNT_PATH in environment variables.
    """
    cred_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
    
    if not firebase_admin._apps:
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            print(f"Firebase initialized with service account: {cred_path}")
        else:
            # Fallback for local development if service account is not provided
            # Note: This will only work if GOOGLE_APPLICATION_CREDENTIALS is set
            firebase_admin.initialize_app()
            print("Firebase initialized with default credentials")

def get_db():
    return firestore.client()
