import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from datacrawler.crawler import crawl_category
from datacrawler.db import init_db, save_categories, save_products, update_category_counts

_CATEGORIES_JSON = Path(__file__).parent / "categories.json"


def _collect_all_ids(categories: list[dict]) -> list[tuple[str, str]]:
    """Return [(id, name), ...] for every category and subcategory."""
    result = []
    for cat in categories:
        result.append((cat["id"], cat["name"]))
        for child in cat.get("children") or []:
            result.append((child["id"], child["name"]))
    return result


def main(max_categories: int | None = None, max_pages: int = 2) -> None:
    print("Initializing SQLite DB...")
    init_db()

    with open(_CATEGORIES_JSON, encoding="utf-8") as f:
        top_categories = json.load(f)["categories"]

    print(f"Saving {len(top_categories)} top-level categories to DB...")
    save_categories(top_categories)

    all_ids = _collect_all_ids(top_categories)
    targets = all_ids if max_categories is None else all_ids[:max_categories]
    print(f"크롤링 대상: {len(targets)}개 카테고리 (전체 {len(all_ids)}개 중)")

    total = 0
    for i, (cat_id, cat_name) in enumerate(targets, 1):
        print(f"[{i}/{len(targets)}] {cat_name} (id={cat_id}) 크롤링 중...")
        products = list(crawl_category(cat_id, max_pages=max_pages))
        save_products(products)
        total += len(products)
        print(f"  → {len(products)}개 저장 (누적 {total}개)")

    update_category_counts()
    print(f"\n완료. 총 {total}개 상품 저장됨.")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Naver Shopping 크롤러")
    parser.add_argument("--categories", type=int, default=None, help="크롤링할 카테고리 수 (기본: 전체)")
    parser.add_argument("--pages", type=int, default=2, help="카테고리당 최대 페이지 수 (기본 2, 페이지당 ~50개)")
    args = parser.parse_args()

    main(max_categories=args.categories, max_pages=args.pages)
