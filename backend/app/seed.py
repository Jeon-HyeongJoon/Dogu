from pathlib import Path
import json

from app.config import get_settings
from app.models import SeedData


def get_seed_path() -> Path:
    return get_settings().seed_path


def load_seed_data(path: Path | None = None) -> SeedData:
    seed_path = path or get_seed_path()
    return SeedData.model_validate_json(seed_path.read_text(encoding="utf-8"))


def save_seed_data(data: SeedData, path: Path | None = None) -> None:
    seed_path = path or get_seed_path()
    seed_path.write_text(json.dumps(data.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
