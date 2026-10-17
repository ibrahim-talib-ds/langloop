"""Rating - one row per (match, rater)."""
import uuid
from datetime import datetime
from typing import Optional

from sqlmodel import Field, SQLModel


def utcnow() -> datetime:
    return datetime.utcnow()


class Rating(SQLModel, table=True):
    __tablename__ = "ratings"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)

    match_id: uuid.UUID = Field(foreign_key="matches.id", index=True)
    rater_id: uuid.UUID = Field(foreign_key="users.id", index=True)
    rated_id: uuid.UUID = Field(foreign_key="users.id", index=True)

    stars: int = Field(ge=1, le=5)
    comment: Optional[str] = None

    created_at: datetime = Field(default_factory=utcnow)
