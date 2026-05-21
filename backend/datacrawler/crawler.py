import hashlib
import os
import time
from typing import Iterator

import requests

# success request template (from browser DevTools):
# GET /ns/v1/search/paged-composite-cards?cursor=51&pageSize=50&query=10006530&searchMethod=displayCategory.basic&listPage=1 HTTP/2
# Host: search.shopping.naver.com
# X-Wtm-Ncaptcha-Token: RkFJTFVSRXwxNzc5MTc5OTQzfG5jYXB0Y2hhIG5vdCBpbml0aWFsaXplZA==
# Sec-Ch-Ua: "Not-A.Brand";v="24", "Chromium";v="146"
# User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36
# Referer: https://search.shopping.naver.com/ns/category/10000506
# Accept-Encoding: gzip, deflate, br

_BASE_URL = "https://search.shopping.naver.com"
_PAGE_SIZE = 50
_MOTIFS = ["dots", "grid", "lines", "checker", "cross", "wave", "diag", "halftone"]
_MONOS = ["//", "→", "◆", "▲", "○", "×", "∞", "⬡"]


def _artwork(product_id: str) -> dict:
    h = int(hashlib.md5(product_id.encode()).hexdigest(), 16)
    return {
        "hue": h % 360,
        "saturation": 20 + (h >> 8) % 40,
        "lightness": 40 + (h >> 16) % 30,
        "mono": _MONOS[(h >> 24) % len(_MONOS)],
        "motif": _MOTIFS[(h >> 32) % len(_MOTIFS)],
    }


def _build_headers(category_id: str) -> dict:
    token = os.environ.get("NAVER_NCAPTCHA_TOKEN", "")
    return {
        "Host": "search.shopping.naver.com",
        "X-Wtm-Ncaptcha-Token": token,
        "Sec-Ch-Ua": '"Not-A.Brand";v="24", "Chromium";v="146"',
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36"
        ),
        "Referer": f"https://search.shopping.naver.com/ns/category/{category_id}",
        "Accept-Encoding": "gzip, deflate, br",
        "Accept": "application/json, text/plain, */*",
        "Accept-Language": "ko-KR,ko;q=0.9",
    }


def _fetch_page(category_id: str, cursor: int, page: int) -> dict | None:
    params = {
        "cursor": cursor,
        "pageSize": _PAGE_SIZE,
        "query": category_id,
        "searchMethod": "displayCategory.basic",
        "listPage": page,
    }
    try:
        resp = requests.get(
            f"{_BASE_URL}/ns/v1/search/paged-composite-cards",
            params=params,
            headers=_build_headers(category_id),
            timeout=15,
        )
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        print(f"  fetch error (cat={category_id}, page={page}): {e}")
        return None


def _parse(p: dict, category_id: str) -> dict | None:
    nv_mid = str(p.get("nvMid", ""))
    if not nv_mid:
        return None

    sale = p.get("salePrice") or 0
    discounted = p.get("discountedSalePrice") or sale
    ratio = p.get("discountedRatio") or 0

    if ratio > 0 and discounted < sale:
        price, old_price = discounted, sale
    else:
        price, old_price = sale, None

    images = p.get("images") or []
    image_url = images[0].get("imageUrl") if images else None

    cat_ids = [category_id]
    for key in ("lCatId", "mCatId", "sCatId", "ssCatId"):
        val = p.get(key)
        if val:
            cat_ids.append(str(val))
    cat_ids = list(dict.fromkeys(cat_ids))

    tags: list[str] = []
    if ratio >= 30 or "SALE" in (p.get("promotionTypes") or []):
        tags.append("today_deal")
    if p.get("isNewProduct"):
        tags.append("new_arrival")

    return {
        "id": nv_mid,
        "name": p.get("productName") or "",
        "subtitle": "",
        "brand": p.get("mallName") or "",
        "price": price,
        "old_price": old_price,
        "discount_percent": ratio,
        "badge": "BEST" if ratio >= 40 else None,
        "rating": round(float(p.get("averageReviewScore") or 0), 1),
        "reviews": int(p.get("totalReviewCount") or 0),
        "blurb": "",
        "tags": list(dict.fromkeys(tags)),
        "image_url": image_url,
        "thumbnail_url": image_url,
        "gallery": [image_url] if image_url else [],
        "category_ids": cat_ids,
        "artwork": _artwork(nv_mid),
    }


def crawl_category(category_id: str, max_pages: int = 1) -> Iterator[dict]:
    cursor = 51  # naver paging starts at cursor=51
    for page in range(1, max_pages + 1):
        data = _fetch_page(category_id, cursor, page)
        if not data:
            break

        inner = data.get("data") or {}
        items = inner.get("data") or []

        for raw in items:
            product = raw.get("card", {}).get("product")
            if product:
                parsed = _parse(product, category_id)
                if parsed:
                    yield parsed

        if not inner.get("hasMore"):
            break

        cursor = inner.get("cursor") or (cursor + _PAGE_SIZE)
        time.sleep(0.3)
