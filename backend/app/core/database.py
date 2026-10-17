"""
Postgres connection + session dependency for FastAPI.
Uses SQLModel (SQLAlchemy + Pydantic) under the hood.
"""
from typing import Generator

from sqlmodel import Session, SQLModel, create_engine

from app.core.config import settings

# echo=False → quiet logs. Turn True if you want to see every SQL query.
engine = create_engine(
    settings.DATABASE_URL,
    echo=False,
    pool_pre_ping=True,   # auto-recover dead connections
    pool_size=10,
    max_overflow=20,
)


def init_db() -> None:
    """Create tables that don't exist yet. (Later we'll use Alembic instead.)"""
    # Import models here so SQLModel knows about them before create_all
    from app import models  # noqa: F401
    SQLModel.metadata.create_all(engine)


def get_session() -> Generator[Session, None, None]:
    """FastAPI dependency: yields a DB session per request, auto-closes."""
    with Session(engine) as session:
        yield session
