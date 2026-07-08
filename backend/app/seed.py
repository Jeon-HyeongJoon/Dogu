from pathlib import Path
import json

from app.config import get_settings
from app.models import SeedData
from app.state import seed_override_path


def get_seed_path() -> Path:
    return get_settings().seed_path


def load_seed_data(path: Path | None = None) -> SeedData:
    if path is None:
        # Prefer an admin-saved override (writable state) over the bundled seed.
        override = seed_override_path()
        if override.exists():
            return SeedData.model_validate_json(override.read_text(encoding="utf-8"))
    seed_path = path or get_seed_path()
    return SeedData.model_validate_json(seed_path.read_text(encoding="utf-8"))


def save_seed_data(data: SeedData, path: Path | None = None) -> None:
    # Write to the writable override, never the read-only bundled seed.json.
    seed_path = path or seed_override_path()
    seed_path.parent.mkdir(parents=True, exist_ok=True)
    seed_path.write_text(json.dumps(data.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
