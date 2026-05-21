"""
배포용 슬림 DB 생성 스크립트.
전체 37,000+ 상품 DB 대신 카테고리별 대표 상품 500개만 추출해
약 1MB짜리 app/data/slim.db를 만든다.
"""
import json
import shutil
import sqlite3
import sys
from pathlib import Path

SRC = Path(__file__).parent.parent / "app" / "data" / "dogu.db"
DST = Path(__file__).parent.parent / "app" / "data" / "slim.db"
TARGET = 500


def main() -> None:
    if not SRC.exists():
        print(f"ERROR: {SRC} 없음. 크롤러를 먼저 실행하세요.", file=sys.stderr)
        sys.exit(1)

    shutil.copy2(SRC, DST)
    conn = sqlite3.connect(DST)
    conn.row_factory = sqlite3.Row

    # 카테고리별 고평점 상품 균등 추출
    cats = [r["category_id"] for r in conn.execute(
        "SELECT DISTINCT category_id FROM product_categories"
    ).fetchall()]

    per_cat = max(1, TARGET // max(len(cats), 1))

    keep_ids: set[str] = set()
    for cat_id in cats:
        rows = conn.execute(
            """
            SELECT p.id FROM products p
            JOIN product_categories pc ON p.id = pc.product_id
            WHERE pc.category_id = ?
            ORDER BY p.rating DESC, p.reviews DESC
            LIMIT ?
            """,
            (cat_id, per_cat),
        ).fetchall()
        keep_ids.update(r["id"] for r in rows)
        if len(keep_ids) >= TARGET * 2:
            break

    # 상위 TARGET개로 자름
    keep_list = sorted(keep_ids)[:TARGET]
    placeholders = ",".join("?" * len(keep_list))

    conn.execute(f"DELETE FROM products WHERE id NOT IN ({placeholders})", keep_list)
    conn.execute(f"DELETE FROM product_categories WHERE product_id NOT IN ({placeholders})", keep_list)
    conn.commit()
    conn.isolation_level = None
    conn.execute("VACUUM")

    # 결과 확인
    n_prods = conn.execute("SELECT COUNT(*) FROM products").fetchone()[0]
    size_mb = DST.stat().st_size / 1024 / 1024
    conn.close()

    print(f"완료: {n_prods}개 상품 → {DST} ({size_mb:.1f} MB)")


if __name__ == "__main__":
    main()
