"""Push notifications via ntfy.sh — no accounts, no Firebase.

Each user has a secret topic. Backend POSTs plain text to ntfy.sh and
subscribers get push notifications instantly.
"""
import secrets
import uuid

import httpx

NTFY_BASE = "https://ntfy.sh"


def generate_topic() -> str:
    """Return a long random topic — practically impossible to guess."""
    return f"ll-{secrets.token_urlsafe(18)}"


async def notify(
    topic: str,
    title: str,
    body: str,
    tags: list[str] | None = None,
    click_url: str | None = None,
) -> bool:
    """Send a push to a topic. Silently fails on error."""
    if not topic:
        return False
    headers = {
        "Title": title,
        "Tags": ",".join(tags or ["bell"]),
    }
    if click_url:
        headers["Click"] = click_url
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            r = await client.post(
                f"{NTFY_BASE}/{topic}",
                content=body.encode("utf-8"),
                headers=headers,
            )
            return r.status_code < 300
    except Exception:
        return False
