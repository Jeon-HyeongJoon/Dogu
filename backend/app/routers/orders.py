from fastapi import APIRouter, HTTPException

from app.models import OrderCreateRequest, OrderResponse
from app.repository import repository


router = APIRouter(prefix="/api/orders", tags=["orders"])


@router.get("", response_model=list[OrderResponse])
def list_orders() -> list[OrderResponse]:
    return repository.orders


@router.post("", response_model=OrderResponse, status_code=202)
def create_order(payload: OrderCreateRequest) -> OrderResponse:
    try:
        return repository.create_order(payload)
    except KeyError as error:
        raise HTTPException(status_code=404, detail=f"Product not found: {error.args[0]}") from error
