from fastapi import APIRouter, Depends
from app.models import User
from app.schemas import User as UserSchema
from app.dependencies import get_current_user

router = APIRouter()

@router.get("/me", response_model=UserSchema)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    return current_user