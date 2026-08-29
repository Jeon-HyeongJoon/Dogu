#!/usr/bin/env sh
# 브랜드 로고 SSOT — 정본은 design/assets/(git-ignored, 디자인 원본 보관소).
# 앱은 패키지 밖 경로를 에셋으로 번들할 수 없어, 여기서 256px 파생본을 만들어
# app/assets/에 커밋한다. 로고를 바꾸면 정본을 교체하고 이 스크립트를 다시 돌린다.
#   scripts/sync_logo.sh          # 정본 -> app 미러
#   scripts/sync_logo.sh --check  # 미러가 정본과 같은지 검증(CI 가드)
set -eu

cd "$(dirname "$0")/.."

SRC="design/assets/logo-square.png"
DEST="app/assets/logo-square.png"
SIZE=256

if [ ! -f "$SRC" ]; then
  # 정본은 git-ignored라 CI 체크아웃에는 없다 — 그때는 커밋된 미러를 그대로 신뢰한다.
  echo "canonical $SRC not present (design/ is git-ignored) — keeping committed $DEST"
  [ -f "$DEST" ] || { echo "::error::$DEST is missing" >&2; exit 1; }
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
sips -Z "$SIZE" "$SRC" --out "$TMP/logo-square.png" >/dev/null

if [ "${1:-}" = "--check" ]; then
  if cmp -s "$TMP/logo-square.png" "$DEST"; then
    echo "OK: $DEST matches $SRC (${SIZE}px)"
  else
    echo "::error::$DEST is stale — run scripts/sync_logo.sh" >&2
    exit 1
  fi
else
  cp "$TMP/logo-square.png" "$DEST"
  echo "synced $SRC -> $DEST (${SIZE}px)"
fi
