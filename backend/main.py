from fastapi import FastAPI
from core.database import Base, engine
from routes import assessment_routes


def init_db():
    Base.metadata.create_all(bind=engine)


# Create FastAPI app
app = FastAPI(title="CodeMap API")

# Register routers
app.include_router(assessment_routes.router)


# Run init_db() when FastAPI starts
@app.on_event("startup")
def on_startup():
    init_db()
