"""Agora Token Generator."""
from datetime import datetime
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from agora_token_builder import RtcTokenBuilder
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter(prefix="/video", tags=["video"])

class TokenRequest(BaseModel):
    channelName: str
    uid: int

@router.post("/token")
def generate_token(payload: TokenRequest, current: User = Depends(get_current_user)):
    app_id = "362ac9b730a2499199766380f58eecc6"
    app_certificate = "1bfc716244904d4398578c784d7bf31f"
    
    # Token expires in 2 hours
    expiration_time_in_seconds = 7200
    current_timestamp = int(datetime.now().timestamp())
    privilege_expired_ts = current_timestamp + expiration_time_in_seconds
    
    # Role 1 = Publisher (can send video/audio)
    token = RtcTokenBuilder.buildTokenWithUid(
        app_id, app_certificate, payload.channelName, payload.uid, 1, privilege_expired_ts
    )
    
    return {"token": token}
