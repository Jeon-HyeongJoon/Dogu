#!/usr/bin/env sh
# 농담 한 줄('상자는 비어 있었어요, 헤헤.')에 쓰는 Gaegu Bold 서브셋을 만든다.
#
# 디자인 시안이 쓴 서체가 Gaegu Bold라 앱도 같은 자형을 써야 하는데, 원본은
# 한글 2350자를 다 담아 2.9MB다. 장식용 한 줄 때문에 그걸 받게 할 수 없어
# charset.txt에 적힌 글자만 남긴 서브셋(약 80KB)을 커밋한다.
#
#   scripts/build_joke_font.sh
#
# 문구를 바꿨다면 app/assets/fonts/gaegu/charset.txt에 글자를 먼저 더할 것.
# (app/test/joke_font_test.dart가 문구와 charset의 어긋남을 CI에서 잡는다)
set -eu

cd "$(dirname "$0")/.."

DIR="app/assets/fonts/gaegu"
CHARSET="$DIR/charset.txt"
OUT="$DIR/Gaegu-Bold-subset.ttf"
# Google Fonts 원본(SIL OFL). 라이선스 원문은 $DIR/OFL.txt에 함께 커밋한다.
SRC_URL="https://raw.githubusercontent.com/google/fonts/main/ofl/gaegu/Gaegu-Bold.ttf"

command -v python3 >/dev/null || { echo "python3 required" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading Gaegu-Bold from Google Fonts"
curl -fsSL -o "$TMP/Gaegu-Bold.ttf" "$SRC_URL"

python3 -m venv "$TMP/venv" >/dev/null
"$TMP/venv/bin/pip" -q install fonttools

"$TMP/venv/bin/python" - "$CHARSET" "$TMP/Gaegu-Bold.ttf" "$OUT" <<'PY'
import sys
from fontTools import subset

charset_path, src, out = sys.argv[1], sys.argv[2], sys.argv[3]
# 주석(#로 시작하는 줄)을 뺀 나머지가 문자 집합이다.
text = ''.join(
    line for line in open(charset_path, encoding='utf-8').read().splitlines()
    if not line.startswith('#')
)

options = subset.Options()
options.drop_tables += ['DSIG']
options.layout_features = '*'
options.notdef_outline = True

font = subset.load_font(src, options)
subsetter = subset.Subsetter(options=options)
subsetter.populate(text=text)
subsetter.subset(font)
subset.save_font(font, out, options)
print(f'subset {len(set(text))} chars -> {out}')
PY

ls -l "$OUT"
