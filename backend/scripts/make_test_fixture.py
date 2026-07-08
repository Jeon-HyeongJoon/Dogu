"""
CI/테스트용 결정론적 fixture DB 생성 스크립트.

26MB짜리 전체 크롤 DB(app/data/dogu.db, git 제외)는 CI에 존재하지 않는다.
테스트(tests/test_api.py)는 특정 상품 ID와 행 순서(rowid 기반 정렬)에 의존하므로,
전체 DB에서 불필요한 행만 DELETE 하여 남은 행의 rowid(=상대 순서)를 보존한
작은 fixture(app/data/test_fixture.db)를 만든다. 이 파일만 git에 커밋하고
CI 에서 DOGU_DB_PATH 로 지정한다.

로컬에서 dogu.db 가 갱신되면 다시 실행해 fixture 를 재생성한다.
"""
import shutil
import sqlite3
import sys
from pathlib import Path

DATA = Path(__file__).parent.parent / "app" / "data"
SRC = DATA / "dogu.db"
DST = DATA / "test_fixture.db"

# tests/test_api.py 가 명시적으로 참조하는 상품 ID (반드시 포함)
REFERENCED = [
    "83142579120",  # 검색 '선풍기' 첫 결과
    "83781891828",  # today_deal[0]
    "90975233454",  # today_deal[1]
    "90649753925",  # today_deal[2]
    "89865177420",  # 상세/주문 대상
    "90969885411",  # new_arrival[0]
    "91001952511",  # new_arrival[1]
    "90903501594",  # new_arrival[2]
]

FILLER_TARGET = 120  # /api/products 기본 limit(100) 검증을 위해 넉넉히 확보


def main() -> None:
    if not SRC.exists():
        print(f"ERROR: {SRC} 없음. 크롤러/DB 빌드를 먼저 실행하세요.", file=sys.stderr)
        sys.exit(1)

    shutil.copy2(SRC, DST)
    conn = sqlite3.connect(DST)
    conn.row_factory = sqlite3.Row

    keep: set[str] = set(REFERENCED)

    # 카테고리 필터 테스트(category_id=10000112)를 위한 최소 rowid 상품 포함
    row = conn.execute(
        """
        SELECT p.id FROM products p
        JOIN product_categories pc ON p.id = pc.product_id
        WHERE pc.category_id = '10000112'
        ORDER BY p.rowid LIMIT 1
        """
    ).fetchone()
    if row:
        keep.add(row["id"])

    # 필러: 순서 의존 쿼리(today_deal / new_arrival / '선풍기')를 교란하지 않는
    # 낮은 rowid 상품들로 100개 이상 확보. 태그/검색어에 걸리지 않는 행만 선택한다.
    filler = conn.execute(
        """
        SELECT id FROM products
        WHERE tags NOT LIKE '%"today_deal"%'
          AND tags NOT LIKE '%"new_arrival"%'
          AND lower(name) NOT LIKE '%선풍기%'
          AND lower(brand) NOT LIKE '%선풍기%'
        ORDER BY rowid
        LIMIT ?
        """,
        (FILLER_TARGET,),
    ).fetchall()
    keep.update(r["id"] for r in filler)

    keep_list = sorted(keep)
    placeholders = ",".join("?" * len(keep_list))
    conn.execute(f"DELETE FROM products WHERE id NOT IN ({placeholders})", keep_list)
    conn.execute(
        f"DELETE FROM product_categories WHERE product_id NOT IN ({placeholders})",
        keep_list,
    )
    # 카테고리 27개(parent)는 전부 유지 — 삭제하지 않는다.
    conn.commit()
    conn.isolation_level = None
    conn.execute("VACUUM")

    n_prods = conn.execute("SELECT COUNT(*) FROM products").fetchone()[0]
    n_cats = conn.execute(
        "SELECT COUNT(*) FROM categories WHERE parent_id IS NULL"
    ).fetchone()[0]
    size_kb = DST.stat().st_size / 1024
    conn.close()
    print(f"완료: 상품 {n_prods}개, 카테고리(parent) {n_cats}개 → {DST} ({size_kb:.0f} KB)")


if __name__ == "__main__":
    main()
