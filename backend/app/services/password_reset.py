"""Password reset tokens — generated and emailed via ntfy (or shown to admin)."""
import secrets
from datetime import datetime, timedelta

from sqlmodel import Session, select

from app.models.user import User

RESET_TTL_MINUTES = 30


def create_reset_token(session: Session, user: User) -> str:
    """Generate a short reset code. Returns it (plain)."""
    token = secrets.token_urlsafe(24)[:32]
    user.reset_token = token
    user.reset_token_expires = datetime.utcnow() + timedelta(
        minutes=RESET_TTL_MINUTES
    )
    session.add(user)
    session.commit()
    return token


def verify_reset_token(session: Session, token: str):
    """Return the User if token is valid and not expired, else None."""
    user = session.exec(
        select(User).where(User.reset_token == token)
    ).first()
    if not user:
        return None
    if not user.reset_token_expires:
        return None
    if user.reset_token_expires < datetime.utcnow():
        return None
    return user


def consume_reset_token(session: Session, user: User, new_password_hash: str):
    """Apply new password and clear the token."""
    user.hashed_password = new_password_hash
    user.reset_token = None
    user.reset_token_expires = None
    session.add(user)
    session.commit()
