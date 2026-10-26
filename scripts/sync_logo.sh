#!/usr/bin/env sh
# 브랜드 로고 SSOT — 정본은 design/assets/(git-ignored, 디자인 원본 보관소).
# 앱은 패키지 밖 경로를 에셋으로 번들할 수 없어, 여기서 파생본을 만들어 커밋한다:
#   packages/dogu_ui/assets/logo-square.png  헤더 로고(디자인 시스템이 담는다)(30pt로 그린다 — 3배 화면에서도 96px이면 충분, 256px은 116KB였다)
#   app/web/favicon.png                 브라우저 탭(로딩 중에도 보인다)
#   app/web/icons/Icon-{192,512}.png    PWA·홈 화면 아이콘
#   app/web/icons/Icon-maskable-*.png   가장자리가 잘려도 되게 로고를 80%로 줄이고 로고 바탕색으로 여백
# 예전 웹 아이콘은 Flutter 기본 로고(파란 F)였다. 로고를 바꾸면 정본을 교체하고 이 스크립트를 다시 돌린다.
#   scripts/sync_logo.sh          # 정본 -> 파생본
#   scripts/sync_logo.sh --check  # 파생본이 정본과 같은지 검증(CI 가드)
set -eu

cd "$(dirname "$0")/.."

SRC="design/assets/logo-square.png"
# 정본 로고의 바탕색(거의 흰색) — 마스커블 아이콘 여백을 이 색으로 채워 사각 테두리가 안 보이게 한다.
BG="F9F8F8"

TARGETS="packages/dogu_ui/assets/logo-square.png app/web/favicon.png app/web/icons/Icon-192.png app/web/icons/Icon-512.png app/web/icons/Icon-maskable-192.png app/web/icons/Icon-maskable-512.png"

if [ ! -f "$SRC" ]; then
  # 정본은 git-ignored라 CI 체크아웃에는 없다 — 그때는 커밋된 파생본을 그대로 신뢰한다.
  echo "canonical $SRC not present (design/ is git-ignored) — keeping committed derivatives"
  for target in $TARGETS; do
    [ -f "$target" ] || { echo "::error::$target is missing" >&2; exit 1; }
  done
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 헤더 로고 — sips로 줄이기만 한다(골든 이미지가 이 바이트에 맞춰져 있다).
mkdir -p "$TMP/packages/dogu_ui/assets"
sips -Z 96 "$SRC" --out "$TMP/packages/dogu_ui/assets/logo-square.png" >/dev/null

# 웹 아이콘 — 로고는 녹색 선 + 흰 바탕이라 32색 팔레트로 줄여도 티가 안 난다(Icon-512 461KB → 95KB).
# 브라우저가 페이지를 열 때 manifest 아이콘을 받으므로 크기가 곧 첫 로딩 부담이다. PIL이 필요하다.
python3 - "$SRC" "$TMP" "$BG" <<'ICONS'
import os, sys
from PIL import Image

src_path, out, bg = sys.argv[1], sys.argv[2], sys.argv[3]
src = Image.open(src_path).convert('RGB')

def save(img, target):
    path = os.path.join(out, target)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.quantize(colors=32, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).save(path, optimize=True)

def plain(px, target):
    save(src.resize((px, px), Image.Resampling.LANCZOS), target)

def maskable(px, target):
    inner = src.resize((px * 4 // 5,) * 2, Image.Resampling.LANCZOS)
    canvas = Image.new('RGB', (px, px), tuple(int(bg[i:i + 2], 16) for i in (0, 2, 4)))
    offset = (px - inner.width) // 2
    canvas.paste(inner, (offset, offset))
    save(canvas, target)

plain(32, 'app/web/favicon.png')
plain(192, 'app/web/icons/Icon-192.png')
plain(512, 'app/web/icons/Icon-512.png')
maskable(192, 'app/web/icons/Icon-maskable-192.png')
maskable(512, 'app/web/icons/Icon-maskable-512.png')
ICONS

if [ "${1:-}" = "--check" ]; then
  stale=0
  for target in $TARGETS; do
    if ! cmp -s "$TMP/$target" "$target"; then
      echo "::error::$target is stale — run scripts/sync_logo.sh" >&2
      stale=1
    fi
  done
  [ "$stale" -eq 0 ] && echo "OK: logo derivatives match $SRC"
  exit "$stale"
else
  for target in $TARGETS; do
    cp "$TMP/$target" "$target"
  done
  echo "synced $SRC -> $TARGETS"
fi
