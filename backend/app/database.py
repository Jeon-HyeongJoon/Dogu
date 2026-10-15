import json
import os
import sqlite3
from functools import lru_cache
from pathlib import Path

from app.models import SECTION_TAGS, Category, Product, ProductArtwork

_DEFAULT_DB = Path(__file__).parent / "data" / "dogu.db"
DB_PATH = Path(os.environ.get("DOGU_DB_PATH", str(_DEFAULT_DB)))

# 메인화면 '카테고리' 칸 — 수요 순위로 자동 선정하고 편집 조정(제외·고정)을 더한다.
# 수요 = 최상위 카테고리 자체를 크롤링한 상위 상품들의 누적 리뷰 합. 크롤러가 카테고리마다
# 같은 수(상위 100개)를 담으므로 카테고리끼리 비교할 수 있다. 반대로 상품 수는 그 한도
# 때문에 전부 ~100이라 공급 지표가 되지 못한다.
HOME_CATEGORY_SLOTS = 9
HOME_CATEGORY_EXCLUDED = frozenset({"10000126"})  # 공구 — 메인에서 뺀다
HOME_CATEGORY_PINNED = ("10000107",)  # 여성의류 — 순위와 무관하게 메인 마지막 칸


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
    """메인 노출 카테고리 id → 노출 순위(1부터, 수요 순 + 고정은 끝).

    배포 DB는 읽기 전용이라 경로별로 한 번만 계산한다(실 DB에서 ~100ms).
    """
    with _conn() as conn:
        rows = conn.execute(
            """
            SELECT c.id, COALESCE(SUM(p.reviews), 0) AS demand
            FROM categories c
            LEFT JOIN product_categories pc ON pc.category_id = c.id
            LEFT JOIN products p ON p.id = pc.product_id
            WHERE c.parent_id IS NULL
            GROUP BY c.id
            ORDER BY demand DESC, c.label
            """
        ).fetchall()
    ids = [row["id"] for row in rows]
    pinned = [category_id for category_id in HOME_CATEGORY_PINNED if category_id in ids]
    ranked = [category_id for category_id in ids if category_id not in HOME_CATEGORY_EXCLUDED and category_id not in pinned]
    picks = ranked[: HOME_CATEGORY_SLOTS - len(pinned)] + pinned
    return {category_id: rank for rank, category_id in enumerate(picks, 1)}


def db_list_categories() -> list[Category]:
    home_ranks = _home_category_ranks(str(DB_PATH))
    with _conn() as conn:
        rows = conn.execute(
            "SELECT * FROM categories WHERE parent_id IS NULL ORDER BY label"
        ).fetchall()
        return [
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
        ]


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
            conditions.append("pc.category_id = ?")
            params.append(category_id)
        if effective_tag:
            conditions.append(f"p.tags LIKE ?")
            params.append(f'%"{effective_tag}"%')

        if conditions:
            sql += " WHERE " + " AND ".join(conditions)

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
            conditions.append("pc.category_id = ?")
            params.append(category_id)
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

        sql += f" LIMIT {limit}"

        rows = conn.execute(sql, params).fetchall()
        if not rows:
            return []

        ids = [r["id"] for r in rows]
        cat_map = _cat_ids_for(conn, ids)
        return [_to_product(r, cat_map.get(r["id"], [])) for r in rows]
