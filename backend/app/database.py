import json
import os
import sqlite3
from pathlib import Path

from app.models import Category, Product, ProductArtwork

_DEFAULT_DB = Path(__file__).parent / "data" / "dogu.db"
DB_PATH = Path(os.environ.get("DOGU_DB_PATH", str(_DEFAULT_DB)))


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


def db_list_categories() -> list[Category]:
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
                featured=bool(row["featured"]),
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
    section_tag = {"deals": "today_deal", "new": "new_arrival"}.get(section or "")
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
            conditions.append("(lower(p.name) LIKE ? OR lower(p.brand) LIKE ?)")
            params.extend([q, q])

        if conditions:
            sql += " WHERE " + " AND ".join(conditions)

        sql += f" LIMIT {limit}"

        rows = conn.execute(sql, params).fetchall()
        if not rows:
            return []

        ids = [r["id"] for r in rows]
        cat_map = _cat_ids_for(conn, ids)
        return [_to_product(r, cat_map.get(r["id"], [])) for r in rows]
