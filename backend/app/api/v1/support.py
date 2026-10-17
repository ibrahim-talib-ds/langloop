"""Support ticket endpoints — user submits, admin reads."""
from datetime import datetime
from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlmodel import Session, select

from app.api.deps import get_current_admin, get_current_user
from app.core.database import get_session
from app.models.support_ticket import SupportTicket
from app.models.user import User

router = APIRouter(prefix="/support", tags=["support"])


class TicketCreate(BaseModel):
    subject: str = Field(max_length=120)
    message: str = Field(max_length=2000)
    category: str = Field(default="other")


class TicketOut(BaseModel):
    id: UUID
    user_id: UUID
    user_username: Optional[str] = None
    subject: str
    message: str
    category: str
    admin_reply: Optional[str] = None
    resolved: bool
    created_at: datetime


class TicketReply(BaseModel):
    reply: str = Field(max_length=2000)
    resolved: bool = True


@router.post("/", response_model=TicketOut)
def create_ticket(
    payload: TicketCreate,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    t = SupportTicket(
        user_id=current.id,
        subject=payload.subject.strip(),
        message=payload.message.strip(),
        category=payload.category,
    )
    session.add(t)
    session.commit()
    session.refresh(t)
    return _to_out(t, current.username)


@router.get("/mine", response_model=List[TicketOut])
def my_tickets(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    rows = session.exec(
        select(SupportTicket)
        .where(SupportTicket.user_id == current.id)
        .order_by(SupportTicket.created_at.desc())
    ).all()
    return [_to_out(t, current.username) for t in rows]


@router.get("/admin/list", response_model=List[TicketOut])
def list_tickets(
    admin: User = Depends(get_current_admin),
    session: Session = Depends(get_session),
    only_open: bool = True,
    limit: int = 100,
):
    stmt = select(SupportTicket).order_by(SupportTicket.created_at.desc()).limit(limit)
    if only_open:
        stmt = stmt.where(SupportTicket.resolved == False)  # noqa: E712
    rows = session.exec(stmt).all()
    out = []
    for t in rows:
        u = session.get(User, t.user_id)
        out.append(_to_out(t, u.username if u else None))
    return out


@router.post("/admin/{ticket_id}/reply", response_model=TicketOut)
def admin_reply(
    ticket_id: UUID,
    payload: TicketReply,
    admin: User = Depends(get_current_admin),
    session: Session = Depends(get_session),
):
    t = session.get(SupportTicket, ticket_id)
    if not t:
        raise HTTPException(404, "Ticket not found")
    t.admin_reply = payload.reply.strip()
    t.resolved = payload.resolved
    t.resolved_by = admin.id
    t.updated_at = datetime.utcnow()
    session.add(t)
    session.commit()
    session.refresh(t)
    u = session.get(User, t.user_id)
    return _to_out(t, u.username if u else None)


def _to_out(t: SupportTicket, username: Optional[str]) -> TicketOut:
    return TicketOut(
        id=t.id,
        user_id=t.user_id,
        user_username=username,
        subject=t.subject,
        message=t.message,
        category=t.category,
        admin_reply=t.admin_reply,
        resolved=t.resolved,
        created_at=t.created_at,
    )
