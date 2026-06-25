from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session

from database import engine, get_db, Base
from models import User
from schemas import UserCreate, UserOut, UserUpdate

# Create tables on startup
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Login API")


# ── Create ───────────────────────────────────────────────
@app.post("/users", response_model=UserOut, status_code=201)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == user.username).first():
        raise HTTPException(status_code=400, detail="Username already exists")
    db_user = User(username=user.username, password=user.password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


# ── Read All ─────────────────────────────────────────────
@app.get("/users", response_model=list[UserOut])
def list_users(db: Session = Depends(get_db)):
    return db.query(User).all()


# ── Read One ─────────────────────────────────────────────
@app.get("/users/{user_id}", response_model=UserOut)
def get_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


# ── Update ───────────────────────────────────────────────
@app.patch("/users/{user_id}", response_model=UserOut)
def update_user(user_id: int, data: UserUpdate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if data.username is None and data.password is None:
        raise HTTPException(status_code=400, detail="Nothing to update")
    if data.username is not None:
        existing = (
            db.query(User)
            .filter(User.username == data.username, User.id != user_id)
            .first()
        )
        if existing:
            raise HTTPException(status_code=400, detail="Username already exists")
        user.username = data.username
    if data.password is not None:
        user.password = data.password
    db.commit()
    db.refresh(user)
    return user


# ── Delete ───────────────────────────────────────────────
@app.delete("/users/{user_id}", status_code=204)
def delete_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    db.delete(user)
    db.commit()


# ── Login ────────────────────────────────────────────────
@app.post("/login")
def login(data: UserCreate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == data.username).first()
    if not user or user.password != data.password:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return {"message": "Login successful", "user_id": user.id}
