from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # App Settings
    PROJECT_NAME: str = "Personal Learning OS - AI Gateway"
    VERSION: str = "1.0.0"

    # API Keys
    OPENAI_API_KEY: Optional[str] = None
    ANTHROPIC_API_KEY: Optional[str] = None
    GEMINI_API_KEY: Optional[str] = None
    GROQ_API_KEY: Optional[str] = None

    # Local AI Settings
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    FAISS_INDEX_PATH: str = "../AI_Cache/faiss_index"

    class Config:
        env_file = ".env"

settings = Settings()
