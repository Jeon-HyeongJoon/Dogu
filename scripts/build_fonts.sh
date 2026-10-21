#!/usr/bin/env sh
# 앱이 담는 서체 전부를 서브셋으로 다시 만든다.
#
# 왜: 원본 통짜 서체를 그대로 담으면 폰트만 10MB가 넘는다(gzip main.dart.js는 794KB).
# 앱이 실제로 그리는 글자만 남기면 1/10 이하로 줄고, 첫 페인트를 막는 서체가 특히 가벼워진다.
#
#   scripts/build_fonts.sh
#
# 만드는 것:
#   Dogu Sans  (본문)  ← Pretendard        : KS X 1001 상용 한글 + seed/소스 문자 + 기호
#   Dogu Hand  (타이틀) ← HSBombaram 3.0    : 브랜드 타이틀 + 농담 한 줄 + ASCII
#   Gaegu      (농담)  ← Gaegu Bold        : 농담 한 줄 + ASCII
#   Dogu Serif (가격)  ← Playfair Display  : Bold 700 인스턴스(바로·이탤릭), ASCII + 숫자 기호 + 합성한 ₩
#
# 이름을 바꾸는 이유(Dogu Sans / Dogu Hand): 원본이 각각 OFL 예약 폰트 이름과
# 등록상표를 달고 있어, 수정본(서브셋)을 원본 이름으로 배포할 수 없다. 자형은 그대로고
# 출처·저작권은 각 디렉터리의 NOTICE.md에 남긴다. Gaegu는 예약 이름이 없어 그대로 쓴다.
#
# 커버 문자가 모자라면 그 글자만 두부(⊠)로 찍힌다 — app/test/font_charset_test.dart가
# seed 카탈로그와 앱 소스를 charset과 대조해 CI에서 잡는다.
set -eu

cd "$(dirname "$0")/.."

PRETENDARD_VERSION="1.3.9"
PRETENDARD_URL="https://github.com/orioncactus/pretendard/releases/download/v${PRETENDARD_VERSION}/Pretendard-${PRETENDARD_VERSION}.zip"
GAEGU_URL="https://raw.githubusercontent.com/google/fonts/main/ofl/gaegu/Gaegu-Bold.ttf"
GAEGU_OFL_URL="https://raw.githubusercontent.com/google/fonts/main/ofl/gaegu/OFL.txt"
PLAYFAIR_URL="https://raw.githubusercontent.com/google/fonts/main/ofl/playfairdisplay/PlayfairDisplay%5Bwght%5D.ttf"
PLAYFAIR_ITALIC_URL="https://raw.githubusercontent.com/google/fonts/main/ofl/playfairdisplay/PlayfairDisplay-Italic%5Bwght%5D.ttf"
PLAYFAIR_OFL_URL="https://raw.githubusercontent.com/google/fonts/main/ofl/playfairdisplay/OFL.txt"
# HSBombaram 원본은 배포처가 없어 디자인 원본 보관소(git-ignored)에서 가져온다.
BOMBARAM_ZIP="design/assets/HSBomBaram3.0_OTF.zip"

