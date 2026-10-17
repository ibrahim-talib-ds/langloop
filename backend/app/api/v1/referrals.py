"""Referral / invite endpoints."""
from fastapi import APIRouter, Depends
from sqlmodel import Session

from app.api.deps import get_current_user
from app.core.database import get_session
from app.models.user import User
from app.services.referrals import BONUS_MINUTES_FOR_INVITE, ensure_referral_code

router = APIRouter(prefix="/referrals", tags=["referrals"])


@router.get("/me")
def my_referral(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    code = ensure_referral_code(session, current)
    return {
        "code": code,
        "share_url": f"https://langloop.app/join?ref={code}",
        "bonus_minutes": current.bonus_minutes,
        "invite_reward": BONUS_MINUTES_FOR_INVITE,
    }
