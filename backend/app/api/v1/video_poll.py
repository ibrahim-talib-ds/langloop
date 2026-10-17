"""HTTP Polling video streaming."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional
from app.api.deps import get_current_user
from app.core.redis_client import redis_client
from app.models.user import User
import json

router = APIRouter(prefix="/video-poll", tags=["video"])

class FrameMessage(BaseModel):
    to: str
    image: str

@router.post("/send")
def send_frame(msg: FrameMessage, current: User = Depends(get_current_user)):
    key = f"video:{msg.to}"
    redis_client.setex(key, 5, json.dumps({"from": str(current.id), "image": msg.image}))
    return {"ok": True}

@router.get("/receive")
def receive_frame(current: User = Depends(get_current_user)):
    key = f"video:{current.id}"
    data = redis_client.getdel(key)
    if data:
        return json.loads(data)
    return {}
