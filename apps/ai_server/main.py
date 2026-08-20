from fastapi import FastAPI
from api.routes import router as ai_router
from core.config import settings
import uvicorn

app = FastAPI(title=settings.PROJECT_NAME, version=settings.VERSION)

app.include_router(ai_router, prefix="/api/v1/ai", tags=["AI Integration"])

@app.get("/")
def read_root():
    return {"message": "Welcome to Personal Learning OS - AI Gateway"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
