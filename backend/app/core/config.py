"""
Central configuration — reads from .env via pydantic-settings.
Anywhere in the app: from app.core.config import settings
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # ─── App ───
    APP_NAME: str = "LangLoop"
    ENV: str = "development"
    DEBUG: bool = True

    # ─── Security ───
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 days

    # ─── Admin seed ───
    ADMIN_EMAIL: str
    ADMIN_PASSWORD: str
    ADMIN_USERNAME: str

    # ─── Database ───
    DATABASE_URL: str

    # ─── Redis ───
    REDIS_URL: str

    # ─── Google Sign-In ───
    GOOGLE_CLIENT_ID: str = ""

    # ─── Paddle ───
    PADDLE_API_KEY: str = ""
    PADDLE_CLIENT_TOKEN: str = ""
    PADDLE_WEBHOOK_SECRET: str = ""
    PADDLE_ENV: str = "production"
    PADDLE_PRICE_PLUS: str = ""
    PADDLE_PRICE_PRO: str = ""

    # ─── API ───
    API_V1_PREFIX: str = "/api/v1"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )


settings = Settings()
