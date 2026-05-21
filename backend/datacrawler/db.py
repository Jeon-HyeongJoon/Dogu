import json
import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).parent.parent / "app" / "data" / "dogu.db"

_SCHEMA = """
CREATE TABLE IF NOT EXISTS categories (
    id TEXT PRIMARY KEY,
    parent_id TEXT,
    label TEXT NOT NULL,
    count INTEGER DEFAULT 0,
    description TEXT DEFAULT '',
    tone TEXT DEFAULT '',
    featured INTEGER DEFAULT 0,
    image_url TEXT
);

CREATE TABLE IF NOT EXISTS products (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    subtitle TEXT DEFAULT '',
    brand TEXT NOT NULL,
    price INTEGER NOT NULL,
    old_price INTEGER,
    discount_percent INTEGER DEFAULT 0,
    badge TEXT,
    rating REAL DEFAULT 0,
    reviews INTEGER DEFAULT 0,
    blurb TEXT DEFAULT '',
    tags TEXT DEFAULT '[]',
    image_url TEXT,
    thumbnail_url TEXT,
    gallery TEXT DEFAULT '[]',
    artwork_hue INTEGER DEFAULT 0,
    artwork_saturation INTEGER DEFAULT 50,
    artwork_lightness INTEGER DEFAULT 50,
    artwork_mono TEXT DEFAULT '//',
    artwork_motif TEXT DEFAULT 'dots'
);

CREATE TABLE IF NOT EXISTS product_categories (
    product_id TEXT NOT NULL,
    category_id TEXT NOT NULL,
    PRIMARY KEY (product_id, category_id)
);
"""


def get_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with get_conn() as conn:
        conn.executescript(_SCHEMA)


def _collect_categories(categories: list[dict], parent_id: str | None, rows: list) -> None:
    for cat in categories:
        rows.append((cat["id"], parent_id, cat["name"], cat["id"]))
        children = cat.get("children") or []
        if children:
            _collect_categories(children, cat["id"], rows)


def save_categories(categories: list[dict], parent_id: str | None = None) -> None:
    rows: list = []
    _collect_categories(categories, parent_id, rows)
    with get_conn() as conn:
        for row in rows:
            conn.execute(
                """
                INSERT OR REPLACE INTO categories (id, parent_id, label, count, description, tone, featured, image_url)
                VALUES (?, ?, ?, COALESCE((SELECT count FROM categories WHERE id = ?), 0), '', '', 0, NULL)
                """,
                row,
            )


def save_products(products: list[dict]) -> None:
    if not products:
        return
    with get_conn() as conn:
        for p in products:
            art = p["artwork"]
            conn.execute(
                """
                INSERT OR REPLACE INTO products
                (id, name, subtitle, brand, price, old_price, discount_percent, badge,
                 rating, reviews, blurb, tags, image_url, thumbnail_url, gallery,
                 artwork_hue, artwork_saturation, artwork_lightness, artwork_mono, artwork_motif)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                """,
                (
                    p["id"], p["name"], p.get("subtitle", ""), p["brand"],
                    p["price"], p.get("old_price"), p["discount_percent"], p.get("badge"),
                    p["rating"], p["reviews"], p.get("blurb", ""),
                    json.dumps(p.get("tags", []), ensure_ascii=False),
                    p.get("image_url"), p.get("thumbnail_url"),
                    json.dumps(p.get("gallery", []), ensure_ascii=False),
                    art["hue"], art["saturation"], art["lightness"],
                    art["mono"], art["motif"],
                ),
            )
            for cat_id in p.get("category_ids", []):
                conn.execute(
                    "INSERT OR IGNORE INTO product_categories (product_id, category_id) VALUES (?, ?)",
                    (p["id"], cat_id),
                )


def update_category_counts() -> None:
    with get_conn() as conn:
        conn.execute("""
            UPDATE categories SET count = (
                SELECT COUNT(DISTINCT pc.product_id)
                FROM product_categories pc
                WHERE pc.category_id = categories.id
            )
        """)
