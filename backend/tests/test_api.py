import pytest
from fastapi.testclient import TestClient

from app.config import get_settings
from app.main import app


client = TestClient(app)

ADMIN_KEY = "test-admin-key"


@pytest.fixture
def admin_auth(monkeypatch):
    """Enable the admin surface with a known key and return Basic-auth creds."""
    monkeypatch.setenv("ADMIN_API_KEY", ADMIN_KEY)
    get_settings.cache_clear()
    try:
        yield ("admin", ADMIN_KEY)
    finally:
        get_settings.cache_clear()


def test_health_endpoint() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_home_endpoint_returns_seed_sections() -> None:
    response = client.get("/api/home")

    payload = response.json()

    assert response.status_code == 200
    assert payload["hero"]["title"] == "오늘 사고 싶은 것만, 가볍게 담아두세요."
    assert len(payload["categories"]) == 27
    assert [product["id"] for product in payload["deals"][:3]] == ["83781891828", "90975233454", "90649753925"]
    assert payload["newsletter"]["cadence"] == "weekly"


def test_categories_endpoint() -> None:
    response = client.get("/api/categories")
    payload = response.json()

    assert response.status_code == 200
    assert payload["count"] == 27
    assert {category["id"] for category in payload["items"]} >= {"10000129", "10000122", "10000114"}


def test_products_endpoint_and_filters() -> None:
    all_products = client.get("/api/products")
    home_products = client.get("/api/products", params={"category_id": "10000112"})
    deal_products = client.get("/api/products", params={"tag": "today_deal"})
    section_deals = client.get("/api/products", params={"section": "deals"})
    section_new = client.get("/api/products", params={"section": "new"})

    assert all_products.status_code == 200
    # limit 미지정 시에도 응답을 기본 100개로 제한 — 전체(수만 개) 반환 시 Vercel 서버리스 응답 한도 초과로 500이 난다
    assert all_products.json()["count"] == 100
    assert home_products.status_code == 200
    assert all("10000112" in product["category_ids"] for product in home_products.json()["items"])
    assert deal_products.status_code == 200
    assert {product["id"] for product in deal_products.json()["items"]} >= {"83781891828", "90975233454", "90649753925"}
    assert section_deals.status_code == 200
    assert {product["id"] for product in section_deals.json()["items"]} >= {"83781891828", "90975233454", "90649753925"}
    assert section_new.status_code == 200
    assert {product["id"] for product in section_new.json()["items"]} >= {"90969885411", "91001952511", "90903501594"}


def test_products_default_limit_is_capped_to_avoid_oversized_response() -> None:
    # limit 미지정 시 전체 카탈로그(수만 개, ~25MB)를 반환하면 서버리스 응답 한도를 초과해 500이 난다.
    default = client.get("/api/products")
    assert default.status_code == 200
    assert default.json()["count"] <= 100
    # 상한(100)을 넘는 명시적 요청은 검증 오류(422)로 막는다.
    over = client.get("/api/products", params={"limit": 1000})
    assert over.status_code == 422


def test_product_detail_endpoint_uses_stable_id() -> None:
    response = client.get("/api/products/89865177420")
    payload = response.json()

    assert response.status_code == 200
    assert payload["id"] == "89865177420"
    assert payload["brand"] == "서플라이루트"
    assert payload["name"] == "건지울른스 슈퍼 파인 메리노울 라운드넥 가디건 - 네이비"


def test_missing_product_returns_404() -> None:
    response = client.get("/api/products/not-a-product")

    assert response.status_code == 404


def test_search_endpoint() -> None:
    response = client.get("/api/search", params={"q": "선풍기"})
    payload = response.json()

    assert response.status_code == 200
    assert payload["query"] == "선풍기"
    assert payload["count"] >= 1
    assert payload["items"][0]["id"] == "83142579120"


def test_trending_and_suggestions_endpoints() -> None:
    trending = client.get("/api/search/trending")
    suggestions = client.get("/api/search/suggestions", params={"q": "무선"})

    assert trending.status_code == 200
    assert trending.json()["count"] >= 10
    assert suggestions.status_code == 200
    assert any("무선" in item for item in suggestions.json()["items"])


