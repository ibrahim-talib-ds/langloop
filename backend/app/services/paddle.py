"""Paddle Billing integration — server-side helpers."""
from typing import Optional

from paddle_billing import Client, Environment, Options

from app.core.config import settings


def client() -> Client:
    """Return a Paddle client using the API key from settings."""
    key = settings.PADDLE_API_KEY
    if not key:
        raise RuntimeError("PADDLE_API_KEY not configured")
    return Client(key)


def client_token() -> str:
    return settings.PADDLE_CLIENT_TOKEN


def price_for_tier(tier: str) -> Optional[str]:
    if tier == "plus":
        return settings.PADDLE_PRICE_PLUS or None
    if tier == "pro":
        return settings.PADDLE_PRICE_PRO or None
    return None


def tier_for_price(price_id: str) -> str:
    if price_id and price_id == settings.PADDLE_PRICE_PLUS:
        return "plus"
    if price_id and price_id == settings.PADDLE_PRICE_PRO:
        return "pro"
    return "free"
