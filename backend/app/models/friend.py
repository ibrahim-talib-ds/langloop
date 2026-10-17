"""Friend - one row per (user, friend) pair, both directions stored."""
import uuid
from datetime import datetime

from sqlmodel import Field, SQLModel


def utcnow() -> datetime:
    return datetime.utcnow()


class Friend(SQLModel, table=True):
    __tablename__ = "friends"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)

    user_id: uuid.UUID = Field(foreign_key="users.id", index=True)
    friend_id: uuid.UUID = Field(foreign_key="users.id", index=True)

    created_at: datetime = Field(default_factory=utcnow)
