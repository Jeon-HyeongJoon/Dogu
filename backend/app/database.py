import json
import os
import sqlite3
from functools import lru_cache
from pathlib import Path
from typing import NamedTuple

from app.models import SECTION_TAGS, Category, Product, ProductArtwork

_DEFAULT_DB = Path(__file__).parent / "data" / "dogu.db"
DB_PATH = Path(os.environ.get("DOGU_DB_PATH", str(_DEFAULT_DB)))

# 메인화면 '카테고리' 칸 — 수요 순위로 자동 선정하고 편집 조정(제외·고정)을 더한다.
# 수요 = 최상위 카테고리 자체를 크롤링한 상위 상품들의 누적 리뷰 합. 크롤러가 카테고리마다
# 같은 수(상위 100개)를 담으므로 카테고리끼리 비교할 수 있다. 반대로 상품 수는 그 한도
# 때문에 전부 ~100이라 공급 지표가 되지 못한다.
HOME_CATEGORY_SLOTS = 9
HOME_CATEGORY_EXCLUDED = frozenset({"10000126"})  # 공구 — 메인에서 뺀다
HOME_CATEGORY_PINNED = ("10000107", "10000108")  # 여성의류, 남성의류 — 순위와 무관하게 메인 끝 칸


class CategoryGroup(NamedTuple):
    label: str
    member_ids: tuple[str, ...]


# 하나로 묶어 보여줄 최상위 카테고리. 크롤링 원본(네이버)은 식품을 셋으로 나눠 두지만
# 쇼핑몰에서는 한 품목이다 — 카테고리 목록에는 묶음만 나오고, 묶음 id로 상품을 조회하면
# 멤버 전부에서 고른다. 묶음의 수요는 멤버 수요의 합.
CATEGORY_GROUPS: dict[str, CategoryGroup] = {
    "food": CategoryGroup("식품", ("10006530", "10000114", "10000115")),  # 신선식품 · 가공식품 · 건강식품
}
_GROUP_OF = {member_id: group_id for group_id, group in CATEGORY_GROUPS.items() for member_id in group.member_ids}


def db_exists() -> bool:
    return DB_PATH.exists()


def _conn() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def _cat_ids_for(conn: sqlite3.Connection, product_ids: list[str]) -> dict[str, list[str]]:
    if not product_ids:
        return {}
    placeholders = ",".join("?" * len(product_ids))
    rows = conn.execute(
        f"SELECT product_id, category_id FROM product_categories WHERE product_id IN ({placeholders})",
        product_ids,
    ).fetchall()
    result: dict[str, list[str]] = {pid: [] for pid in product_ids}
    for row in rows:
        result[row["product_id"]].append(row["category_id"])
    return result


def _category_condition(category_id: str) -> tuple[str, list[str]]:
    """category_id(묶음 id 포함)로 상품을 거르는 product_categories 조건과 파라미터."""
    group = CATEGORY_GROUPS.get(category_id)
    if group is None:
        return "pc.category_id = ?", [category_id]
    placeholders = ",".join("?" * len(group.member_ids))
    return f"pc.category_id IN ({placeholders})", list(group.member_ids)


# 묶음은 리뷰 많은 순으로 준다 — 정렬이 없으면 한 멤버(신선식품)가 100개를 거의 다 차지한다.
_GROUP_ORDER = " ORDER BY p.reviews DESC"


def _to_product(row: sqlite3.Row, category_ids: list[str]) -> Product:
    return Product(
        id=row["id"],
        name=row["name"],
        subtitle=row["subtitle"] or "",
        brand=row["brand"],
        price=row["price"],
        old_price=row["old_price"],
        discount_percent=row["discount_percent"],
        badge=row["badge"],
        rating=row["rating"],
        reviews=row["reviews"],
        blurb=row["blurb"] or "",
        tags=json.loads(row["tags"] or "[]"),
        image_url=row["image_url"],
        thumbnail_url=row["thumbnail_url"],
        gallery=json.loads(row["gallery"] or "[]"),
        category_ids=category_ids,
        artwork=ProductArtwork(
            hue=row["artwork_hue"],
            saturation=row["artwork_saturation"],
            lightness=row["artwork_lightness"],
            mono=row["artwork_mono"],
            motif=row["artwork_motif"],
        ),
    )


