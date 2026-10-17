"""HTTP Polling fallback for WebRTC signaling."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional, List
from app.api.deps import get_current_user
from app.core.redis_client import redis_client
from app.models.user import User
import json

router = APIRouter(prefix="/signal-poll", tags=["signal"])

class SignalMessage(BaseModel):
    type: str
    to: str
    sdp: Optional[str] = None
    sdpType: Optional[str] = None
    candidate: Optional[dict] = None

@router.post("/send")
def send_signal(msg: SignalMessage, current: User = Depends(get_current_user)):
    key = f"signal:{msg.to}"
    data = {"from": str(current.id), **msg.model_dump()}
    redis_client.lpush(key, json.dumps(data))
    redis_client.expire(key, 60)
    return {"ok": True}

@router.get("/receive")
def receive_signals(current: User = Depends(get_current_user)):
    key = f"signal:{current.id}"
    items = redis_client.lrange(key, 0, -1)
    if items:
        redis_client.delete(key)
    return [json.loads(i) for i in items]
