from datetime import timedelta
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from auth import (
    ACCESS_TOKEN_EXPIRE_MINUTES,
    authenticate_user,
    create_access_token,
    get_current_user,
    hash_password,
    require_roles,
)
from database import get_db
from models import User
from schemas import UserCreate, UserRead, Token

router = APIRouter(prefix="/auth", tags=["Authentication"])

VALID_ROLES = {
    "admin",
    "inventory_officer",
    "safety_officer",
    "viewer",
}


@router.post("/login", response_model=Token)
def login(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: Session = Depends(get_db),
):
    user = authenticate_user(
        db,
        form_data.username,
        form_data.password,
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = create_access_token(
        subject=user.username,
        expires_delta=timedelta(
            minutes=ACCESS_TOKEN_EXPIRE_MINUTES,
        ),
    )

    return {
        "access_token": token,
        "token_type": "bearer",
    }


@router.get("/me", response_model=UserRead)
def read_current_user(
    current_user: Annotated[User, Depends(get_current_user)],
):
    return current_user


@router.post("/users", response_model=UserRead)
def create_user(
    payload: UserCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("admin")),
):
    username = payload.username.strip()

    if not username:
        raise HTTPException(
            status_code=400,
            detail="Username is required.",
        )

    if payload.role not in VALID_ROLES:
        raise HTTPException(
            status_code=400,
            detail="Invalid user role.",
        )

    existing_user = (
        db.query(User)
        .filter(User.username == username)
        .first()
    )

    if existing_user is not None:
        raise HTTPException(
            status_code=409,
            detail="Username already exists.",
        )

    if len(payload.password) < 8:
        raise HTTPException(
            status_code=400,
            detail="Password must contain at least 8 characters.",
        )

    user = User(
        username=username,
        full_name=payload.full_name,
        hashed_password=hash_password(payload.password),
        role=payload.role,
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return user