@lru_cache(maxsize=4)
def _home_category_ranks(db_path: str) -> dict[str, int]:
    """메인 노출 카테고리 id(묶음 id 포함) → 노출 순위(1부터, 수요 순 + 고정은 끝).

    배포 DB는 읽기 전용이라 경로별로 한 번만 계산한다(실 DB에서 ~100ms).
    """
    with _conn() as conn:
        rows = conn.execute(
            """
            SELECT c.id, c.label, COALESCE(SUM(p.reviews), 0) AS demand
            FROM categories c
            LEFT JOIN product_categories pc ON pc.category_id = c.id
            LEFT JOIN products p ON p.id = pc.product_id
            WHERE c.parent_id IS NULL
            GROUP BY c.id
            """
        ).fetchall()
    demand: dict[str, int] = {}
    labels: dict[str, str] = {}
    for row in rows:
        key = _GROUP_OF.get(row["id"], row["id"])
        demand[key] = demand.get(key, 0) + row["demand"]
        labels[key] = CATEGORY_GROUPS[key].label if key in CATEGORY_GROUPS else row["label"]
    ids = sorted(demand, key=lambda key: (-demand[key], labels[key]))
    pinned = [category_id for category_id in HOME_CATEGORY_PINNED if category_id in ids]
    ranked = [category_id for category_id in ids if category_id not in HOME_CATEGORY_EXCLUDED and category_id not in pinned]
    picks = ranked[: HOME_CATEGORY_SLOTS - len(pinned)] + pinned
    return {category_id: rank for rank, category_id in enumerate(picks, 1)}


def db_list_categories() -> list[Category]:
    home_ranks = _home_category_ranks(str(DB_PATH))
    with _conn() as conn:
        rows = conn.execute("SELECT * FROM categories WHERE parent_id IS NULL").fetchall()
    categories = [
        Category(
            id=row["id"],
            label=row["label"],
            count=row["count"],
            description=row["description"] or "",
            tone=row["tone"] or "#6b6b6b",
            featured=row["id"] in home_ranks,
            home_rank=home_ranks.get(row["id"]),
            image_url=row["image_url"],
        )
        for row in rows
        if row["id"] not in _GROUP_OF
    ]
    for group_id, group in CATEGORY_GROUPS.items():
        members = sorted(
            (row for row in rows if row["id"] in group.member_ids),
            key=lambda row: group.member_ids.index(row["id"]),
        )
        if not members:
            continue
        categories.append(
            Category(
                id=group_id,
                label=group.label,
                count=sum(row["count"] for row in members),
                description=" · ".join(row["label"] for row in members),
                tone="#6b6b6b",
                featured=group_id in home_ranks,
                home_rank=home_ranks.get(group_id),
            )
        )
    return sorted(categories, key=lambda category: category.label)


@lru_cache(maxsize=4)
def db_home_stats(db_path: str) -> tuple[dict[str, str], ...]:
    """메인 히어로 숫자 — seed의 고정값(218 · 14 · −42%) 대신 DB에서 계산한다.

    신상품 = new_arrival 태그 상품 수, 브랜드 = 서로 다른 브랜드 수,
    평균 할인 = 할인 중인 상품의 평균 할인율. 배포 DB는 읽기 전용이라 한 번만 계산한다.
    """
    with _conn() as conn:
        new_count = conn.execute("SELECT COUNT(*) FROM products WHERE tags LIKE ?", ('%"new_arrival"%',)).fetchone()[0]
        brand_count = conn.execute("SELECT COUNT(DISTINCT brand) FROM products WHERE trim(brand) <> ''").fetchone()[0]
        avg_discount = conn.execute("SELECT AVG(discount_percent) FROM products WHERE discount_percent > 0").fetchone()[0]
    return (
        {"value": f"{new_count:,}", "label": "신상품"},
        {"value": f"{brand_count:,}", "label": "브랜드"},
        {"value": f"\u2212{round(avg_discount or 0)}%", "label": "평균 할인"},
    )


