"""Admin endpoints - full control over users."""
from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Body, Depends, HTTPException, Query
from sqlmodel import Session, func, select

from app.api.deps import get_current_admin
from app.core.database import get_session
from app.models.user import User
from app.schemas.user import UserPublic

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/stats")
def stats(
    admin: User = Depends(get_current_admin),
    session: Session = Depends(get_session),
):
    total = session.exec(select(func.count()).select_from(User)).one()
    banned = session.exec(
        select(func.count()).select_from(User).where(User.is_banned == True)  # noqa: E712
    ).one()
    admins = session.exec(
        select(func.count()).select_from(User).where(User.is_admin == True)  # noqa: E712
    ).one()
    return {
        "total_users": total,
        "banned": banned,
        "admins": admins,
        "active": total - banned,
    }


@router.get("/users", response_model=List[UserPublic])
def list_users(
    admin: User = Depends(get_current_admin),
    session: Session = Depends(get_session),
    q: Optional[str] = Query(None, description="Search email or username"),
    only_banned: bool = False,
    limit: int = Query(50, le=200),
    offset: int = 0,
):
    stmt = select(User)
    if q:
        like = f"%{q}%"
        stmt = stmt.where((User.email.ilike(like)) | (User.username.ilike(like)))
    if only_banned:
        stmt = stmt.where(User.is_banned == True)  # noqa: E712
    stmt = stmt.order_by(User.created_at.desc()).offset(offset).limit(limit)
    return session.exec(stmt).all()


@router.get("/users/{user_id}", response_model=UserPublic)
def get_user(
    user_id: UUID,
    admin: User = Depends(get_current_admin),
    session: Session = Depends(get_session),
):
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(404, "User not found")
    return user


@router.post("/users/{user_id}/ban", response_model=UserPublic)
def ban_user(
    user_id: UUID,
    reason: str = Body(..., embed=True),
    admin: User = Depends(get_current_admin),
    session: Session = Depends(get_session),
):
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(404, "User not found")
    if user.id == admin.id:
        raise HTTPException(400, "You cannot ban yourself")
    if user.is_admin:
        raise HTTPException(400, "Cannot ban another admin")
    user.is_banned = True
    user.ban_reason = reason
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


@router.post("/users/{user_id}/unban", response_model=UserPublic)
def unban_user(
    user_id: UUID,
    admin: User = Depends(get_current_admin),
    session: Session = Depends(get_session),
):
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(404, "User not found")
    user.is_banned = False
    user.ban_reason = None
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


@router.post("/users/{user_id}/promote", response_model=UserPublic)
def promote_user(
    user_id: UUID,
    admin: User = Depends(get_current_admin),
    session: Session = Depends(get_session),
):
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(404, "User not found")
    user.is_admin = True
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


@router.post("/users/{user_id}/demote", response_model=UserPublic)
def demote_user(
    user_id: UUID,
    admin: User = Depends(get_current_admin),
    session: Session = Depends(get_session),
):
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(404, "User not found")
    if user.id == admin.id:
        raise HTTPException(400, "You cannot demote yourself")
    user.is_admin = False
    session.add(user)
    session.commit()
    session.refresh(user)
    return user
