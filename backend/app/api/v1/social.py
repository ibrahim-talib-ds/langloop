"""Ratings, friends, and user stats."""
from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, func, select

from app.api.deps import get_current_user
from app.core.database import get_session
from app.models.friend import Friend
from app.models.match import Match
from app.models.rating import Rating
from app.models.user import User
from app.schemas.friend import FriendPublic, UserStats
from app.schemas.rating import RatingCreate, RatingPublic, RatingResult
from app.services.gamification import award_match_xp, level_from_xp, update_streak

router = APIRouter(tags=["social"])


# ─────────────────── RATINGS ───────────────────

@router.post("/matches/{match_id}/rate", response_model=RatingResult)
def rate_match(
    match_id: UUID,
    payload: RatingCreate,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    match = session.get(Match, match_id)
    if not match:
        raise HTTPException(404, "Match not found")
    if current.id not in (match.user_a_id, match.user_b_id):
        raise HTTPException(403, "Not part of this match")

    partner_id = match.user_b_id if match.user_a_id == current.id else match.user_a_id

    # One rating per (match, rater)
    existing = session.exec(
        select(Rating).where(
            Rating.match_id == match_id, Rating.rater_id == current.id
        )
    ).first()
    if existing:
        raise HTTPException(400, "You already rated this match")

    rating = Rating(
        match_id=match_id,
        rater_id=current.id,
        rated_id=partner_id,
        stars=payload.stars,
        comment=payload.comment,
    )
    session.add(rating)

    # ─── Auto-friend if both rated ≥ 4 ───
    became_friends = False
    partner_rating = session.exec(
        select(Rating).where(
            Rating.match_id == match_id, Rating.rater_id == partner_id
        )
    ).first()

    if payload.stars >= 4 and partner_rating and partner_rating.stars >= 4:
        # Check neither already friends
        already = session.exec(
            select(Friend).where(
                Friend.user_id == current.id, Friend.friend_id == partner_id
            )
        ).first()
        if not already:
            session.add(Friend(user_id=current.id, friend_id=partner_id))
            session.add(Friend(user_id=partner_id, friend_id=current.id))
            became_friends = True

    # ─── Gamification for the RATER ───
    update_streak(current)
    xp_gained = award_match_xp(
        current, stars_received=0, new_friends=1 if became_friends else 0
    )

    session.add(current)
    session.commit()
    session.refresh(rating)

    return RatingResult(
        rating=RatingPublic.model_validate(rating, from_attributes=True),
        became_friends=became_friends,
        xp_gained=xp_gained,
    )


# ─────────────────── FRIENDS ───────────────────

@router.get("/friends", response_model=list[FriendPublic])
def list_friends(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    rows = session.exec(
        select(Friend).where(Friend.user_id == current.id)
    ).all()
    out = []
    for f in rows:
        u = session.get(User, f.friend_id)
        if not u or u.is_banned:
            continue
        out.append(
            FriendPublic(
                id=u.id,
                username=u.username,
                full_name=u.full_name,
                avatar_url=u.avatar_url,
                native_language=u.native_language,
                learning_language=u.learning_language,
                level=u.level,
                xp=u.xp,
                friend_since=f.created_at,
            )
        )
    return out


# ─────────────────── STATS ───────────────────

@router.get("/me/stats", response_model=UserStats)
def my_stats(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    friend_count = session.exec(
        select(func.count()).select_from(Friend).where(Friend.user_id == current.id)
    ).one()
    lvl = level_from_xp(current.xp)
    return UserStats(
        xp=current.xp,
        level=lvl["level"],
        badge=lvl["badge"],
        title=lvl["title"],
        next_xp=lvl["next_xp"],
        progress=lvl["progress"],
        streak_days=current.streak_days,
        total_matches=current.total_matches,
        friend_count=friend_count,
    )
