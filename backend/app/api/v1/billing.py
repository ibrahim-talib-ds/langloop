"""Paddle billing - checkout URL + webhook receiver."""
from datetime import datetime
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel
from sqlmodel import Session, select

from app.api.deps import get_current_user
from app.core.config import settings
from app.core.database import get_session
from app.models.subscription import Subscription
from app.models.user import User
from app.services import paddle as paddle_svc

router = APIRouter(prefix="/billing", tags=["billing"])


class CheckoutRequest(BaseModel):
    tier: str  # "plus" | "pro"


class CheckoutResponse(BaseModel):
    checkout_url: str
    price_id: str


@router.post("/checkout", response_model=CheckoutResponse)
def create_checkout(
    payload: CheckoutRequest,
    current: User = Depends(get_current_user),
):
    """Return a hosted Paddle checkout URL for the chosen tier."""
    price_id = paddle_svc.price_for_tier(payload.tier)
    if not price_id:
        raise HTTPException(400, f"Tier '{payload.tier}' not configured")

    # Hosted checkout — Paddle will collect payment in its own UI.
    # We pass the user's email + our user_id as custom_data.
    url = (
        f"https://checkout.paddle.com/checkout/custom"
        f"?price_id={price_id}"
        f"&user_email={current.email}"
    )
    return CheckoutResponse(checkout_url=url, price_id=price_id)


@router.get("/me")
def my_subscription(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    sub = session.exec(
        select(Subscription).where(Subscription.user_id == current.id)
    ).first()
    if not sub:
        return {"tier": "free", "status": "none"}
    return {
        "tier": sub.tier,
        "status": sub.status,
        "current_period_end": sub.current_period_end.isoformat()
        if sub.current_period_end
        else None,
    }


@router.post("/webhook")
async def paddle_webhook(
    request: Request,
    session: Session = Depends(get_session),
):
    """Handle Paddle webhook events (signature verification optional for now)."""
    try:
        body = await request.json()
    except Exception:
        raise HTTPException(400, "Invalid JSON")

    event_type = body.get("event_type") or body.get("eventType") or ""
    data = body.get("data") or {}

    if event_type.startswith("subscription."):
        await _upsert_subscription(session, data)

    return {"received": True, "type": event_type}


async def _upsert_subscription(session: Session, data: dict):
    sub_id = data.get("id")
    customer_id = data.get("customer_id") or ""
    status = data.get("status", "active")

    # Extract price id
    price_id = ""
    items = data.get("items") or []
    if items and isinstance(items, list):
        first = items[0] or {}
        price = first.get("price") or {}
        price_id = price.get("id") or ""

    # Extract our user_id from custom_data
    custom = data.get("custom_data") or {}
    user_id_str = custom.get("user_id")

    if not sub_id or not user_id_str:
        return

    try:
        user_id = UUID(user_id_str)
    except Exception:
        return

    tier = paddle_svc.tier_for_price(price_id)

    existing = session.exec(
        select(Subscription).where(
            Subscription.paddle_subscription_id == sub_id
        )
    ).first()

    if existing:
        existing.status = status
        existing.tier = tier
        existing.price_id = price_id
        existing.updated_at = datetime.utcnow()
        session.add(existing)
    else:
        session.add(
            Subscription(
                user_id=user_id,
                paddle_subscription_id=sub_id,
                paddle_customer_id=customer_id,
                price_id=price_id,
                status=status,
                tier=tier or "plus",
            )
        )

    # Also mirror tier onto the user row for quick checks
    user = session.get(User, user_id)
    if user:
        user.subscription_tier = tier or "plus"
        session.add(user)

    session.commit()
