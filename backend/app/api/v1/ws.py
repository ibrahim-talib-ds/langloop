"""WebSocket endpoint for WebRTC signaling."""
from uuid import UUID
from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from sqlmodel import Session
from app.core.database import engine
from app.core.security import decode_access_token
from app.models.user import User
from app.services.signaling import signaling_manager

router = APIRouter(prefix="/ws", tags=["websocket"])

@router.websocket("/signal")
async def signal(ws: WebSocket, token: str = Query(...)):
    user_id = decode_access_token(token)
    if not user_id:
        await ws.close(code=4401)
        return

    with Session(engine) as session:
        user = session.get(User, UUID(user_id))
        if not user or user.is_banned:
            await ws.close(code=4403)
            return

    await signaling_manager.connect(user_id, ws)

    try:
        while True:
            data = await ws.receive_json()
            to_user = data.get("to")
            if to_user:
                await signaling_manager.send_to(str(to_user), {**data, "from": user_id})
    except WebSocketDisconnect:
        signaling_manager.disconnect(user_id)
