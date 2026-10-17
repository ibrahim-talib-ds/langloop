"""Friend request - pending acceptance."""
import uuid
from datetime import datetime
from typing import Optional

from sqlmodel import Field, SQLModel


def utcnow() -> datetime:
    return datetime.utcnow()


class FriendRequest(SQLModel, table=True):
    __tablename__ = "friend_requests"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    from_user_id: uuid.UUID = Field(foreign_key="users.id", index=True)
    to_user_id: uuid.UUID = Field(foreign_key="users.id", index=True)

    status: str = Field(default="pending")  # pending | accepted | declined

    created_at: datetime = Field(default_factory=utcnow)
    responded_at: Optional[datetime] = None
