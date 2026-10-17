"""Admin activity feed - matches, messages, reports."""
from datetime import datetime, timedelta
from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlmodel import Session, func, select

from app.api.deps import get_current_admin
from app.core.database import get_session
from app.models.friend import Friend
from app.models.match import Match
from app.models.message import Message
from app.models.rating import Rating
from app.models.user import User

router = APIRouter(prefix="/admin", tags=["admin"])


class MatchOut(BaseModel):
    id: UUID
    user_a_id: UUID
    user_b_id: UUID
    user_a_username: Optional[str] = None
    user_b_username: Optional[str] = None
    language: str
    topic: str
    started_at: datetime
    ended_at: Optional[datetime]
    duration_seconds: Optional[int]


class MessageOut(BaseModel):
    id: UUID
    sender_id: UUID
    sender_username: Optional[str] = None
    recipient_id: UUID
    recipient_username: Optional[str] = None
    body: str
    created_at: datetime


@router.get("/activity/matches", response_model=List[MatchOut])
def recent_matches(
    admin: User = Depends(get_current_admin),
    session: Session = Depends(get_session),
    limit: int = Query(50, le=200),
):
    stmt = select(Match).order_by(Match.started_at.desc()).limit(limit)
    matches = session.exec(stmt).all()
    out: List[MatchOut] = []
    # Cache usernames
    usernames = {}
    for m in matches:
        for uid in (m.user_a_id, m.user_b_id):
            if uid not in usernames:
                u = session.get(User, uid)
                usernames[uid] = u.username if u else None
        out.append(
            MatchOut(
                id=m.id,
                user_a_id=m.user_a_id,
                user_b_id=m.user_b_id,
                user_a_username=usernames.get(m.user_a_id),
                user_b_username=usernames.get(m.user_b_id),
                language=m.language,
                topic=m.topic,
                started_at=m.started_at,
                ended_at=m.ended_at,
                duration_seconds=m.duration_seconds,
            )
        )
    return out


@router.get("/activity/messages", response_model=List[MessageOut])
def recent_messages(
    admin: User = Depends(get_current_admin),
    session: Session = Depends(get_session),
    limit: int = Query(50, le=200),
):
    stmt = (
        select(Message).order_by(Message.created_at.desc()).limit(limit)
    )
    msgs = session.exec(stmt).all()
    out: List[MessageOut] = []
    usernames = {}
    for m in msgs:
        for uid in (m.sender_id, m.recipient_id):
            if uid not in usernames:
                u = session.get(User, uid)
                usernames[uid] = u.username if u else None
        out.append(
            MessageOut(
                id=m.id,
                sender_id=m.sender_id,
                sender_username=usernames.get(m.sender_id),
                recipient_id=m.recipient_id,
                recipient_username=usernames.get(m.recipient_id),
                body=m.body,
                created_at=m.created_at,
            )
        )
    return out


@router.get("/activity/summary")
def activity_summary(
    admin: User = Depends(get_current_admin),
    session: Session = Depends(get_session),
):
    """High-level daily activity — last 14 days."""
    now = datetime.utcnow()
    days = []
    for i in range(13, -1, -1):
        day_start = (now - timedelta(days=i)).replace(
            hour=0, minute=0, second=0, microsecond=0
        )
        day_end = day_start + timedelta(days=1)
        m_count = session.exec(
            select(func.count())
            .select_from(Match)
            .where(Match.started_at >= day_start, Match.started_at < day_end)
        ).one()
        msg_count = session.exec(
            select(func.count())
            .select_from(Message)
            .where(
                Message.created_at >= day_start,
                Message.created_at < day_end,
            )
        ).one()
        user_count = session.exec(
            select(func.count())
            .select_from(User)
            .where(User.created_at >= day_start, User.created_at < day_end)
        ).one()
        days.append(
            {
                "date": day_start.date().isoformat(),
                "matches": m_count,
                "messages": msg_count,
                "new_users": user_count,
            }
        )

    # Top users by XP
    top_users = session.exec(
        select(User).order_by(User.xp.desc()).limit(10)
    ).all()

    return {
        "daily": days,
        "top_users": [
            {
                "id": str(u.id),
                "username": u.username,
                "xp": u.xp,
                "streak_days": u.streak_days,
                "total_matches": u.total_matches,
                "is_admin": u.is_admin,
                "is_banned": u.is_banned,
            }
            for u in top_users
        ],
    }
