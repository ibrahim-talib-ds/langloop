"""Redis-backed matchmaking."""
import uuid
from typing import Optional

from sqlmodel import Session

from app.core.redis_client import redis_client
from app.models.match import Match

QUEUE_TTL = 60 * 30
MATCH_TTL = 60 * 60


def _queue_key(language: str, topic: str) -> str:
    return f"queue:{language}:{topic}"


def _user_key(user_id: str) -> str:
    return f"user_lang:{user_id}"


def _match_key(user_id: str) -> str:
    return f"user_match:{user_id}"


def join_queue(
    session: Session, user_id: str, language: str, topic: str
) -> Optional[Match]:
    """Returns a Match if paired, else None (still waiting)."""
    key = _queue_key(language, topic)
    redis_client.lrem(key, 0, user_id)

    while True:
        partner = redis_client.rpop(key)
        if partner is None:
            break
        if partner == user_id:
            continue
        # Match found
        m = Match(
            user_a_id=uuid.UUID(partner),
            user_b_id=uuid.UUID(user_id),
            language=language,
            topic=topic,
        )
        session.add(m)
        session.commit()
        session.refresh(m)
        redis_client.setex(_match_key(partner), MATCH_TTL, str(m.id))
        redis_client.setex(_match_key(user_id), MATCH_TTL, str(m.id))
        return m

    redis_client.lpush(key, user_id)
    redis_client.setex(_user_key(user_id), QUEUE_TTL, f"{language}:{topic}")
    return None


def leave_queue(user_id: str) -> bool:
    info = redis_client.get(_user_key(user_id))
    removed = False
    if info:
        language, topic = info.split(":", 1)
        removed = bool(redis_client.lrem(_queue_key(language, topic), 0, user_id))
    redis_client.delete(_user_key(user_id))
    redis_client.delete(_match_key(user_id))
    return removed


def get_match_id(user_id: str) -> Optional[str]:
    return redis_client.get(_match_key(user_id))


def queue_size(language: str, topic: str) -> int:
    return redis_client.llen(_queue_key(language, topic))
