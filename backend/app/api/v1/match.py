"""Matchmaking endpoints."""
from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session

from app.api.deps import get_current_user
from app.core.database import get_session
from app.models.match import Match
from app.models.user import User
from app.schemas.match import (
    MatchEndResponse,
    MatchJoinRequest,
    MatchStatusResponse,
)
from app.services import matchmaker
from app.services.minutes import minutes_summary

router = APIRouter(prefix="/match", tags=["match"])


@router.post("/join", response_model=MatchStatusResponse)
def join(
    payload: MatchJoinRequest,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    summary = minutes_summary(session, current)
    if summary["is_exhausted"]:
        raise HTTPException(
            status_code=402,
            detail={
                "code": "out_of_minutes",
                "used_today": summary["used_today"],
                "daily_limit": summary["daily_limit"],
                "bonus_minutes": summary["bonus_minutes"],
                "message": "You've used today's free minutes. "
                           "Invite a friend for 30 more, or upgrade.",
            },
        )
    m = matchmaker.join_queue(
        session, str(current.id), payload.language, payload.topic
    )
    if m is None:
        return MatchStatusResponse(
            state="waiting",
            queue_size=matchmaker.queue_size(payload.language, payload.topic),
            language=payload.language,
            topic=payload.topic,
        )

    # We were matched
    partner_id = m.user_a_id if m.user_b_id == current.id else m.user_b_id
    partner = session.get(User, partner_id)
    return MatchStatusResponse(
        state="matched",
        match_id=m.id,
        partner_id=partner_id,
        partner_username=partner.username if partner else None,
        language=m.language,
        topic=m.topic,
        started_at=m.started_at,
    )


@router.get("/status", response_model=MatchStatusResponse)
def status(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    match_id = matchmaker.get_match_id(str(current.id))
    if not match_id:
        return MatchStatusResponse(state="idle")

    m = session.get(Match, UUID(match_id))
    if not m:
        return MatchStatusResponse(state="idle")

    partner_id = m.user_a_id if m.user_b_id == current.id else m.user_b_id
    partner = session.get(User, partner_id)
    return MatchStatusResponse(
        state="matched",
        match_id=m.id,
        partner_id=partner_id,
        partner_username=partner.username if partner else None,
        language=m.language,
        topic=m.topic,
        started_at=m.started_at,
    )


@router.post("/leave")
def leave(current: User = Depends(get_current_user)):
    removed = matchmaker.leave_queue(str(current.id))
    return {"left": removed}


@router.post("/{match_id}/end", response_model=MatchEndResponse)
def end_match(
    match_id: UUID,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    m = session.get(Match, match_id)
    if not m:
        raise HTTPException(404, "Match not found")
    if current.id not in (m.user_a_id, m.user_b_id):
        raise HTTPException(403, "Not part of this match")
    if m.ended_at is not None:
        raise HTTPException(400, "Already ended")

    now = datetime.utcnow()
    m.ended_at = now
    m.duration_seconds = int((now - m.started_at).total_seconds())
    m.ended_by = current.id
    session.add(m)
    session.commit()
    session.refresh(m)

    # Clear both users' match keys
    matchmaker.redis_client.delete(matchmaker._match_key(str(m.user_a_id)))
    matchmaker.redis_client.delete(matchmaker._match_key(str(m.user_b_id)))

    return MatchEndResponse(
        match_id=m.id, duration_seconds=m.duration_seconds or 0, ended_at=now
    )
