from fastapi import FastAPI
from core.database import Base, engine, SessionLocal
from routes import assessment_routes
from sqlalchemy import text
import asyncio
from services.embedding_service import initialize_ai_models, is_initialized

def init_db():
    Base.metadata.create_all(bind=engine)

# Create FastAPI app
app = FastAPI(title="CodeMap API")

# Health check endpoint
@app.get("/health")
async def health_check():
    if is_initialized():
        return {"status": "ready", "message": "Server is running"}
    else:
        return {"status": "starting", "message": "Server is initializing"}

async def warmup_database():
    """Simple database connection warmup"""
    try:
        # Use SessionLocal instead of async_session
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()  # Close the session
        print("Database connection warmed up")
    except Exception as e:
        print(f"Database warmup failed: {e}")

# Run initialization when FastAPI starts
@app.on_event("startup")
async def on_startup():
    # Initialize database
    init_db()
    print("✓ Database initialized")
    
    # Warm up database connection
    await warmup_database()
    
    # Initialize AI models and load job data
    initialize_ai_models()  # This will load everything
    
    print("✓ Server startup complete - Ready for requests!")

# Register routers
app.include_router(assessment_routes.router)