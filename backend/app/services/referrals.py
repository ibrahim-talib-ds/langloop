"""Referral code generation + bonus minutes helpers."""
import secrets

from sqlmodel import Session, select

from app.models.user import User
from app.models.friend import Friend


def generate_code(username: str) -> str:
    """Short, readable code from username + random suffix."""
    base = "".join(c for c in username.upper() if c.isalnum())[:8] or "USER"
    suffix = secrets.token_hex(3).upper()  # 6 chars
    return f"{base}-{suffix}"


def ensure_referral_code(session: Session, user: User) -> str:
    """Return existing code, or create one if missing."""
    if user.referral_code:
        return user.referral_code
    # retry if collision
    for _ in range(5):
        code = generate_code(user.username)
        existing = session.exec(
            select(User).where(User.referral_code == code)
        ).first()
        if not existing:
            user.referral_code = code
            session.add(user)
            session.commit()
            session.refresh(user)
            return code
    raise RuntimeError("Could not generate unique referral code")


BONUS_MINUTES_FOR_INVITE = 30


def apply_referral(
    session: Session,
    new_user: User,
    referral_code: str,
) -> bool:
    """Apply a referral code. Gives bonus minutes to both users."""
    code = referral_code.strip().upper()
    if not code:
        return False

    inviter = session.exec(
        select(User).where(User.referral_code == code)
    ).first()
    if not inviter:
        return False
    if inviter.id == new_user.id:
        return False
    if new_user.referred_by:
        return False  # already used a code

    new_user.referred_by = code
    new_user.bonus_minutes += BONUS_MINUTES_FOR_INVITE
    inviter.bonus_minutes += BONUS_MINUTES_FOR_INVITE

    session.add(new_user)
    session.add(inviter)

    # Auto-friend: both directions (the friend who invited you becomes your friend)
    existing = session.exec(
        select(Friend).where(
            Friend.user_id == inviter.id,
            Friend.friend_id == new_user.id,
        )
    ).first()
    if not existing:
        session.add(Friend(user_id=inviter.id, friend_id=new_user.id))
        session.add(Friend(user_id=new_user.id, friend_id=inviter.id))

    session.commit()
    return True
