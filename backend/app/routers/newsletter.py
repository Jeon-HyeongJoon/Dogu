import re

from fastapi import APIRouter, HTTPException

from app.models import NewsletterContent, NewsletterSubscribeRequest, NewsletterSubscribeResponse
from app.repository import repository


router = APIRouter(prefix="/api/newsletter", tags=["newsletter"])
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


@router.get("", response_model=NewsletterContent)
def get_newsletter() -> NewsletterContent:
    return repository.data.newsletter


@router.post("/subscribe", response_model=NewsletterSubscribeResponse, status_code=202)
def subscribe(request: NewsletterSubscribeRequest) -> NewsletterSubscribeResponse:
    email = request.email.strip().lower()
    if not EMAIL_RE.fullmatch(email):
        raise HTTPException(status_code=422, detail="Invalid email address")
    return NewsletterSubscribeResponse(
        accepted=True,
        email=email,
        message="구독 요청을 받았습니다. 이 MVP는 이메일을 저장하지 않습니다.",
    )