def test_newsletter_endpoints() -> None:
    info = client.get("/api/newsletter")
    subscription = client.post("/api/newsletter/subscribe", json={"email": "Shopper@Example.com"})
    invalid = client.post("/api/newsletter/subscribe", json={"email": "not-an-email"})

    assert info.status_code == 200
    assert info.json()["title"] == "조용한 신상품을 가장 먼저."
    assert subscription.status_code == 202
    assert subscription.json() == {
        "accepted": True,
        "email": "shopper@example.com",
        "message": "구독 요청을 받았습니다. 이 MVP는 이메일을 저장하지 않습니다.",
    }
    assert invalid.status_code == 422


def test_order_endpoint_accepts_selected_cart_lines() -> None:
    response = client.post(
        "/api/orders",
        json={
            "items": [
                {"product_id": "89865177420", "quantity": 2},
                {"product_id": "83781891828", "quantity": 1},
            ]
        },
    )

    payload = response.json()

    assert response.status_code == 202
    assert payload["accepted"] is True
    assert payload["item_count"] == 3
    assert payload["total_price"] == (142400 * 2) + 49900
    assert payload["items"][0]["product_id"] == "89865177420"


def test_created_orders_persist_and_are_listed(admin_auth) -> None:
    created = client.post(
        "/api/orders", json={"items": [{"product_id": "89865177420", "quantity": 1}]}
    )
    order_id = created.json()["order_id"]

    listed = client.get("/api/orders", auth=admin_auth)
    assert listed.status_code == 200
    assert order_id in {order["order_id"] for order in listed.json()}


def test_order_endpoint_rejects_invalid_or_missing_product() -> None:
    invalid = client.post("/api/orders", json={"items": []})
    missing = client.post("/api/orders", json={"items": [{"product_id": "missing", "quantity": 1}]})

    assert invalid.status_code == 422
    assert missing.status_code == 404


def test_admin_page_and_seed_management_endpoints(admin_auth) -> None:
    admin = client.get("/admin", auth=admin_auth)
    seed = client.get("/api/manage/seed", auth=admin_auth)
    payload = seed.json()
    original_title = payload["newsletter"]["title"]
    try:
        payload["newsletter"]["title"] = "관리페이지 저장 테스트"
        saved = client.post("/api/manage/seed", json=payload, auth=admin_auth)

        assert admin.status_code == 200
        assert "text/html" in admin.headers["content-type"]
        assert "Dogu Admin" in admin.text
        assert seed.status_code == 200
        assert saved.status_code == 200
        assert saved.json()["newsletter"]["title"] == "관리페이지 저장 테스트"
    finally:
        payload["newsletter"]["title"] = original_title
        client.post("/api/manage/seed", json=payload, auth=admin_auth)


def test_admin_surface_requires_authentication(admin_auth) -> None:
    # No credentials -> 401 with a Basic challenge.
    for path in ("/admin", "/api/manage/seed"):
        unauth = client.get(path)
        assert unauth.status_code == 401
        assert unauth.headers.get("www-authenticate") == "Basic"

    # Wrong password is rejected.
    assert client.get("/api/manage/seed", auth=("admin", "wrong")).status_code == 401
    # Listing orders is admin-only too.
    assert client.get("/api/orders").status_code == 401
    assert client.get("/api/orders", auth=admin_auth).status_code == 200


def test_admin_disabled_when_key_unset() -> None:
    # With ADMIN_API_KEY unset the whole admin surface fails closed (503),
    # never falling back to being world-writable.
    get_settings.cache_clear()
    try:
        assert client.get("/api/manage/seed", auth=("admin", "anything")).status_code == 503
    finally:
        get_settings.cache_clear()


def test_cors_allows_flutter_web_localhost() -> None:
    response = client.options(
        "/api/products",
        headers={
            "Origin": "http://localhost:8080",
            "Access-Control-Request-Method": "GET",
        },
    )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://localhost:8080"
