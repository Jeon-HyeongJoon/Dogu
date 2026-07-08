"""Single-source-of-truth guard for the catalog seed.

The seed catalog has ONE canonical file, `backend/app/data/seed.json`. The
Flutter app ships a byte-for-byte mirror at `app/assets/seed.json` for its
offline instant-paint fallback (both packages deploy independently, so each
needs a physical copy at build time). This test fails if the two drift, making
silent divergence impossible to merge. Re-sync with:

    python3 scripts/sync_seed.py
"""
import json
from pathlib import Path

from app.models import SECTION_TAGS

REPO_ROOT = Path(__file__).resolve().parents[2]
CANONICAL = REPO_ROOT / "backend" / "app" / "data" / "seed.json"
MIRROR = REPO_ROOT / "app" / "assets" / "seed.json"
GENERATED_DART = REPO_ROOT / "app" / "lib" / "src" / "bundled_seed.g.dart"


def test_seed_files_exist() -> None:
    assert CANONICAL.exists(), f"canonical seed missing: {CANONICAL}"
    assert MIRROR.exists(), f"app seed mirror missing: {MIRROR}"


def test_app_seed_mirror_matches_canonical() -> None:
    assert MIRROR.read_bytes() == CANONICAL.read_bytes(), (
        f"{MIRROR.relative_to(REPO_ROOT)} has drifted from the canonical "
        f"{CANONICAL.relative_to(REPO_ROOT)}. Re-sync with: "
        "python3 scripts/sync_seed.py"
    )


def test_canonical_seed_is_valid_json() -> None:
    # A corrupt canonical would silently be mirrored everywhere; guard it here.
    data = json.loads(CANONICAL.read_text(encoding="utf-8"))
    assert isinstance(data, dict) and data, "canonical seed is not a non-empty object"


def test_bundled_seed_dart_matches_canonical() -> None:
    # The Flutter app derives its synchronous 0ms/last-resort fallback catalog from
    # the seed embedded in this generated file; guard it against drifting from the
    # canonical seed.json so the fallback stays a derivative, not a second source.
    text = GENERATED_DART.read_text(encoding="utf-8")
    marker = "r'''\n"
    start = text.index(marker) + len(marker)
    end = text.index("''';", start)
    embedded = text[start:end]
    assert json.loads(embedded) == json.loads(CANONICAL.read_text(encoding="utf-8")), (
        f"{GENERATED_DART.relative_to(REPO_ROOT)} has drifted from the canonical seed. "
        "Regenerate with: python3 scripts/sync_seed.py"
    )


def test_section_tag_mapping_is_the_single_source() -> None:
    # The DB query layer (database.py) and the seed fallback filter (repository.py)
    # both resolve `section` through SECTION_TAGS; pin its canonical contents so a
    # section is defined in exactly one place.
    assert SECTION_TAGS == {"deals": "today_deal", "new": "new_arrival"}
