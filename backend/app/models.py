from pydantic import BaseModel, Field

# Single source of truth mapping the public `section` query values to the seed/DB
# product tags they select. Used by both the DB query layer (database.py) and the
# seedstore fallback filter (repository.py), so a section is defined in one place.
SECTION_TAGS: dict[str, str] = {"deals": "today_deal", "new": "new_arrival"}


class ProductArtwork(BaseModel):
    hue: int = Field(ge=0, le=360)
    saturation: int = Field(ge=0, le=100)
    lightness: int = Field(ge=0, le=100)
    mono: str
    motif: str


class Category(BaseModel):
    id: str
    label: str
    count: int = Field(ge=0)
    description: str
    tone: str
    featured: bool = False
    image_url: str | None = None


class Product(BaseModel):
    id: str
    name: str
    subtitle: str
    brand: str
    category_ids: list[str]
    price: int = Field(ge=0)
    old_price: int | None = Field(default=None, ge=0)
    discount_percent: int = Field(ge=0, le=100)
    badge: str | None = None
    rating: float = Field(ge=0, le=5)
    reviews: int = Field(ge=0)
    blurb: str
    tags: list[str] = Field(default_factory=list)
    image_url: str | None = None
    thumbnail_url: str | None = None
    gallery: list[str] = Field(default_factory=list)
    artwork: ProductArtwork


class HeroContent(BaseModel):
    eyebrow: str
    title: str
    subtitle: str
    primary_action: str
    secondary_action: str
    stats: list[dict[str, str]]


class Collection(BaseModel):
    id: str
    title: str
    subtitle: str
    tone: str
    accent: str
    product_ids: list[str]


class HomeContent(BaseModel):
    hero: HeroContent
    ticker: list[str]
    nav: list[str]
    deal_product_ids: list[str]
    new_product_ids: list[str]
    featured_product_id: str
    editorial: dict[str, str]
    brands: list[str]
    collections: list[Collection]


class SearchTerm(BaseModel):
    term: str
    movement: str


class NewsletterContent(BaseModel):
    eyebrow: str
    title: str
    description: str
    cadence: str
    disclaimer: str


class SeedData(BaseModel):
    categories: list[Category]
    products: list[Product]
    home: HomeContent
    trending: list[SearchTerm]
    suggestions: list[str]
    newsletter: NewsletterContent


class ProductListResponse(BaseModel):
    items: list[Product]
    count: int


class CategoryListResponse(BaseModel):
    items: list[Category]
    count: int


class HomeResponse(BaseModel):
    hero: HeroContent
    ticker: list[str]
    nav: list[str]
    categories: list[Category]
    deals: list[Product]
    new_arrivals: list[Product]
    featured_product: Product | None
    editorial: dict[str, str]
    brands: list[str]
    collections: list[dict[str, object]]
    newsletter: NewsletterContent


class SearchResponse(BaseModel):
    query: str | None
    items: list[Product]
    count: int
    suggestions: list[str]


class TrendingSearchResponse(BaseModel):
    items: list[SearchTerm]
    count: int


class SuggestionResponse(BaseModel):
    items: list[str]
    count: int


class NewsletterSubscribeRequest(BaseModel):
    email: str = Field(min_length=5, max_length=254)


class NewsletterSubscribeResponse(BaseModel):
    accepted: bool
    email: str
    message: str


class OrderLineRequest(BaseModel):
    product_id: str
    quantity: int = Field(ge=1)


class OrderCreateRequest(BaseModel):
    items: list[OrderLineRequest] = Field(min_length=1)


class OrderLineResponse(BaseModel):
    product_id: str
    name: str
    quantity: int
    unit_price: int
    line_total: int


class OrderResponse(BaseModel):
    order_id: str
    accepted: bool
    items: list[OrderLineResponse]
    item_count: int
    total_price: int
    message: str
