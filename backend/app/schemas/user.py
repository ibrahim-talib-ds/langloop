"""Pydantic schemas for auth + user responses."""
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class UserRegister(BaseModel):
    email: EmailStr
    username: str = Field(min_length=3, max_length=32)
    password: str = Field(min_length=6, max_length=128)
    full_name: Optional[str] = None
    native_language: str = "en"
    learning_language: str = "en"
    referral_code: Optional[str] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class GoogleLogin(BaseModel):
    id_token: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserUpdate(BaseModel):
    full_name: Optional[str] = Field(default=None, max_length=80)
    bio: Optional[str] = Field(default=None, max_length=280)
    country: Optional[str] = Field(default=None, max_length=64)
    native_language: Optional[str] = Field(default=None, max_length=8)
    learning_language: Optional[str] = Field(default=None, max_length=8)
    level: Optional[str] = Field(default=None, max_length=16)


class UserPublic(BaseModel):
    id: UUID
    email: EmailStr
    username: str
    full_name: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None
    country: Optional[str] = None
    native_language: str
    learning_language: str
    level: str
    is_admin: bool
    is_banned: bool
    subscription_tier: str
    daily_minutes_used: int
    created_at: datetime

    class Config:
        from_attributes = True
