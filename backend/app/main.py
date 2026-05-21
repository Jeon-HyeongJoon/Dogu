from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import admin, catalog, health, home, newsletter, orders, proxy, search


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="Seed-data FastAPI backend for the Dogu shopping app.",
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST", "OPTIONS"],
        allow_headers=["*"],
    )
    app.include_router(health.router)
    app.include_router(home.router)
    app.include_router(catalog.router)
    app.include_router(search.router)
    app.include_router(newsletter.router)
    app.include_router(orders.router)
    app.include_router(admin.router)
    app.include_router(proxy.router)
    return app


app = create_app()
