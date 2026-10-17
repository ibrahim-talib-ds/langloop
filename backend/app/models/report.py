"""Report - user reports another user for abuse."""
import uuid
from datetime import datetime
from typing import Optional

from sqlmodel import Field, SQLModel


def utcnow() -> datetime:
    return datetime.utcnow()


class Report(SQLModel, table=True):
    __tablename__ = "reports"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    reporter_id: uuid.UUID = Field(foreign_key="users.id", index=True)
    reported_id: uuid.UUID = Field(foreign_key="users.id", index=True)

    reason: str = Field(max_length=64)
    details: Optional[str] = Field(default=None, max_length=1000)
    match_id: Optional[uuid.UUID] = Field(default=None, foreign_key="matches.id")

    resolved: bool = Field(default=False)
    resolved_by: Optional[uuid.UUID] = Field(default=None, foreign_key="users.id")
    resolved_at: Optional[datetime] = None

    created_at: datetime = Field(default_factory=utcnow)
