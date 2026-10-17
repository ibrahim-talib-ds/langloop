"""In-memory WebSocket connection manager.

Tracks active WebSocket connections by user_id.
In production we'd back this with Redis pub/sub for multi-worker setups.
"""
import json
from typing import Dict, Optional

from fastapi import WebSocket


class SignalingManager:
    def __init__(self) -> None:
        self._connections: Dict[str, WebSocket] = {}

    async def connect(self, user_id: str, ws: WebSocket) -> None:
        await ws.accept()
        # If the user already had a connection, close it (reconnect)
        old = self._connections.get(user_id)
        if old is not None:
            try:
                await old.close()
            except Exception:
                pass
        self._connections[user_id] = ws

    def disconnect(self, user_id: str) -> None:
        self._connections.pop(user_id, None)

    def is_online(self, user_id: str) -> bool:
        return user_id in self._connections

    async def send_to(self, user_id: str, message: dict) -> bool:
        ws = self._connections.get(user_id)
        if ws is None:
            return False
        try:
            await ws.send_text(json.dumps(message))
            return True
        except Exception:
            self.disconnect(user_id)
            return False


signaling_manager = SignalingManager()
