"""Rating schemas."""
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class RatingCreate(BaseModel):
    stars: int = Field(ge=1, le=5)
    comment: Optional[str] = None


class RatingPublic(BaseModel):
    id: UUID
    match_id: UUID
    rater_id: UUID
    rated_id: UUID
    stars: int
    comment: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class RatingResult(BaseModel):
    rating: RatingPublic
    became_friends: bool
    xp_gained: int
