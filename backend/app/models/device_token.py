"""Device token for push notifications."""
import uuid
from datetime import datetime

from sqlmodel import Field, SQLModel


def utcnow() -> datetime:
    return datetime.utcnow()


class DeviceToken(SQLModel, table=True):
    __tablename__ = "device_tokens"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="users.id", index=True)
    token: str = Field(index=True, unique=True)
    platform: str = Field(default="web")
    created_at: datetime = Field(default_factory=utcnow)
