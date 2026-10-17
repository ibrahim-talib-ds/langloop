"""Daily minutes tracking + daily reset."""
from datetime import date, datetime

from sqlmodel import Session

from app.models.user import User


FREE_DAILY_MINUTES = 10


def _reset_if_new_day(session: Session, user: User) -> None:
    """Reset daily counter if the day changed."""
    today = datetime.utcnow().date()
    last = user.last_minute_reset.date() if user.last_minute_reset else None
    if last != today:
        user.daily_minutes_used = 0
        user.last_minute_reset = datetime.utcnow()
        session.add(user)
        session.commit()
        session.refresh(user)


def minutes_summary(session: Session, user: User) -> dict:
    """Return the current minute-usage summary for this user."""
    _reset_if_new_day(session, user)

    is_free = user.subscription_tier == "free"
    if is_free:
        limit = FREE_DAILY_MINUTES + user.bonus_minutes
    else:
        limit = None  # unlimited

    used = user.daily_minutes_used
    remaining = None if limit is None else max(0, limit - used)

    return {
        "tier": user.subscription_tier,
        "used_today": used,
        "daily_limit": limit,
        "bonus_minutes": user.bonus_minutes,
        "remaining": remaining,
        "unlimited": limit is None,
        "is_exhausted": (limit is not None) and (used >= limit),
    }


def add_minutes(session: Session, user: User, minutes: int) -> None:
    """Called after each completed match."""
    _reset_if_new_day(session, user)
    user.daily_minutes_used += minutes
    session.add(user)
    session.commit()
