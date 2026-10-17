"""Paddle subscription record."""
import uuid
from datetime import datetime
from typing import Optional

from sqlmodel import Field, SQLModel


def utcnow() -> datetime:
    return datetime.utcnow()


class Subscription(SQLModel, table=True):
    __tablename__ = "subscriptions"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="users.id", index=True, unique=True)

    paddle_subscription_id: str = Field(index=True, unique=True)
    paddle_customer_id: str = Field(default="")
    price_id: str = Field(default="")

    status: str = Field(default="active")
    tier: str = Field(default="plus")

    current_period_end: Optional[datetime] = None
    canceled_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=utcnow)
    updated_at: datetime = Field(default_factory=utcnow)
