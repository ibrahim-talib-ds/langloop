"""Local-disk file storage for avatars.

Swap this file for Cloudflare R2 / S3 later — only `save_bytes()`
and `public_url()` need to change.
"""
import os
import uuid
from pathlib import Path

from fastapi import HTTPException, UploadFile, status

# Where files live on disk
STORAGE_ROOT = Path(__file__).resolve().parents[2] / "storage"
AVATAR_DIR = STORAGE_ROOT / "avatars"
AVATAR_DIR.mkdir(parents=True, exist_ok=True)

# Size + type limits
MAX_AVATAR_BYTES = 3 * 1024 * 1024   # 3 MB
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}


async def save_avatar(user_id: str, file: UploadFile) -> str:
    """Save uploaded file, return relative URL path (/static/avatars/<name>)."""
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file type: {file.content_type}",
        )

    data = await file.read()
    if len(data) > MAX_AVATAR_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File too large (max {MAX_AVATAR_BYTES // 1024 // 1024} MB)",
        )

    ext = {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "image/webp": ".webp",
        "image/gif": ".gif",
    }[file.content_type]

    name = f"{user_id}_{uuid.uuid4().hex[:8]}{ext}"
    dest = AVATAR_DIR / name
    with dest.open("wb") as f:
        f.write(data)

    # Delete any previous avatar for this user (best effort)
    _cleanup_old_avatars(user_id, keep=name)

    return f"/static/avatars/{name}"


def _cleanup_old_avatars(user_id: str, keep: str) -> None:
    try:
        for p in AVATAR_DIR.glob(f"{user_id}_*"):
            if p.name != keep:
                p.unlink(missing_ok=True)
    except Exception:
        pass


def delete_avatar(user_id: str) -> None:
    _cleanup_old_avatars(user_id, keep="")