@lru_cache(maxsize=4)
def db_home_brands(db_path: str, limit: int) -> tuple[str, ...]:
    """검색 탭 '추천 브랜드' — 메인 카테고리 순서대로 각 카테고리에서 리뷰가 가장 많은 브랜드.

    전체 리뷰 순으로만 뽑으면 식품·건강 브랜드가 다 차지해서 카테고리마다 하나씩 고른다.
    실제 상품의 브랜드라 누르면 반드시 검색 결과가 나온다(예전 seed 검색어는 0개가 많았다).
    """
    ranks = _home_category_ranks(db_path)
    brands: list[str] = []
    with _conn() as conn:
        for category_id in sorted(ranks, key=ranks.__getitem__):
            condition, params = _category_condition(category_id)
            row = conn.execute(
                "SELECT p.brand FROM products p JOIN product_categories pc ON pc.product_id = p.id "
                f"WHERE {condition} AND trim(p.brand) <> '' GROUP BY p.brand ORDER BY SUM(p.reviews) DESC LIMIT 1",
                params,
            ).fetchone()
            if row and row["brand"] not in brands:
                brands.append(row["brand"])
            if len(brands) >= limit:
                break
    return tuple(brands)


def db_list_products(
    category_id: str | None = None,
    tag: str | None = None,
    section: str | None = None,
    limit: int | None = None,
) -> list[Product]:
    section_tag = SECTION_TAGS.get(section or "")
    effective_tag = section_tag or tag

    with _conn() as conn:
        sql = "SELECT DISTINCT p.* FROM products p"
        params: list = []

        if category_id:
            sql += " JOIN product_categories pc ON p.id = pc.product_id"

        conditions: list[str] = []
        if category_id:
            condition, category_params = _category_condition(category_id)
            conditions.append(condition)
            params.extend(category_params)
        if effective_tag:
            conditions.append(f"p.tags LIKE ?")
            params.append(f'%"{effective_tag}"%')

        if conditions:
            sql += " WHERE " + " AND ".join(conditions)

        if category_id in CATEGORY_GROUPS:
            sql += _GROUP_ORDER

        if limit:
            sql += f" LIMIT {limit}"

        rows = conn.execute(sql, params).fetchall()
        if not rows:
            return []

        ids = [r["id"] for r in rows]
        cat_map = _cat_ids_for(conn, ids)
        return [_to_product(r, cat_map.get(r["id"], [])) for r in rows]


def db_get_product(product_id: str) -> Product | None:
    with _conn() as conn:
        row = conn.execute("SELECT * FROM products WHERE id = ?", (product_id,)).fetchone()
        if not row:
            return None
        cat_rows = conn.execute(
            "SELECT category_id FROM product_categories WHERE product_id = ?", (product_id,)
        ).fetchall()
        return _to_product(row, [r["category_id"] for r in cat_rows])


def db_search_products(query: str | None = None, category_id: str | None = None, limit: int = 20) -> list[Product]:
    with _conn() as conn:
        sql = "SELECT DISTINCT p.* FROM products p"
        params: list = []

        if category_id:
            sql += " JOIN product_categories pc ON p.id = pc.product_id"

        conditions: list[str] = []
        if category_id:
            condition, category_params = _category_condition(category_id)
            conditions.append(condition)
            params.extend(category_params)
        if query:
            q = f"%{query.strip().lower()}%"
            # Match the seed-path search fields (name/brand/subtitle/blurb/tags)
            # so both data sources return consistent results for the same query.
            conditions.append(
                "(lower(p.name) LIKE ? OR lower(p.brand) LIKE ? "
                "OR lower(p.subtitle) LIKE ? OR lower(p.blurb) LIKE ? "
                "OR lower(p.tags) LIKE ?)"
            )
            params.extend([q, q, q, q, q])

        if conditions:
            sql += " WHERE " + " AND ".join(conditions)

        if category_id in CATEGORY_GROUPS:
            sql += _GROUP_ORDER

        sql += f" LIMIT {limit}"

        rows = conn.execute(sql, params).fetchall()
        if not rows:
            return []

        ids = [r["id"] for r in rows]
        cat_map = _cat_ids_for(conn, ids)
        return [_to_product(r, cat_map.get(r["id"], [])) for r in rows]
