import secrets

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials

from app.config import get_settings

_basic = HTTPBasic(auto_error=False)
_ADMIN_USERNAME = "admin"


def require_admin(
    credentials: HTTPBasicCredentials | None = Depends(_basic),
) -> None:
    """Gate admin/write endpoints behind HTTP Basic auth.

    The password is ADMIN_API_KEY. When it is unset the admin surface is
    disabled entirely (fail closed) instead of being world-writable.
    Basic auth is used so the browser-loaded /admin page and its same-origin
    fetch() calls are authenticated automatically.
    """
    settings = get_settings()
    if not settings.admin_api_key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Admin API is disabled (ADMIN_API_KEY not set)",
        )
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Admin authentication required",
            headers={"WWW-Authenticate": "Basic"},
        )
    user_ok = secrets.compare_digest(credentials.username, _ADMIN_USERNAME)
    key_ok = secrets.compare_digest(credentials.password, settings.admin_api_key)
    if not (user_ok and key_ok):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid admin credentials",
            headers={"WWW-Authenticate": "Basic"},
        )
