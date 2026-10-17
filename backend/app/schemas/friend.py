"""Friend schemas."""
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr


class FriendPublic(BaseModel):
    id: UUID
    username: str
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None
    native_language: str
    learning_language: str
    level: str
    xp: int
    friend_since: datetime


class UserStats(BaseModel):
    xp: int
    level: int
    badge: str
    title: str
    next_xp: Optional[int] = None
    progress: int
    streak_days: int
    total_matches: int
    friend_count: int
