"""Match request/response schemas."""
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class MatchJoinRequest(BaseModel):
    language: str = Field(default="en", min_length=2, max_length=8)
    topic: str = Field(default="small_talk", max_length=32)


class MatchStatusResponse(BaseModel):
    state: str                       # waiting | matched | idle
    queue_size: int = 0
    match_id: Optional[UUID] = None
    partner_id: Optional[UUID] = None
    partner_username: Optional[str] = None
    language: Optional[str] = None
    topic: Optional[str] = None
    started_at: Optional[datetime] = None


class MatchEndResponse(BaseModel):
    match_id: UUID
    duration_seconds: int
    ended_at: datetime
