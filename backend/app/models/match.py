"""Match model - one row per paired session."""
import uuid
from datetime import datetime
from typing import Optional

from sqlmodel import Field, SQLModel


def utcnow() -> datetime:
    return datetime.utcnow()


class Match(SQLModel, table=True):
    __tablename__ = "matches"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)

    user_a_id: uuid.UUID = Field(foreign_key="users.id", index=True)
    user_b_id: uuid.UUID = Field(foreign_key="users.id", index=True)

    language: str = Field(default="en", index=True)
    topic: str = Field(default="small_talk")

    # Session lifecycle
    started_at: datetime = Field(default_factory=utcnow)
    ended_at: Optional[datetime] = None
    duration_seconds: Optional[int] = None

    # Flags
    ended_by: Optional[uuid.UUID] = None
    was_reported: bool = Field(default=False)
