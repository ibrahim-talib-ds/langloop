# LangLoop Backend — API Reference

Base URL (dev): http://localhost:8001
API prefix: /api/v1

## Health
- GET    /                      → app info
- GET    /health                → postgres + redis status

## Auth
- POST   /api/v1/auth/register  → create account
- POST   /api/v1/auth/login     → get JWT token

## Users
- GET    /api/v1/users/me       → current user (auth)

## Admin (admin-only)
- GET    /api/v1/admin/stats    → counts
- GET    /api/v1/admin/users    → list all users (search, paginate)
- GET    /api/v1/admin/users/{id}
- POST   /api/v1/admin/users/{id}/ban     (reason in body)
- POST   /api/v1/admin/users/{id}/unban
- POST   /api/v1/admin/users/{id}/promote
- POST   /api/v1/admin/users/{id}/demote

## Matchmaking
- POST   /api/v1/match/join         → join queue (language + topic)
- GET    /api/v1/match/status       → waiting / matched / idle
- POST   /api/v1/match/leave        → leave queue
- POST   /api/v1/match/{id}/end     → mark match complete

## Social
- POST   /api/v1/matches/{id}/rate  → rate 1-5, triggers friendship + XP
- GET    /api/v1/friends            → your friends list
- GET    /api/v1/me/stats           → xp, level, badge, streak, matches, friends

## WebSocket
- WS     /api/v1/ws/signal?token=JWT
  Messages: {type: "offer"|"answer"|"ice"|"hangup", to: <user_id>, ...}
  Server pushes: {type: "peer-online"|"peer-offline"|"error"}

## Backend commit checklist
- Postgres: users, matches, ratings, friends
- Redis: queue:{lang}:{topic}, user_lang:{id}, user_match:{id}
- JWT: HS256, 7-day expiry, sub = user uuid
- Password: bcrypt 4.0.1 + passlib
