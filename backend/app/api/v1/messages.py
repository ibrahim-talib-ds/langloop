"""Simple 1-to-1 messaging."""
from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlmodel import Session, select

from app.api.deps import get_current_user
from app.core.database import get_session
from app.models.message import Message
from app.models.user import User
from app.services.ntfy import notify as ntfy_notify

router = APIRouter(prefix="/messages", tags=["messages"])


class SendMessage(BaseModel):
    body: str = Field(min_length=1, max_length=2000)


class MessageOut(BaseModel):
    id: UUID
    sender_id: UUID
    recipient_id: UUID
    body: str
    read_at: Optional[str] = None
    created_at: str


@router.post("/{other_id}", response_model=MessageOut)
def send_message(
    other_id: UUID,
    payload: SendMessage,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    if other_id == current.id:
        raise HTTPException(400, "Cannot message yourself")
    other = session.get(User, other_id)
    if not other or other.is_banned:
        raise HTTPException(404, "Recipient not found")

    m = Message(
        sender_id=current.id,
        recipient_id=other_id,
        body=payload.body.strip(),
    )
    session.add(m)
    session.commit()
    session.refresh(m)

    # Push notify via ntfy.sh if the recipient has a topic
    try:
        if other.ntfy_topic:
            import asyncio
            asyncio.create_task(
                ntfy_notify(
                    topic=other.ntfy_topic,
                    title=f"New message from {current.username}",
                    body=payload.body[:140],
                    tags=["speech_balloon"],
                )
            )
    except Exception:
        pass

    return _to_out(m)


@router.get("/{other_id}", response_model=List[MessageOut])
def conversation(
    other_id: UUID,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
    limit: int = Query(100, le=500),
    before: Optional[str] = None,
):
    stmt = (
        select(Message)
        .where(
            ((Message.sender_id == current.id) & (Message.recipient_id == other_id))
            | ((Message.sender_id == other_id) & (Message.recipient_id == current.id))
        )
        .order_by(Message.created_at.desc())
        .limit(limit)
    )
    rows = session.exec(stmt).all()
    # Mark received ones as read
    changed = False
    for m in rows:
        if m.recipient_id == current.id and m.read_at is None:
            m.read_at = m.created_at
            session.add(m)
            changed = True
    if changed:
        session.commit()
    return [_to_out(m) for m in reversed(rows)]


@router.get("/", response_model=List[MessageOut])
def inbox(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    stmt = (
        select(Message)
        .where(Message.recipient_id == current.id)
        .order_by(Message.created_at.desc())
        .limit(200)
    )
    return [_to_out(m) for m in session.exec(stmt).all()]


def _to_out(m: Message) -> MessageOut:
    return MessageOut(
        id=m.id,
        sender_id=m.sender_id,
        recipient_id=m.recipient_id,
        body=m.body,
        read_at=m.read_at.isoformat() if m.read_at else None,
        created_at=m.created_at.isoformat(),
    )
