"""WebSocket endpoint for WebRTC signaling."""
from uuid import UUID

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from sqlmodel import Session, select

from app.core.database import engine
from app.core.security import decode_access_token
from app.models.match import Match
from app.models.user import User
from app.services.signaling import signaling_manager

router = APIRouter(prefix="/ws", tags=["websocket"])


@router.websocket("/signal")
async def signal(ws: WebSocket, token: str = Query(...)):
    # ─── Authenticate ───
    user_id = decode_access_token(token)
    if not user_id:
        await ws.close(code=4401)
        return

    with Session(engine) as session:
        user = session.get(User, UUID(user_id))
        if not user or user.is_banned:
            await ws.close(code=4403)
            return

    # ─── Register connection ───
    await signaling_manager.connect(user_id, ws)

    # Tell the peer (if matched & online) that we're online
    try:
        with Session(engine) as session:
            match = session.exec(
                select(Match)
                .where((Match.user_a_id == UUID(user_id)) | (Match.user_b_id == UUID(user_id)))
                .where(Match.ended_at == None)  # noqa: E711
                .order_by(Match.started_at.desc())
            ).first()
            if match:
                peer_id = (
                    str(match.user_b_id)
                    if str(match.user_a_id) == user_id
                    else str(match.user_a_id)
                )
                await signaling_manager.send_to(
                    peer_id,
                    {"type": "peer-online", "from": user_id, "match_id": str(match.id)},
                )
    except Exception:
        pass

    # ─── Main message loop ───
    try:
        while True:
            data = await ws.receive_json()
            msg_type = data.get("type")
            to_user = data.get("to")

            # Client must specify "to" (their matched partner)
            if not to_user:
                await ws.send_json({"type": "error", "detail": "missing 'to'"})
                continue

            relay = {**data, "from": user_id}
            delivered = await signaling_manager.send_to(str(to_user), relay)
            if not delivered:
                await ws.send_json(
                    {"type": "peer-offline", "to": to_user}
                )

    except WebSocketDisconnect:
        signaling_manager.disconnect(user_id)
        # Notify peer they went offline
        try:
            with Session(engine) as session:
                match = session.exec(
                    select(Match)
                    .where((Match.user_a_id == UUID(user_id)) | (Match.user_b_id == UUID(user_id)))
                    .where(Match.ended_at == None)  # noqa: E711
                    .order_by(Match.started_at.desc())
                ).first()
                if match:
                    peer_id = (
                        str(match.user_b_id)
                        if str(match.user_a_id) == user_id
                        else str(match.user_a_id)
                    )
                    await signaling_manager.send_to(
                        peer_id, {"type": "peer-offline", "from": user_id}
                    )
        except Exception:
            pass
    except Exception:
        signaling_manager.disconnect(user_id)
