"""User model - the core account table."""
import uuid
from datetime import date, datetime
from typing import Optional

from sqlmodel import Field, SQLModel


def utcnow() -> datetime:
    return datetime.utcnow()


class User(SQLModel, table=True):
    __tablename__ = "users"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)

    email: str = Field(index=True, unique=True)
    username: str = Field(index=True, unique=True)
    hashed_password: str
    google_id: Optional[str] = Field(default=None, index=True, unique=True)
    ntfy_topic: Optional[str] = Field(default=None, index=True, unique=True)

    # ─── Password reset ───
    reset_token: Optional[str] = Field(default=None, index=True)
    reset_token_expires: Optional[datetime] = None

    # ─── Referral ───
    referral_code: Optional[str] = Field(default=None, index=True, unique=True)
    referred_by: Optional[str] = Field(default=None, index=True)
    bonus_minutes: int = Field(default=0)

    full_name: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None
    country: Optional[str] = None

    native_language: str = Field(default="en")
    learning_language: str = Field(default="en")
    level: str = Field(default="beginner")

    is_active: bool = Field(default=True)
    is_admin: bool = Field(default=False)
    is_banned: bool = Field(default=False)
    ban_reason: Optional[str] = None

    subscription_tier: str = Field(default="free")
    daily_minutes_used: int = Field(default=0)
    last_minute_reset: datetime = Field(default_factory=utcnow)

    # ─── Gamification ───
    xp: int = Field(default=0)
    streak_days: int = Field(default=0)
    last_practice_date: Optional[date] = None
    total_matches: int = Field(default=0)

    created_at: datetime = Field(default_factory=utcnow)
    updated_at: datetime = Field(default_factory=utcnow)
