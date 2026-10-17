"""WebSocket video streaming for simple fallback."""
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import Dict, List
import asyncio

router = APIRouter(prefix="/video-stream", tags=["video"])

# Store connections in memory
connections: Dict[str, WebSocket] = {}
pairs: Dict[str, str] = {}

@router.websocket("/ws/{user_id}")
async def video_stream(ws: WebSocket, user_id: str):
    await ws.accept()
    connections[user_id] = ws
    try:
        while True:
            # Just wait for data, then forward it
            data = await ws.receive_text()
            # The message contains {"to": "partner_id", "image": "base64..."}
            import json
            try:
                msg = json.loads(data)
                to_id = msg.get("to")
                if to_id and to_id in connections:
                    await connections[to_id].send_text(json.dumps({
                        "from": user_id,
                        "image": msg.get("image")
                    }))
            except:
                pass
    except WebSocketDisconnect:
        if user_id in connections:
            del connections[user_id]
