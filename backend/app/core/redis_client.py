"""
Shared Redis client — used for matchmaking queues, rate limits, presence.
"""
import redis

from app.core.config import settings

# decode_responses=True → get str back instead of bytes
redis_client: redis.Redis = redis.from_url(
    settings.REDIS_URL,
    decode_responses=True,
)


def ping_redis() -> bool:
    """Health check helper."""
    try:
        return redis_client.ping()
    except Exception:
        return False
