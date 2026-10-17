"""User endpoints."""
from datetime import datetime
import base64
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlmodel import Session

from app.api.deps import get_current_user
from app.core.database import get_session
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
    """Save image directly in the database as Base64."""
    if file.content_type not in ["image/jpeg", "image/png", "image/webp", "image/gif"]:
        raise HTTPException(400, "Unsupported file type")

    contents = await file.read()
    if len(contents) > 3 * 1024 * 1024:
        raise HTTPException(400, "Image must be under 3MB")

    # Convert to Base64 string
    b64 = base64.b64encode(contents).decode("utf-8")
    mime = file.content_type
    
    # Save as data URI
    current.avatar_url = f"data:{mime};base64,{b64}"
    
    current.updated_at = datetime.utcnow()
    session.add(current)
    session.commit()
    session.refresh(current)
    return current


@router.delete("/me")
def delete_me(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
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
