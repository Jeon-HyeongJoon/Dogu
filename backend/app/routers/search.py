from typing import Annotated

from fastapi import APIRouter, Query

from app.models import SearchResponse, SuggestionResponse, TrendingSearchResponse
from app.repository import repository


router = APIRouter(prefix="/api/search", tags=["search"])


@router.get("", response_model=SearchResponse)
def search_products(
    q: Annotated[str | None, Query(min_length=1)] = None,
    category_id: str | None = None,
    limit: Annotated[int, Query(ge=1, le=50)] = 20,
) -> SearchResponse:
    items = repository.search_products(query=q, category_id=category_id, limit=limit)
    suggestions = repository.suggestions(query=q, limit=6)
    return SearchResponse(query=q, items=items, count=len(items), suggestions=suggestions)


@router.get("/trending", response_model=TrendingSearchResponse)
def trending_searches() -> TrendingSearchResponse:
    items = repository.data.trending
    return TrendingSearchResponse(items=items, count=len(items))


@router.get("/suggestions", response_model=SuggestionResponse)
def search_suggestions(
    q: Annotated[str | None, Query(min_length=1)] = None,
    limit: Annotated[int, Query(ge=1, le=20)] = 8,
) -> SuggestionResponse:
    items = repository.suggestions(query=q, limit=limit)
    return SuggestionResponse(items=items, count=len(items))
