import os
from functools import lru_cache
from pathlib import Path

from pydantic import BaseModel, Field


def _cors_origins() -> list[str]:
    env = os.environ.get("CORS_ORIGINS", "")
    if env:
        return [o.strip() for o in env.split(",") if o.strip()]
    return ["*"]


class Settings(BaseModel):
    app_name: str = "Dogu Backend"
    app_version: str = "0.1.0"
    api_prefix: str = "/api"
    seed_path: Path = Field(default_factory=lambda: Path(__file__).parent / "data" / "seed.json")
    cors_origins: list[str] = Field(default_factory=_cors_origins)


@lru_cache
def get_settings() -> Settings:
    return Settings()
