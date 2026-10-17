"""Gamification: XP, streaks, levels, badges."""
from datetime import date, timedelta
from typing import List

from app.models.user import User


# ─── XP awards ───
XP_PER_MATCH = 10          # completing one 5-min session
XP_PER_5STAR = 5           # bonus for a 5-star rating received
XP_PER_NEW_FRIEND = 20     # bonus for each new friend
XP_PER_STREAK_DAY = 5      # bonus per consecutive day


LEVELS = [
    (0,    1, "🌱", "Newcomer"),
    (100,  2, "🥉", "Starter"),
    (300,  3, "🥈", "Regular"),
    (600,  4, "🥇", "Pro"),
    (1000, 5, "💎", "Master"),
    (2000, 6, "👑", "Legend"),
]


def level_from_xp(xp: int) -> dict:
    current = LEVELS[0]
    for threshold, lvl, badge, name in LEVELS:
        if xp >= threshold:
            current = (threshold, lvl, badge, name)
    next_tier = None
    for threshold, lvl, badge, name in LEVELS:
        if threshold > xp:
            next_tier = (threshold, lvl, badge, name)
            break
    return {
        "level": current[1],
        "badge": current[2],
        "title": current[3],
        "xp": xp,
        "next_xp": next_tier[0] if next_tier else None,
        "progress": (
            int((xp - current[0]) / (next_tier[0] - current[0]) * 100)
            if next_tier else 100
        ),
    }


def update_streak(user: User) -> None:
    """Call this after a completed match."""
    today = date.today()
    if user.last_practice_date is None:
        user.streak_days = 1
    elif user.last_practice_date == today:
        pass  # already counted today
    elif user.last_practice_date == today - timedelta(days=1):
        user.streak_days += 1
    else:
        user.streak_days = 1
    user.last_practice_date = today


def award_match_xp(user: User, stars_received: int = 0, new_friends: int = 0) -> int:
    gained = XP_PER_MATCH
    if stars_received == 5:
        gained += XP_PER_5STAR
    gained += XP_PER_NEW_FRIEND * new_friends
    gained += XP_PER_STREAK_DAY * max(user.streak_days - 1, 0)
    user.xp += gained
    user.total_matches += 1
    return gained
