#!/usr/bin/env sh
# 본문 서체 빌드 — Pretendard를 앱이 실제로 그리는 글자만 남겨 서브셋한다.
#
# 왜: 원본 Pretendard는 한글 11,172자를 전부 담아 굵기당 1.5MB(4굵기 6MB)다.
# 앱의 gzip JS가 794KB인데 폰트로 6MB를 받게 할 수 없다.
#
# 이름을 왜 바꾸나: Pretendard는 SIL OFL이면서 예약 폰트 이름(Reserved Font Name)
# 'Pretendard'가 걸려 있다. 서브셋은 OFL이 말하는 Modified Version이라, 사용자에게
# 보이는 폰트 이름을 그대로 쓸 수 없다(OFL 1.1 §3). 그래서 내부 이름을 'Dogu Sans'로
# 바꿔 담고, 저작권·라이선스 원문과 출처는 NOTICE에 그대로 남긴다.
#
#   scripts/build_fonts.sh
#
# 커버 문자 집합(charset)은 KS X 1001 상용 한글 2350자 + seed 데이터와 앱 소스에
# 실제로 등장하는 문자 + 자주 쓰는 기호다. app/test/font_charset_test.dart가
# seed/소스의 글자가 charset을 벗어나면 CI에서 실패시킨다.
set -eu

cd "$(dirname "$0")/.."

PRETENDARD_VERSION="1.3.9"
SRC_URL="https://github.com/orioncactus/pretendard/releases/download/v${PRETENDARD_VERSION}/Pretendard-${PRETENDARD_VERSION}.zip"
DEST="app/assets/fonts/dogusans"

command -v python3 >/dev/null || { echo "python3 required" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading Pretendard v${PRETENDARD_VERSION}"
curl -fsSL -o "$TMP/pretendard.zip" "$SRC_URL"
unzip -q -o "$TMP/pretendard.zip" -d "$TMP/pretendard"

python3 -m venv "$TMP/venv" >/dev/null
"$TMP/venv/bin/pip" -q install fonttools

mkdir -p "$DEST"
"$TMP/venv/bin/python" - "$TMP/pretendard/public/static" "$DEST" "$PRETENDARD_VERSION" <<'PY'
import glob
import os
import sys

from fontTools import subset
from fontTools.ttLib import TTFont

src_dir, dest, version = sys.argv[1], sys.argv[2], sys.argv[3]

# 앱에 담을 굵기 — 소스의 FontWeight 사용 분포(w300~w900)를 4단계로 커버한다.
WEIGHTS = ['Regular', 'SemiBold', 'Bold', 'ExtraBold']
FAMILY = 'Dogu Sans'
FAMILY_PS = 'DoguSans'


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


def build_charset():
    chars = {chr(c) for c in range(0x20, 0x7F)}          # ASCII 출력 가능
    chars |= ksx1001_hangul()                            # 상용 한글
    chars |= {chr(c) for c in range(0x3131, 0x3164)}     # 호환 자모 ㄱ-ㅣ
    # 실제 콘텐츠와 소스에 등장하는 글자(상품명·카피·기호)를 빠짐없이 포함한다.
    chars |= set(open('backend/app/data/seed.json', encoding='utf-8').read())
    for path in glob.glob('app/lib/**/*.dart', recursive=True):
        chars |= set(open(path, encoding='utf-8').read())
    # 앞으로 쓸 법한 기호 여유분.
    chars |= set('©®™·—–…“”‘’₩€$¥×÷±≤≥≠→←↑↓○●◇◆□■△▲▽▼★☆♡♥✓✔✕✖※')
    return {c for c in chars if c == ' ' or c.isprintable()}


charset = build_charset()
text = ''.join(sorted(charset))
hangul = len([c for c in charset if 0xAC00 <= ord(c) <= 0xD7A3])
print(f'charset: {len(charset)} chars (hangul {hangul})')

charset_path = os.path.join(dest, 'charset.txt')
with open(charset_path, 'w', encoding='utf-8') as handle:
    handle.write(
        '# Dogu Sans 서브셋이 담는 문자 집합(생성물 — scripts/build_fonts.sh가 씀).\n'
        '# KS X 1001 상용 한글 + seed 데이터/앱 소스의 문자 + 자주 쓰는 기호.\n'
        '# 이 파일 아래 한 줄이 실제 문자열이다.\n'
    )
    handle.write(text + '\n')

total_before = total_after = 0
for weight in WEIGHTS:
    src = os.path.join(src_dir, f'Pretendard-{weight}.otf')
    out = os.path.join(dest, f'DoguSans-{weight}.otf')

    options = subset.Options()
    options.drop_tables += ['DSIG']
    options.layout_features = '*'
    options.notdef_outline = True
    font = subset.load_font(src, options)
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(text=text)
    subsetter.subset(font)
    subset.save_font(font, out, options)

    # OFL 예약 이름을 벗어나도록 사용자에게 보이는 이름을 바꾼다(OFL 1.1 §3).
    renamed = TTFont(out)
    records = {
        1: FAMILY,
        3: f'{FAMILY_PS}-{weight}; subset of Pretendard {version}',
        4: f'{FAMILY} {weight}',
        6: f'{FAMILY_PS}-{weight}',
        16: FAMILY,
    }
    for record in renamed['name'].names:
        if record.nameID in records:
            record.string = records[record.nameID].encode('utf-16-be') \
                if record.platformID == 3 else records[record.nameID].encode('latin-1')
    renamed.save(out)

    before, after = os.path.getsize(src), os.path.getsize(out)
    total_before += before
    total_after += after
    print(f'  Pretendard-{weight:10} {before / 1024:7.0f}KB -> DoguSans-{weight:10} {after / 1024:6.0f}KB')

print(f'total: {total_before / 1024 / 1024:.2f}MB -> {total_after / 1024 / 1024:.2f}MB')
PY

cp "$TMP/pretendard/LICENSE.txt" "$DEST/LICENSE.txt"

cat > "$DEST/NOTICE.md" <<NOTICE
# Dogu Sans — Pretendard 서브셋

이 디렉터리의 \`DoguSans-*.otf\`는 **Pretendard v${PRETENDARD_VERSION}의 서브셋**이다.
원본은 한글 11,172자를 모두 담아 굵기당 약 1.5MB인데, 앱이 실제로 그리는 글자만
남겨 굵기당 약 350KB로 줄였다. \`charset.txt\`가 담긴 문자 집합이다.

## 이름을 바꾼 이유

Pretendard는 SIL Open Font License 1.1이면서 예약 폰트 이름(Reserved Font Name)
\`Pretendard\`가 선언돼 있다. 서브셋은 OFL이 정의하는 Modified Version이므로,
사용자에게 보이는 폰트 이름으로 예약 이름을 쓸 수 없다(OFL 1.1 §3).
그래서 내부 name 레코드를 \`Dogu Sans\`로 바꿔 담는다. 자형은 원본 그대로다.

- 원저작권: Copyright (c) 2021, Kil Hyung-jin — https://github.com/orioncactus/pretendard
- 라이선스: \`LICENSE.txt\`(OFL 1.1 원문, 원본 배포본에서 그대로 가져옴)
- 재생성: \`scripts/build_fonts.sh\`

NOTICE

ls -l "$DEST"
