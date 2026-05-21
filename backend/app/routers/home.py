from fastapi import APIRouter

from app.models import HomeResponse
from app.repository import repository


router = APIRouter(prefix="/api", tags=["home"])


@router.get("/home", response_model=HomeResponse)
def get_home() -> HomeResponse:
    return repository.build_home()
