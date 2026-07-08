from functools import cached_property
from uuid import uuid4

from app import state
from app.database import db_exists, db_get_product, db_list_categories, db_list_products, db_search_products
from app.models import Category, HomeResponse, OrderCreateRequest, OrderLineResponse, OrderResponse, Product, SeedData
from app.seed import load_seed_data, save_seed_data


class CatalogRepository:
    @property
    def orders(self) -> list[OrderResponse]:
        return [OrderResponse.model_validate(row) for row in state.list_orders()]

    @cached_property
    def data(self) -> SeedData:
        return load_seed_data()

    @cached_property
    def products_by_id(self) -> dict[str, Product]:
        return {product.id: product for product in self.data.products}

    @cached_property
    def categories_by_id(self) -> dict[str, Category]:
        return {category.id: category for category in self.data.categories}

    def list_categories(self) -> list[Category]:
        if db_exists():
            return db_list_categories()
        return self.data.categories

    def list_products(
        self,
        category_id: str | None = None,
        tag: str | None = None,
        section: str | None = None,
        limit: int | None = None,
    ) -> list[Product]:
        if db_exists():
            return db_list_products(category_id=category_id, tag=tag, section=section, limit=limit)
        products = self.data.products
        if category_id:
            products = [p for p in products if category_id in p.category_ids]
        if section:
            mapped = {"deals": "today_deal", "new": "new_arrival"}.get(section)
            if mapped:
                products = [p for p in products if mapped in p.tags]
        if tag:
            products = [p for p in products if tag in p.tags]
        if limit is not None:
            products = products[:limit]
        return products

    def get_product(self, product_id: str) -> Product | None:
        if db_exists():
            return db_get_product(product_id)
        return self.products_by_id.get(product_id)

    def build_home(self) -> HomeResponse:
        home = self.data.home
        if db_exists():
            categories = db_list_categories()
            deals = db_list_products(section="deals", limit=10)
            new_arrivals = db_list_products(section="new", limit=10)
            all_products = db_list_products(limit=1)
            featured = all_products[0] if all_products else None
            # Seed collection product_ids reference the p01-style seed catalog,
            # not the DB's real product ids, so they never resolve here. Back the
            # editorial collections with real DB products instead of returning
            # empty lists (previously home collections were blank in DB mode).
            collection_products = self._db_collection_products(len(home.collections))
        else:
            categories = self.data.categories
            deals = self.products_for_ids(home.deal_product_ids)
            new_arrivals = self.products_for_ids(home.new_product_ids)
            featured = self.get_product(home.featured_product_id)
            collection_products = [self.products_for_ids(c.product_ids) for c in home.collections]
        return HomeResponse(
            hero=home.hero,
            ticker=home.ticker,
            nav=home.nav,
            categories=categories,
            deals=deals,
            new_arrivals=new_arrivals,
            featured_product=featured,
            editorial=home.editorial,
            brands=home.brands,
            collections=[
                {
                    "id": c.id,
                    "title": c.title,
                    "subtitle": c.subtitle,
                    "tone": c.tone,
                    "accent": c.accent,
                    "products": collection_products[index],
                }
                for index, c in enumerate(home.collections)
            ],
            newsletter=self.data.newsletter,
        )

    def products_for_ids(self, product_ids: list[str]) -> list[Product]:
        return [product for product_id in product_ids if (product := self.get_product(product_id))]

    def _db_collection_products(self, count: int, per: int = 6) -> list[list[Product]]:
        """Back each editorial collection with a distinct slice of real DB
        products (deterministic rowid order), since seed collection ids do not
        exist in the DB."""
        if count <= 0:
            return []
        pool = db_list_products(limit=count * per)
        return [pool[i * per:(i + 1) * per] for i in range(count)]

    def search_products(self, query: str | None = None, category_id: str | None = None, limit: int = 20) -> list[Product]:
        if db_exists():
            return db_search_products(query=query, category_id=category_id, limit=limit)
        products = self.list_products(category_id=category_id)
        normalized_query = (query or "").strip().lower()
        if normalized_query:
            products = [product for product in products if self._matches_product(product, normalized_query)]
        return products[:limit]

    def suggestions(self, query: str | None = None, limit: int = 8) -> list[str]:
        values = [
            *self.data.suggestions,
            *(term.term for term in self.data.trending),
            *(category.label for category in self.data.categories),
            *(product.brand for product in self.data.products),
            *(product.name for product in self.data.products),
        ]
        unique_values = list(dict.fromkeys(values))
        normalized_query = (query or "").strip().lower()
        if normalized_query:
            unique_values = [value for value in unique_values if normalized_query in value.lower()]
        return unique_values[:limit]

    def _matches_product(self, product: Product, normalized_query: str) -> bool:
        category_labels = [self.categories_by_id[category_id].label for category_id in product.category_ids if category_id in self.categories_by_id]
        haystack = " ".join(
            [
                product.id,
                product.name,
                product.subtitle,
                product.brand,
                product.blurb,
                *product.tags,
                *category_labels,
            ]
        ).lower()
        return normalized_query in haystack

    def reset_cache(self) -> None:
        for attr in ("data", "products_by_id", "categories_by_id"):
            self.__dict__.pop(attr, None)

    def save_seed(self, data: SeedData) -> None:
        save_seed_data(data)
        self.reset_cache()

    def create_order(self, payload: OrderCreateRequest) -> OrderResponse:
        lines: list[OrderLineResponse] = []
        total_price = 0
        item_count = 0
        for item in payload.items:
            product = self.get_product(item.product_id)
            if product is None:
                raise KeyError(item.product_id)
            line_total = product.price * item.quantity
            total_price += line_total
            item_count += item.quantity
            lines.append(
                OrderLineResponse(
                    product_id=product.id,
                    name=product.name,
                    quantity=item.quantity,
                    unit_price=product.price,
                    line_total=line_total,
                )
            )
        order = OrderResponse(
            order_id=f"ord_{uuid4().hex[:10]}",
            accepted=True,
            items=lines,
            item_count=item_count,
            total_price=total_price,
            message="주문이 접수되었습니다.",
        )
        state.add_order(order.order_id, order.model_dump(mode="json"))
        return order


repository = CatalogRepository()
