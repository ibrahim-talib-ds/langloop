"""User endpoints."""
from datetime import datetime

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlmodel import Session

from app.api.deps import get_current_user
from app.core.database import get_session
from app.services.ntfy import generate_topic, notify as ntfy_notify
from app.services.storage import delete_avatar, save_avatar
from app.models.user import User
from app.schemas.user import UserPublic, UserUpdate

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserPublic)
def me(current: User = Depends(get_current_user)):
    return current


@router.patch("/me", response_model=UserPublic)
def update_me(
    payload: UserUpdate,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    data = payload.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(current, k, v)
    current.updated_at = datetime.utcnow()
    session.add(current)
    session.commit()
    session.refresh(current)
    return current


@router.post("/me/avatar", response_model=UserPublic)
async def upload_avatar(
    file: UploadFile = File(...),
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    """Upload a profile picture. Returns updated user with new avatar_url."""
    rel_url = await save_avatar(str(current.id), file)
    current.avatar_url = rel_url
    current.updated_at = datetime.utcnow()
    session.add(current)
    session.commit()
    session.refresh(current)
    return current


@router.delete("/me/avatar", response_model=UserPublic)
def remove_avatar(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    delete_avatar(str(current.id))
    current.avatar_url = None
    session.add(current)
    session.commit()
    session.refresh(current)
    return current


@router.get("/me/ntfy")
def my_ntfy_topic(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    """Return my push topic — creating it on first call."""
    if not current.ntfy_topic:
        current.ntfy_topic = generate_topic()
        session.add(current)
        session.commit()
        session.refresh(current)
    return {
        "topic": current.ntfy_topic,
        "subscribe_url": f"https://ntfy.sh/{current.ntfy_topic}",
    }


@router.post("/me/ntfy/test")
async def test_ntfy(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    if not current.ntfy_topic:
        current.ntfy_topic = generate_topic()
        session.add(current)
        session.commit()
        session.refresh(current)
    ok = await ntfy_notify(
        topic=current.ntfy_topic,
        title="LangLoop test",
        body="If you see this, your notifications work!",
        tags=["white_check_mark"],
    )
    return {"sent": ok, "topic": current.ntfy_topic}


@router.delete("/me")
def delete_me(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    """Soft-delete: mark inactive + anonymize email/username."""
    import uuid as _uuid

    current.is_active = False
    current.email = f"deleted_{current.id}@langloop.local"
    current.username = f"deleted_{str(current.id)[:8]}"
    current.full_name = None
    current.bio = None
    current.avatar_url = None
    current.google_id = None
    session.add(current)
    session.commit()
    return {"ok": True}