command -v python3 >/dev/null || { echo "python3 required" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading Pretendard v${PRETENDARD_VERSION}"
curl -fsSL -o "$TMP/pretendard.zip" "$PRETENDARD_URL"
unzip -q -o -j "$TMP/pretendard.zip" 'public/static/Pretendard-*.otf' 'LICENSE.txt' -d "$TMP/pretendard" < /dev/null

echo "Downloading Gaegu Bold"
curl -fsSL -o "$TMP/Gaegu-Bold.ttf" "$GAEGU_URL"
curl -fsSL -o "$TMP/gaegu-OFL.txt" "$GAEGU_OFL_URL"

echo "Downloading Playfair Display (variable)"
curl -fsSL -o "$TMP/PlayfairDisplay.ttf" "$PLAYFAIR_URL"
curl -fsSL -o "$TMP/PlayfairDisplay-Italic.ttf" "$PLAYFAIR_ITALIC_URL"
curl -fsSL -o "$TMP/playfair-OFL.txt" "$PLAYFAIR_OFL_URL"

if [ -f "$BOMBARAM_ZIP" ]; then
  # zip 안에 세로쓰기 파일명이 깨져 있어 필요한 굵기만 골라 꺼낸다(대화형 프롬프트 회피).
  unzip -q -o -j "$BOMBARAM_ZIP" 'HSBombaram3.0_Thin.otf' -d "$TMP/bombaram" < /dev/null
  BOMBARAM_SRC="$TMP/bombaram/HSBombaram3.0_Thin.otf"
else
  echo "note: $BOMBARAM_ZIP not present (design/ is git-ignored) — keeping the committed Dogu Hand subset"
  BOMBARAM_SRC=""
fi

python3 -m venv "$TMP/venv" >/dev/null
"$TMP/venv/bin/pip" -q install fonttools

"$TMP/venv/bin/python" - "$TMP/pretendard" "$TMP/Gaegu-Bold.ttf" "$BOMBARAM_SRC" "$PRETENDARD_VERSION" "$TMP/PlayfairDisplay.ttf" "$TMP/PlayfairDisplay-Italic.ttf" <<'PY'
import glob
import os
import re
import sys

from fontTools import subset
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

pretendard_dir, gaegu_src, bombaram_src, pretendard_version, playfair_src, playfair_italic_src = sys.argv[1:7]


def dart_const(path, name):
    """Dart 소스의 `static const <name> = '...';` 값을 읽는다."""
    source = open(path, encoding='utf-8').read()
    match = re.search(rf"static const {name} = '((?:[^'\\]|\\.)*)';", source)
    if not match:
        raise SystemExit(f'{name} not found in {path}')
    return match.group(1).replace('\\n', '\n')


def ksx1001_hangul():
    """KS X 1001 상용 한글 2350자 — euc-kr 한글 영역(리드바이트 0xB0~0xC8)."""
    out = set()
    for code in range(0xAC00, 0xD7A4):
        ch = chr(code)
        try:
            encoded = ch.encode('euc_kr')
        except UnicodeEncodeError:
            continue
        if len(encoded) == 2 and 0xB0 <= encoded[0] <= 0xC8:
            out.add(ch)
    return out


ASCII = {chr(c) for c in range(0x20, 0x7F)}
BRAND = dart_const('packages/dogu_ui/lib/src/components/brand/dogu_brand_lockup.dart', 'brandName')
JOKE = dart_const('app/lib/src/order_flow.dart', 'jokeLine')


def body_charset():
    chars = set(ASCII) | ksx1001_hangul()
    chars |= {chr(c) for c in range(0x3131, 0x3164)}     # 호환 자모 ㄱ-ㅣ
    # 실제 콘텐츠와 소스에 등장하는 글자(상품명·카피·기호)를 빠짐없이 포함한다.
    chars |= set(open('backend/app/data/seed.json', encoding='utf-8').read())
    # 앱과 디자인 시스템(packages/dogu_ui) 소스 모두 — 컴포넌트 문구('이미지 준비 중' 등)는 패키지에 있다.
    for path in glob.glob('app/lib/**/*.dart', recursive=True) + glob.glob('packages/dogu_ui/lib/**/*.dart', recursive=True):
        chars |= set(open(path, encoding='utf-8').read())
    chars |= set('©®™·—–…“”‘’₩€$¥×÷±≤≥≠→←↑↓○●◇◆□■△▲▽▼★☆♡♥✓✔✕✖※')
    return chars


def write_charset(dest, text, note):
    path = os.path.join(dest, 'charset.txt')
    with open(path, 'w', encoding='utf-8') as handle:
        handle.write(f'# {note}\n')
        handle.write('# 생성물 — scripts/build_fonts.sh 가 쓴다. 아래 한 줄이 실제 문자열이다.\n')
        handle.write(text + '\n')


def clean(chars):
    return ''.join(sorted(c for c in chars if c == ' ' or c.isprintable()))


def make_subset(src, out, text, rename=None):
    options = subset.Options()
    options.drop_tables += ['DSIG']
    options.layout_features = '*'
    options.notdef_outline = True
    font = subset.load_font(src, options)
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(text=text)
    subsetter.subset(font)
    subset.save_font(font, out, options)

    if rename:
        renamed = TTFont(out)
        for record in renamed['name'].names:
            if record.nameID in rename:
                value = rename[record.nameID]
                record.string = value.encode('utf-16-be') if record.platformID == 3 else value.encode('latin-1')
        renamed.save(out)
    return os.path.getsize(src), os.path.getsize(out)


total_before = total_after = 0

# ── 본문체: Pretendard -> Dogu Sans ───────────────────────────────────────
dest = 'packages/dogu_ui/assets/fonts/dogusans'
os.makedirs(dest, exist_ok=True)
body = clean(body_charset())
write_charset(dest, body, 'Dogu Sans(본문) 커버 문자 — KS X 1001 + seed/소스 문자 + 기호')
for weight in ['Regular', 'SemiBold', 'Bold', 'ExtraBold']:
    before, after = make_subset(
        os.path.join(pretendard_dir, f'Pretendard-{weight}.otf'),
        os.path.join(dest, f'DoguSans-{weight}.otf'),
        body,
        rename={
            1: 'Dogu Sans',
            3: f'DoguSans-{weight}; subset of Pretendard {pretendard_version}',
            4: f'Dogu Sans {weight}',
            6: f'DoguSans-{weight}',
            16: 'Dogu Sans',
        },
    )
    total_before += before
    total_after += after
    print(f'  Pretendard-{weight:10} {before / 1024:7.0f}KB -> DoguSans-{weight:10} {after / 1024:7.1f}KB')

# ── 타이틀 손글씨체: HSBombaram 3.0 -> Dogu Hand ──────────────────────────
dest = 'packages/dogu_ui/assets/fonts/doguhand'
os.makedirs(dest, exist_ok=True)
# 브랜드 타이틀 + (농담 줄의 폴백 역할) + ASCII.
hand = clean(set(BRAND) | set(JOKE) | ASCII)
write_charset(dest, hand, 'Dogu Hand(타이틀) 커버 문자 — 브랜드 타이틀 + 농담 한 줄 + ASCII')
if bombaram_src:
    before, after = make_subset(
        bombaram_src,
        os.path.join(dest, 'DoguHand-Thin.otf'),
        hand,
        rename={
            1: 'Dogu Hand',
            3: 'DoguHand-Thin; subset of HSBombaram 3.0',
            4: 'Dogu Hand Thin',
            6: 'DoguHand-Thin',
            16: 'Dogu Hand',
        },
    )
    total_before += before
    total_after += after
    print(f'  HSBombaram-Thin       {before / 1024:7.0f}KB -> DoguHand-Thin        {after / 1024:7.1f}KB')

# ── 농담 서체: Gaegu Bold(예약 이름 없음 — 이름 유지) ─────────────────────
dest = 'packages/dogu_ui/assets/fonts/gaegu'
os.makedirs(dest, exist_ok=True)
joke = clean(set(JOKE) | ASCII)
write_charset(dest, joke, 'Gaegu(농담 한 줄) 커버 문자 — 농담 문구 + ASCII')
before, after = make_subset(gaegu_src, os.path.join(dest, 'Gaegu-Bold-subset.ttf'), joke)
total_before += before
total_after += after
print(f'  Gaegu-Bold            {before / 1024:7.0f}KB -> Gaegu-Bold-subset    {after / 1024:7.1f}KB')

# ── 가격·숫자 세리프: Playfair Display -> Dogu Serif ────────────────────────
# 가변 서체에서 Bold(700)만 고정 인스턴스로 떼어 라틴 글자·숫자 기호만 남긴다. 한글은 본문체로 폴백한다.
# 원본에 원화 기호(₩)가 없어서 W 위에 가로줄 두 개를 그어 만든다 — 없으면 가격의 ₩만 고딕으로 튀었다.
def add_won_sign(path):
    font = TTFont(path)
    glyphs = font.getGlyphSet()
    cap = font['OS/2'].sCapHeight
    glyf = font['glyf']
    w = glyf['W']
    w.recalcBounds(glyf)
    pen = TTGlyphPen(glyphs)
    glyphs['W'].draw(pen)
    thick = round(cap * 0.075)
    overhang = round(cap * 0.02)
    for height in (0.40, 0.60):
        y0 = round(cap * height - thick / 2)
        x0, x1, y1 = w.xMin - overhang, w.xMax + overhang, y0 + thick
        pen.moveTo((x0, y0)); pen.lineTo((x0, y1)); pen.lineTo((x1, y1)); pen.lineTo((x1, y0)); pen.closePath()
    name = 'uni20A9'
    glyf[name] = pen.glyph()
    order = font.getGlyphOrder()
    if name not in order:
        order.append(name)
        font.setGlyphOrder(order)
    font['hmtx'][name] = font['hmtx']['W']
    for table in font['cmap'].tables:
        if table.isUnicode():
            table.cmap[0x20A9] = name
    font.save(path)


dest = 'packages/dogu_ui/assets/fonts/doguserif'
os.makedirs(dest, exist_ok=True)
serif = clean(ASCII | set('−·×'))
write_charset(dest, serif + '₩', 'Dogu Serif(가격·숫자) 커버 문자 — ASCII + 숫자 기호 + 합성한 ₩')
# 바로(가격·숫자)와 이탤릭(광고 워드마크의 'SI'·태그라인) — 굵기는 둘 다 700.
for style, src in [('Bold', playfair_src), ('BoldItalic', playfair_italic_src)]:
    instance = os.path.join(os.path.dirname(src), f'PlayfairDisplay-{style}.ttf')
    instancer.instantiateVariableFont(TTFont(src), {'wght': 700}).save(instance)
    out = os.path.join(dest, f'DoguSerif-{style}.ttf')
    label = 'Bold Italic' if style == 'BoldItalic' else 'Bold'
    make_subset(
        instance,
        out,
        serif,
        rename={
            1: 'Dogu Serif',
            2: label,
            3: f'DoguSerif-{style}; subset of Playfair Display',
            4: f'Dogu Serif {label}',
            6: f'DoguSerif-{style}',
            16: 'Dogu Serif',
            17: label,
        },
    )
    add_won_sign(out)
    before, after = os.path.getsize(src), os.path.getsize(out)
    total_before += before
    total_after += after
    print(f'  Playfair {style:13} {before / 1024:7.0f}KB -> DoguSerif-{style:11} {after / 1024:7.1f}KB')

print(f'total: {total_before / 1024 / 1024:.2f}MB -> {total_after / 1024 / 1024:.2f}MB')
PY

cp "$TMP/pretendard/LICENSE.txt" packages/dogu_ui/assets/fonts/dogusans/LICENSE.txt
cp "$TMP/gaegu-OFL.txt" packages/dogu_ui/assets/fonts/gaegu/OFL.txt
cp "$TMP/playfair-OFL.txt" packages/dogu_ui/assets/fonts/doguserif/OFL.txt

cat > packages/dogu_ui/assets/fonts/doguserif/NOTICE.md <<'NOTICE'
# Dogu Serif — Playfair Display 서브셋

이 디렉터리의 `DoguSerif-Bold.ttf`·`DoguSerif-BoldItalic.ttf`는 **Playfair Display(가변 서체, 바로·이탤릭)의
Bold(700) 인스턴스를 서브셋**한 것이다. 가격·큰 숫자·영문 디스플레이(섹션 제목, 광고 워드마크와 태그라인)에만
쓰여 라틴 글자·숫자 기호(`charset.txt`)만 남겼다(각 약 49KB). 첫 화면에 보여서 본문체와 함께 첫 페인트 전에 받는다.

## 바꾼 것

- 이름: 원본은 OFL **예약 폰트 이름(Reserved Font Name) "Playfair Display"**를 달고 있어, 수정본(인스턴스·서브셋)을
  원본 이름으로 배포할 수 없다. 내부 name 레코드를 `Dogu Serif`로 바꿔 담는다.
- 원화 기호(₩, U+20A9): 원본에 없어서 W 글리프 위에 가로줄 두 개를 그어 합성했다(`scripts/build_fonts.sh`의
  `add_won_sign`). 나머지 자형은 원본 그대로다.

## 출처와 라이선스

- Copyright 2017 The Playfair Display Project Authors (https://github.com/clauseggers/Playfair-Display)
- 라이선스: SIL Open Font License 1.1 — `OFL.txt`
- 재생성: `scripts/build_fonts.sh`
NOTICE

cat > packages/dogu_ui/assets/fonts/doguhand/NOTICE.md <<'NOTICE'
# Dogu Hand — HSBombaram 3.0 서브셋

이 디렉터리의 `DoguHand-Thin.otf`는 **HSBombaram 3.0 Thin의 서브셋**이다.
브랜드 타이틀('욕망의 장바구니') 한 줄과 농담 줄 폴백에만 쓰여서, 원본 416KB 중
`charset.txt`에 적힌 글자만 남겨 약 14KB로 줄였다. 이 서체는 첫 페인트를 막고
로드되므로(한글 두부 방지) 크기가 곧 첫 화면 속도다.

## 이름을 바꾼 이유

원본 이름 `HSBomBaram 3.0`은 저작권자의 **등록상표**다(폰트 name 레코드 7번).
수정본(서브셋)을 원본 이름 그대로 배포하지 않으려고 내부 name 레코드를
`Dogu Hand`로 바꿔 담는다. 자형은 원본 그대로다.

## 출처와 라이선스

- 제작: 토끼네활자공장(유미주의적 달필가)
- 원저작권: Copyright (c) 2020. Hyun Seok Choi. All rights reserved. — http://hp0.blog.me
- 라이선스: HS봄바람체(3.0 포함)는 개인·기업을 포함한 모든 사용자에게 상업적·비상업적
  목적으로 무료 제공되는 프리 라이선스다. 원본 배포본에 라이선스 원문 파일은 동봉돼 있지 않다.
- 원본 보관: `design/assets/HSBomBaram3.0_OTF.zip` (git-ignored)
- 재생성: `scripts/build_fonts.sh`
NOTICE

echo
echo "fonts:"
find packages/dogu_ui/assets/fonts -type f \( -name '*.otf' -o -name '*.ttf' \) -exec ls -l {} \; | awk '{printf "  %7.1f KB  %s\n", $5/1024, $9}'
