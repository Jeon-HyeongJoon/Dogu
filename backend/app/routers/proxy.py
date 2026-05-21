import httpx
from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import Response

router = APIRouter(prefix="/api/proxy", tags=["proxy"])

_ALLOWED_HOSTS = {
    "shopping-phinf.pstatic.net",
    "shop-phinf.pstatic.net",
    "phinf.pstatic.net",
}

_HEADERS = {
    "Referer": "https://search.shopping.naver.com/",
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36"
    ),
}


@router.get("/image")
async def proxy_image(url: str = Query(...)) -> Response:
    from urllib.parse import urlparse

    parsed = urlparse(url)
    if parsed.hostname not in _ALLOWED_HOSTS:
        raise HTTPException(status_code=403, detail="Host not allowed")

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(url, headers=_HEADERS, follow_redirects=True)
            resp.raise_for_status()
    except Exception as e:
        raise HTTPException(status_code=502, detail=str(e))

    content_type = resp.headers.get("content-type", "image/jpeg")
    return Response(
        content=resp.content,
        media_type=content_type,
        headers={"Cache-Control": "public, max-age=86400"},
    )
