#!/usr/bin/env python3
"""Keep every derived copy of the catalog seed in lockstep (single source of truth).

The catalog seed lives in ONE canonical file:

    backend/app/data/seed.json      <-- edit this one

Two build-time copies are DERIVED from it (never hand-edited):

    app/assets/seed.json            <-- byte-for-byte mirror bundled as a Flutter
                                        asset (async offline instant-paint source)
    app/lib/src/bundled_seed.g.dart <-- the same JSON embedded as a Dart string so
                                        the app can build its synchronous 0ms /
                                        last-resort fallback catalog from the seed

Both packages deploy independently (backend on Vercel Python from `backend/`, the
web app from `app/build/web`), so each needs a physical copy at build time. This
script regenerates both derived copies, and `--check` verifies they are in sync
(enforced in CI by backend/tests/test_ssot.py).

Usage:
    python3 scripts/sync_seed.py            # regenerate derived copies
    python3 scripts/sync_seed.py --check    # exit 1 if any copy is stale (no writes)
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
CANONICAL = REPO_ROOT / "backend" / "app" / "data" / "seed.json"
MIRROR = REPO_ROOT / "app" / "assets" / "seed.json"
GENERATED_DART = REPO_ROOT / "app" / "lib" / "src" / "bundled_seed.g.dart"


def render_dart(seed_text: str) -> str:
    # Embed the raw seed JSON as a Dart raw string. A raw triple-quoted string
    # keeps every backslash/quote literal; it only breaks on a "'''" sequence,
    # which JSON product data never contains (guarded below).
    if "'''" in seed_text:
        raise ValueError("seed.json contains \"'''\"; cannot embed as a Dart raw string")
    return (
        "// GENERATED FROM backend/app/data/seed.json BY scripts/sync_seed.py — DO NOT EDIT.\n"
        "// Run `python3 scripts/sync_seed.py` to regenerate. Guarded by backend/tests/test_ssot.py.\n"
        "part of '../main.dart';\n"
        "\n"
        "const String kBundledSeedJson = r'''\n"
        f"{seed_text}"
        "''';\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    _ = parser.add_argument(
        "--check",
        action="store_true",
        help="verify the derived copies match the canonical seed without writing",
    )
    args = parser.parse_args()

    if not CANONICAL.exists():
        print(f"canonical seed missing: {CANONICAL}", file=sys.stderr)
        return 2

    canonical_bytes = CANONICAL.read_bytes()
    seed_text = canonical_bytes.decode("utf-8")
    want_dart = render_dart(seed_text)

    mirror_ok = MIRROR.exists() and MIRROR.read_bytes() == canonical_bytes
    dart_ok = GENERATED_DART.exists() and GENERATED_DART.read_text(encoding="utf-8") == want_dart

    if args.check:
        if mirror_ok and dart_ok:
            print("seed derived copies in sync")
            return 0
        if not mirror_ok:
            print(f"OUT OF SYNC: {MIRROR.relative_to(REPO_ROOT)}", file=sys.stderr)
        if not dart_ok:
            print(f"OUT OF SYNC: {GENERATED_DART.relative_to(REPO_ROOT)}", file=sys.stderr)
        print("run: python3 scripts/sync_seed.py", file=sys.stderr)
        return 1

    if mirror_ok and dart_ok:
        print("seed derived copies already in sync")
        return 0

    MIRROR.parent.mkdir(parents=True, exist_ok=True)
    MIRROR.write_bytes(canonical_bytes)
    GENERATED_DART.write_text(want_dart, encoding="utf-8")
    print(
        f"regenerated {MIRROR.relative_to(REPO_ROOT)} and "
        f"{GENERATED_DART.relative_to(REPO_ROOT)} from {CANONICAL.relative_to(REPO_ROOT)}"
    )
    # Sanity: the embedded JSON must parse back to the canonical structure.
    embedded = want_dart.split("r'''\n", 1)[1].rsplit("''';\n", 1)[0]
    assert json.loads(embedded) == json.loads(seed_text), "embedded seed did not round-trip"
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
