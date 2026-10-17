# LangLoop — Backend

Practice a language 1-on-1 with real people. Random video, 5-minute rounds,
topic-based, safe by design.

## Stack
- FastAPI + SQLModel + Postgres 17 (Docker)
- Redis (matchmaking queue)
- WebRTC (client-side) via WebSocket signaling
- JWT auth, bcrypt passwords
- Admin panel (ban / promote / stats)

## Quick start

### 1. Start services
docker compose up -d

### 2. Activate venv
source .venv/bin/activate

### 3. Run the server
uvicorn app.main:app --reload --port 8001

### 4. Open the docs
http://localhost:8001/docs

## Structure
app/
  core/        # config, db, redis, security
  models/      # User, Match, Rating, Friend
  schemas/     # request/response shapes
  api/v1/      # auth, users, admin, match, social, ws
  services/    # matchmaker, signaling, gamification, admin_seed
  main.py      # FastAPI entry

## Endpoints
See API.md

## Dev conventions
- LangLoop uses port 8001 (not 8000)
- Every API call needs `Authorization: Bearer <JWT>`
- Matchmaking uses Redis keys `queue:{language}:{topic}`
- Ratings auto-friend when both sides rate ≥ 4
- XP awards: 10/match, +5 for 5★, +20 per new friend, +5/day streak

## Env
Copy `.env.example` to `.env` and adjust.
