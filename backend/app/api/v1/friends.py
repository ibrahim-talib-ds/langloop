"""Friend request system — send, list, accept, decline."""
from datetime import datetime
from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlmodel import Session, select

from app.api.deps import get_current_user
from app.core.database import get_session
from app.models.friend import Friend
from app.models.friend_request import FriendRequest
from app.models.user import User
from app.services.ntfy import notify as ntfy_notify

router = APIRouter(prefix="/friends", tags=["friends"])


class RequestOut(BaseModel):
    id: UUID
    from_user_id: UUID
    from_username: Optional[str] = None
    from_full_name: Optional[str] = None
    from_avatar_url: Optional[str] = None
    to_user_id: UUID
    to_username: Optional[str] = None
    status: str
    created_at: datetime


# ─── Send a request ───
@router.post("/request/{other_id}")
async def send_request(
    other_id: UUID,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    if other_id == current.id:
        raise HTTPException(400, "You cannot request yourself")
    other = session.get(User, other_id)
    if not other or other.is_banned:
        raise HTTPException(404, "User not found")

    # Already friends?
    already_friend = session.exec(
        select(Friend).where(
            Friend.user_id == current.id, Friend.friend_id == other_id
        )
    ).first()
    if already_friend:
        return {"status": "already_friends"}

    # Existing pending request from me to them?
    existing = session.exec(
        select(FriendRequest).where(
            FriendRequest.from_user_id == current.id,
            FriendRequest.to_user_id == other_id,
            FriendRequest.status == "pending",
        )
    ).first()
    if existing:
        return {"status": "already_requested", "request_id": str(existing.id)}

    # Existing pending request from THEM to me? → auto-accept
    reverse = session.exec(
        select(FriendRequest).where(
            FriendRequest.from_user_id == other_id,
            FriendRequest.to_user_id == current.id,
            FriendRequest.status == "pending",
        )
    ).first()
    if reverse:
        reverse.status = "accepted"
        reverse.responded_at = datetime.utcnow()
        session.add(reverse)
        session.add(Friend(user_id=current.id, friend_id=other_id))
        session.add(Friend(user_id=other_id, friend_id=current.id))
        session.commit()
        return {"status": "auto_accepted"}

    # Create a new request
    req = FriendRequest(
        from_user_id=current.id,
        to_user_id=other_id,
    )
    session.add(req)
    session.commit()
    session.refresh(req)

    # Notify the recipient
    try:
        if other.ntfy_topic:
            import asyncio
            asyncio.create_task(
                ntfy_notify(
                    topic=other.ntfy_topic,
                    title=f"{current.username} sent you a friend request",
                    body="Open Friends tab to accept.",
                    tags=["busts_in_silhouette"],
                )
            )
    except Exception:
        pass

    return {"status": "requested", "request_id": str(req.id)}


# ─── List incoming requests ───
@router.get("/requests/incoming", response_model=List[RequestOut])
def list_incoming(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    rows = session.exec(
        select(FriendRequest)
        .where(
            FriendRequest.to_user_id == current.id,
            FriendRequest.status == "pending",
        )
        .order_by(FriendRequest.created_at.desc())
    ).all()
    out = []
    for r in rows:
        sender = session.get(User, r.from_user_id)
        out.append(
            RequestOut(
                id=r.id,
                from_user_id=r.from_user_id,
                from_username=sender.username if sender else None,
                from_full_name=sender.full_name if sender else None,
                from_avatar_url=sender.avatar_url if sender else None,
                to_user_id=r.to_user_id,
                to_username=current.username,
                status=r.status,
                created_at=r.created_at,
            )
        )
    return out


# ─── List outgoing requests ───
@router.get("/requests/outgoing", response_model=List[RequestOut])
def list_outgoing(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    rows = session.exec(
        select(FriendRequest)
        .where(
            FriendRequest.from_user_id == current.id,
            FriendRequest.status == "pending",
        )
        .order_by(FriendRequest.created_at.desc())
    ).all()
    out = []
    for r in rows:
        target = session.get(User, r.to_user_id)
        out.append(
            RequestOut(
                id=r.id,
                from_user_id=r.from_user_id,
                from_username=current.username,
                from_full_name=current.full_name,
                from_avatar_url=current.avatar_url,
                to_user_id=r.to_user_id,
                to_username=target.username if target else None,
                status=r.status,
                created_at=r.created_at,
            )
        )
    return out


# ─── Accept ───
@router.post("/requests/{req_id}/accept")
async def accept_request(
    req_id: UUID,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    req = session.get(FriendRequest, req_id)
    if not req:
        raise HTTPException(404, "Request not found")
    if req.to_user_id != current.id:
        raise HTTPException(403, "Not your request to accept")
    if req.status != "pending":
        raise HTTPException(400, f"Request already {req.status}")

    req.status = "accepted"
    req.responded_at = datetime.utcnow()
    session.add(req)

    # Create mutual friendship
    session.add(Friend(user_id=req.from_user_id, friend_id=req.to_user_id))
    session.add(Friend(user_id=req.to_user_id, friend_id=req.from_user_id))
    session.commit()

    # Notify the sender
    try:
        sender = session.get(User, req.from_user_id)
        if sender and sender.ntfy_topic:
            import asyncio
            asyncio.create_task(
                ntfy_notify(
                    topic=sender.ntfy_topic,
                    title=f"{current.username} accepted your friend request",
                    body="You're now friends!",
                    tags=["white_check_mark"],
                )
            )
    except Exception:
        pass

    return {"status": "accepted"}


# ─── Decline ───
@router.post("/requests/{req_id}/decline")
def decline_request(
    req_id: UUID,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    req = session.get(FriendRequest, req_id)
    if not req:
        raise HTTPException(404, "Request not found")
    if req.to_user_id != current.id:
        raise HTTPException(403, "Not your request to decline")
    if req.status != "pending":
        raise HTTPException(400, f"Request already {req.status}")

    req.status = "declined"
    req.responded_at = datetime.utcnow()
    session.add(req)
    session.commit()
    return {"status": "declined"}


# ─── Legacy: direct add (auto-friend) — keep for referral flow ───
@router.post("/add/{other_id}")
def add_friend_direct(
    other_id: UUID,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    if other_id == current.id:
        raise HTTPException(400, "You cannot add yourself")
    other = session.get(User, other_id)
    if not other or other.is_banned:
        raise HTTPException(404, "User not found")

    exists = session.exec(
        select(Friend).where(
            Friend.user_id == current.id, Friend.friend_id == other_id
        )
    ).first()
    if exists:
        return {"added": False, "reason": "already_friends"}

    session.add(Friend(user_id=current.id, friend_id=other_id))
    session.add(Friend(user_id=other_id, friend_id=current.id))
    session.commit()
    return {"added": True}
