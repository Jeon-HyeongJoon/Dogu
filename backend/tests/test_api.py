from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_health_endpoint() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_home_endpoint_returns_seed_sections() -> None:
    response = client.get("/api/home")

    payload = response.json()

    assert response.status_code == 200
    assert payload["hero"]["title"] == "조용한 것들이 가장 시끄럽게 욕망된다."
    assert len(payload["categories"]) == 6
    assert [product["id"] for product in payload["deals"]] == ["p02", "p06", "p07"]
    assert payload["newsletter"]["cadence"] == "weekly"


def test_categories_endpoint() -> None:
    response = client.get("/api/categories")
    payload = response.json()

    assert response.status_code == 200
    assert payload["count"] == 6
    assert {category["id"] for category in payload["items"]} >= {"gadget", "home", "fashion"}


def test_products_endpoint_and_filters() -> None:
    all_products = client.get("/api/products")
    home_products = client.get("/api/products", params={"category_id": "home"})
    deal_products = client.get("/api/products", params={"tag": "today_deal"})
    section_deals = client.get("/api/products", params={"section": "deals"})
    section_new = client.get("/api/products", params={"section": "new"})

    assert all_products.status_code == 200
    assert all_products.json()["count"] == 12
    assert home_products.status_code == 200
    assert all("home" in product["category_ids"] for product in home_products.json()["items"])
    assert deal_products.status_code == 200
    assert {product["id"] for product in deal_products.json()["items"]} >= {"p02", "p06", "p07"}
    assert section_deals.status_code == 200
    assert {product["id"] for product in section_deals.json()["items"]} >= {"p02", "p06", "p07"}
    assert section_new.status_code == 200
    assert {product["id"] for product in section_new.json()["items"]} >= {"p01", "p03", "p04", "p08", "p11", "p12"}


def test_product_detail_endpoint_uses_stable_id() -> None:
    response = client.get("/api/products/p01")
    payload = response.json()

    assert response.status_code == 200
    assert payload["id"] == "p01"
    assert payload["brand"] == "NovaTech"
    assert payload["name"] == "폴더블 무선 충전 거치대 3 in 1"


def test_missing_product_returns_404() -> None:
    response = client.get("/api/products/not-a-product")

    assert response.status_code == 404


def test_search_endpoint() -> None:
    response = client.get("/api/search", params={"q": "선풍기"})
    payload = response.json()

    assert response.status_code == 200
    assert payload["query"] == "선풍기"
    assert payload["count"] >= 1
    assert payload["items"][0]["id"] == "p04"


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
                {"product_id": "p01", "quantity": 2},
                {"product_id": "p02", "quantity": 1},
            ]
        },
    )

    payload = response.json()

    assert response.status_code == 202
    assert payload["accepted"] is True
    assert payload["item_count"] == 3
    assert payload["total_price"] == (24900 * 2) + 12900
    assert payload["items"][0]["product_id"] == "p01"


def test_order_endpoint_rejects_invalid_or_missing_product() -> None:
    invalid = client.post("/api/orders", json={"items": []})
    missing = client.post("/api/orders", json={"items": [{"product_id": "missing", "quantity": 1}]})

    assert invalid.status_code == 422
    assert missing.status_code == 404


def test_admin_page_and_seed_management_endpoints() -> None:
    admin = client.get("/admin")
    seed = client.get("/api/manage/seed")
    payload = seed.json()
    original_title = payload["newsletter"]["title"]
    try:
        payload["newsletter"]["title"] = "관리페이지 저장 테스트"
        saved = client.post("/api/manage/seed", json=payload)

        assert admin.status_code == 200
        assert "text/html" in admin.headers["content-type"]
        assert "Dogu Admin" in admin.text
        assert seed.status_code == 200
        assert saved.status_code == 200
        assert saved.json()["newsletter"]["title"] == "관리페이지 저장 테스트"
    finally:
        payload["newsletter"]["title"] = original_title
        client.post("/api/manage/seed", json=payload)


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
