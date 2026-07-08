#!/usr/bin/env python3
"""Keep the two committed seed.json copies in lockstep (single source of truth).

The catalog seed lives in ONE canonical file:

    backend/app/data/seed.json      <-- edit this one

The Flutter app bundles its own copy for the offline instant-paint fallback:

    app/assets/seed.json            <-- generated mirror, do not hand-edit

Both packages deploy independently (backend on Vercel Python from `backend/`,
the web app from `app/build/web`), so each needs a physical copy at build time.
This script makes the app copy a byte-for-byte mirror of the canonical backend
copy, and `--check` verifies they are in sync (used by CI via the guard test).

Usage:
    python3 scripts/sync_seed.py            # copy canonical -> app mirror
    python3 scripts/sync_seed.py --check    # exit 1 if they differ (no writes)
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
CANONICAL = REPO_ROOT / "backend" / "app" / "data" / "seed.json"
MIRROR = REPO_ROOT / "app" / "assets" / "seed.json"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify the mirror matches the canonical seed without writing",
    )
    args = parser.parse_args()

    if not CANONICAL.exists():
        print(f"canonical seed missing: {CANONICAL}", file=sys.stderr)
        return 2

    canonical_bytes = CANONICAL.read_bytes()
    mirror_bytes = MIRROR.read_bytes() if MIRROR.exists() else None

    if args.check:
        if mirror_bytes == canonical_bytes:
            print("seed.json in sync")
            return 0
        rel_mirror = MIRROR.relative_to(REPO_ROOT)
        rel_canonical = CANONICAL.relative_to(REPO_ROOT)
        message = (
            f"seed.json OUT OF SYNC: {rel_mirror} != {rel_canonical}\n"
            f"run: python3 scripts/sync_seed.py"
        )
        print(message, file=sys.stderr)
        return 1

    if mirror_bytes == canonical_bytes:
        print("seed.json already in sync")
        return 0

    MIRROR.parent.mkdir(parents=True, exist_ok=True)
    MIRROR.write_bytes(canonical_bytes)
    print(f"synced {CANONICAL.relative_to(REPO_ROOT)} -> {MIRROR.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
