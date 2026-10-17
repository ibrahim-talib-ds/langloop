"""User-facing 'me' endpoints — minutes usage, daily state."""
from fastapi import APIRouter, Depends
from sqlmodel import Session

from app.api.deps import get_current_user
from app.core.database import get_session
from app.models.user import User
from app.services.minutes import minutes_summary

router = APIRouter(prefix="/me", tags=["me"])


@router.get("/minutes")
def get_minutes(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    return minutes_summary(session, current)
