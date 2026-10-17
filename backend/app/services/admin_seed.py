"""Seed the admin account from .env on startup."""
from sqlmodel import Session, select

from app.core.config import settings
from app.core.database import engine
from app.core.security import hash_password
from app.models.user import User


def ensure_admin_seed() -> None:
    """Idempotent - safe to run every startup."""
    with Session(engine) as session:
        user = session.exec(
            select(User).where(User.email == settings.ADMIN_EMAIL)
        ).first()

        if user is None:
            user = User(
                email=settings.ADMIN_EMAIL,
                username=settings.ADMIN_USERNAME,
                hashed_password=hash_password(settings.ADMIN_PASSWORD),
                full_name="Administrator",
                is_admin=True,
                is_active=True,
            )
            session.add(user)
            session.commit()
            print(f"✅ Admin seeded: {settings.ADMIN_EMAIL}")
            return

        # Ensure the flag is set even if the user was created earlier
        if not user.is_admin:
            user.is_admin = True
            session.add(user)
            session.commit()
            print(f"✅ Existing user promoted to admin: {user.email}")
