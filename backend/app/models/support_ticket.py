"""Support ticket — user writes to admin."""
import uuid
from datetime import datetime
from typing import Optional

from sqlmodel import Field, SQLModel


def utcnow() -> datetime:
    return datetime.utcnow()


class SupportTicket(SQLModel, table=True):
    __tablename__ = "support_tickets"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="users.id", index=True)
    subject: str = Field(max_length=120)
    message: str = Field(max_length=2000)
    category: str = Field(default="other")  # bug | abuse | billing | other

    admin_reply: Optional[str] = Field(default=None, max_length=2000)
    resolved: bool = Field(default=False)
    resolved_by: Optional[uuid.UUID] = Field(default=None, foreign_key="users.id")

    created_at: datetime = Field(default_factory=utcnow)
    updated_at: datetime = Field(default_factory=utcnow)
