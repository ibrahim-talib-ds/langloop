"""Password reset endpoints."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from sqlmodel import Session, select

from app.core.database import get_session
from app.core.security import hash_password
from app.models.user import User
from app.services import password_reset
from app.services.ntfy import notify as ntfy_notify

router = APIRouter(prefix="/auth", tags=["auth"])


class ForgotRequest(BaseModel):
    email: EmailStr


class ResetRequest(BaseModel):
    token: str
    new_password: str


@router.post("/forgot-password")
async def forgot_password(
    payload: ForgotRequest,
    session: Session = Depends(get_session),
):
    """Request a reset token. Always returns 200 (never reveals emails)."""
    user = session.exec(
        select(User).where(User.email == payload.email)
    ).first()

    if user and user.ntfy_topic:
        token = password_reset.create_reset_token(session, user)
        # Send via ntfy if the user has a topic
        try:
            await ntfy_notify(
                topic=user.ntfy_topic,
                title="LangLoop: Reset your password",
                body=f"Your reset code: {token}\nExpires in 30 minutes.",
                tags=["key"],
            )
        except Exception:
            pass

    return {
        "sent": True,
        "message": "If an account with that email exists, "
                   "a reset code was sent to your notifications.",
    }


@router.post("/reset-password")
def reset_password(
    payload: ResetRequest,
    session: Session = Depends(get_session),
):
    user = password_reset.verify_reset_token(session, payload.token)
    if not user:
        raise HTTPException(
            status_code=400,
            detail="Invalid or expired reset code. Request a new one.",
        )
    if len(payload.new_password) < 6:
        raise HTTPException(
            status_code=400,
            detail="Password must be at least 6 characters.",
        )
    password_reset.consume_reset_token(
        session, user, hash_password(payload.new_password)
    )
    return {"ok": True, "message": "Password updated. You can sign in now."}
