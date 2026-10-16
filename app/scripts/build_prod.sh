#!/usr/bin/env sh
# 프로덕션 웹 빌드 — API_BASE_URL을 반드시 주입한다.
#
# ApiConfig.baseUrl은 --dart-define=API_BASE_URL이 비어 있으면 localhost:8000으로
# 폴백한다. 그냥 `flutter build web --release`로 빌드해 배포하면 배포본이 사용자의
# localhost를 호출해 백엔드 연동이 조용히 끊긴다(실제로 한 번 발생). 그래서 배포용
# 빌드는 이 스크립트만 쓴다.
set -eu

cd "$(dirname "$0")/.."

if [ -z "${API_BASE_URL:-}" ] && [ -f .env.production ]; then
  API_BASE_URL="$(grep '^API_BASE_URL=' .env.production | tail -n 1 | cut -d= -f2-)"
fi

if [ -z "${API_BASE_URL:-}" ]; then
  echo "API_BASE_URL is missing (env var or app/.env.production)" >&2
  exit 1
fi

case "$API_BASE_URL" in
  *localhost*|*127.0.0.1*|*10.0.2.2*)
    echo "API_BASE_URL=$API_BASE_URL is a local address — refusing to build a production bundle" >&2
    exit 1
    ;;
esac

echo "Building Dogu web (release, wasm + js) with API_BASE_URL=$API_BASE_URL"
# --wasm: WebAssembly(skwasm 렌더러) 빌드와 JS(CanvasKit) 빌드를 함께 만든다. 로더가 WasmGC를 지원하는
# 브라우저엔 WebAssembly를, 아니면 JS를 준다 — 엔진+코드 전송량 약 2.3MB → 1.9MB, 더 빠른 시작.
flutter build web --wasm --release --dart-define=API_BASE_URL="$API_BASE_URL"

# 주입이 실제로 번들에 박혔는지 확인 — 배포 전에 여기서 잡는다(두 빌드 모두).
HOST="$(printf '%s' "$API_BASE_URL" | sed -e 's|^https\{0,1\}://||' -e 's|/.*$||')"
for BUNDLE in build/web/main.dart.js build/web/main.dart.wasm; do
  if ! grep -aq "$HOST" "$BUNDLE"; then
    echo "::error::$BUNDLE does not contain $HOST — API_BASE_URL was not compiled in" >&2
    exit 1
  fi
done

# 역방향 확인 — 로컬 폴백 주소가 번들에 남아 있으면 주입이 제대로 안 된 것이다.
# (JS 빌드만 본다: dart2wasm은 쓰이지 않는 폴백 분기도 문자열로 남긴다. 같은 소스·같은 dart-define이라
#  JS 빌드에서 폴백이 사라졌으면 WebAssembly 빌드도 주입값을 쓴다.)
for LOCAL in "localhost:8000" "127.0.0.1:8000" "10.0.2.2:8000"; do
  if grep -q "$LOCAL" build/web/main.dart.js; then
    echo "::error::built bundle still contains the local API fallback $LOCAL" >&2
    exit 1
  fi
done

echo "OK: build/web/main.dart.{js,wasm} target $HOST (no local API fallback)"
