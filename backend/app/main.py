"""LangLoop API - entry point."""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.api.v1 import admin as admin_router
from app.api.v1 import admin_activity as admin_activity_router
from app.api.v1 import auth as auth_router
from app.api.v1 import password_reset_api as reset_router
from app.api.v1 import billing as billing_router
from app.api.v1 import geo as geo_router
from app.api.v1 import friends as friends_router
from app.api.v1 import match as match_router
from app.api.v1 import video as video_router
from app.api.v1 import video_poll as video_poll_router
from app.api.v1 import video_stream as video_router
from app.api.v1 import ws_fallback as signal_poll_router
from app.api.v1 import ws_fallback as signal_router
from app.api.v1 import support as support_router
from app.api.v1 import me as me_router
from app.api.v1 import referrals as referrals_router
from app.api.v1 import messages as messages_router
from app.api.v1 import social as social_router
from app.api.v1 import users as users_router
from app.api.v1 import ws as ws_router
from app.core.config import settings
from app.core.database import engine, init_db
from app.core.redis_client import ping_redis
from app.services.admin_seed import ensure_admin_seed


@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"🚀 Starting {settings.APP_NAME} [{settings.ENV}]")
    init_db()
    print("✅ Database tables ready")
    ensure_admin_seed()
    yield
    print("👋 Shutting down")


app = FastAPI(
    title=settings.APP_NAME,
    description="Practice English 1-on-1 with real people.",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", tags=["root"])
def root():
    return {"app": settings.APP_NAME, "env": settings.ENV, "docs": "/docs"}


@app.get("/health", tags=["health"])
def health():
    db_ok = True
    db_error = ""
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
    except Exception as e:
        db_ok = False
        db_error = str(e)
    redis_ok = ping_redis()
    body = {
        "status": "ok" if (db_ok and redis_ok) else "degraded",
        "postgres": "up" if db_ok else "down",
        "redis": "up" if redis_ok else "down",
    }
    if not db_ok:
        body["postgres_error"] = db_error
    return body


# ─── Static files (avatars) ───
app.mount(
    "/static",
    StaticFiles(directory=str(__import__("pathlib").Path(__file__).resolve().parents[1] / "storage")),
    name="static",
)

app.include_router(auth_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(reset_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(billing_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(users_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(admin_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(admin_activity_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(match_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(video_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(video_poll_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(video_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(signal_poll_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(signal_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(friends_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(support_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(me_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(referrals_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(messages_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(geo_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(social_router.router, prefix=settings.API_V1_PREFIX)
app.include_router(ws_router.router, prefix=settings.API_V1_PREFIX)
