"""Message - one row per sent chat message."""
import uuid
from datetime import datetime
from typing import Optional

from sqlmodel import Field, SQLModel


def utcnow() -> datetime:
    return datetime.utcnow()


class Message(SQLModel, table=True):
    __tablename__ = "messages"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    sender_id: uuid.UUID = Field(foreign_key="users.id", index=True)
    recipient_id: uuid.UUID = Field(foreign_key="users.id", index=True)

    body: str
    read_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=utcnow)
