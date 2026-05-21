from typing import Annotated

from fastapi import APIRouter, HTTPException, Query

from app.models import CategoryListResponse, Product, ProductListResponse
from app.repository import repository


router = APIRouter(prefix="/api", tags=["catalog"])


@router.get("/categories", response_model=CategoryListResponse)
def list_categories() -> CategoryListResponse:
    categories = repository.list_categories()
    return CategoryListResponse(items=categories, count=len(categories))


@router.get("/products", response_model=ProductListResponse)
def list_products(
    category_id: Annotated[
        str | None,
        Query(description="Filter by category id, for example 'home'."),
    ] = None,
    section: Annotated[
        str | None,
        Query(description="Filter by home section, for example 'deals' or 'new'."),
    ] = None,
    tag: Annotated[
        str | None,
        Query(description="Filter by seed tag, for example 'today_deal'."),
    ] = None,
    limit: Annotated[int | None, Query(ge=1, le=100)] = None,
) -> ProductListResponse:
    products = repository.list_products(category_id=category_id, section=section, tag=tag, limit=limit)
    return ProductListResponse(items=products, count=len(products))


@router.get("/products/{product_id}", response_model=Product)
def get_product(product_id: str) -> Product:
    product = repository.get_product(product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return product
