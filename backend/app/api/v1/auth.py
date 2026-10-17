"""Auth endpoints: register + login."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.core.database import get_session
from app.core.security import (
    create_access_token,
    hash_password,
    verify_password,
)
from app.models.user import User
from app.schemas.user import GoogleLogin, TokenResponse, UserLogin, UserPublic, UserRegister

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=UserPublic, status_code=201)
def register(payload: UserRegister, session: Session = Depends(get_session)):
    # unique checks
    existing = session.exec(
        select(User).where(
            (User.email == payload.email) | (User.username == payload.username)
        )
    ).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email or username already registered",
        )

    user = User(
        email=payload.email,
        username=payload.username,
        hashed_password=hash_password(payload.password),
        full_name=payload.full_name,
        native_language=payload.native_language,
        learning_language=payload.learning_language,
    )
    session.add(user)
    session.commit()
    session.refresh(user)

    # Apply referral code if given
    if payload.referral_code:
        from app.services.referrals import apply_referral
        apply_referral(session, user, payload.referral_code)
        session.refresh(user)

    return user


@router.post("/login", response_model=TokenResponse)
def login(payload: UserLogin, session: Session = Depends(get_session)):
    user = session.exec(select(User).where(User.email == payload.email)).first()
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    if user.is_banned:
        raise HTTPException(status_code=403, detail="Account is banned")

    token = create_access_token(subject=str(user.id))
    return TokenResponse(access_token=token)


@router.post("/google", response_model=TokenResponse)
def google_login(payload: GoogleLogin, session: Session = Depends(get_session)):
    """Sign in / sign up with a Google ID token."""
    from app.services.google_auth import (
        extract_google_profile,
        verify_google_id_token,
    )

    claims = verify_google_id_token(payload.id_token)
    profile = extract_google_profile(claims)

    google_sub = profile["google_sub"]
    email = profile["email"]
    if not google_sub or not email:
        raise HTTPException(400, "Google token missing required fields")

    # 1) Existing Google user
    user = session.exec(select(User).where(User.google_id == google_sub)).first()

    # 2) Existing email user -> bind google_id
    if user is None:
        user = session.exec(select(User).where(User.email == email)).first()
        if user is not None:
            user.google_id = google_sub
            if not user.full_name and profile.get("name"):
                user.full_name = profile["name"]
            if not user.avatar_url and profile.get("picture"):
                user.avatar_url = profile["picture"]
            session.add(user)
            session.commit()
            session.refresh(user)

    # 3) New user
    if user is None:
        base = (email.split("@")[0] or "user")[:24]
        username = base
        i = 1
        while session.exec(select(User).where(User.username == username)).first():
            i += 1
            username = f"{base}{i}"
        user = User(
            email=email,
            username=username,
            hashed_password="!google-oauth",
            google_id=google_sub,
            full_name=profile.get("name"),
            avatar_url=profile.get("picture"),
        )
        session.add(user)
        session.commit()
        session.refresh(user)

    if user.is_banned:
        raise HTTPException(403, "Account is banned")

    token = create_access_token(subject=str(user.id))
    return TokenResponse(access_token=token)
