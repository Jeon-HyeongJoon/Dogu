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

echo "Building Dogu web (release) with API_BASE_URL=$API_BASE_URL"
flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL"

# 주입이 실제로 번들에 박혔는지 확인 — 배포 전에 여기서 잡는다.
HOST="$(printf '%s' "$API_BASE_URL" | sed -e 's|^https\{0,1\}://||' -e 's|/.*$||')"
if ! grep -q "$HOST" build/web/main.dart.js; then
  echo "::error::built bundle does not contain $HOST — API_BASE_URL was not compiled in" >&2
  exit 1
fi

# 역방향 확인 — 로컬 폴백 주소가 번들에 남아 있으면 주입이 제대로 안 된 것이다.
for LOCAL in "localhost:8000" "127.0.0.1:8000" "10.0.2.2:8000"; do
  if grep -q "$LOCAL" build/web/main.dart.js; then
    echo "::error::built bundle still contains the local API fallback $LOCAL" >&2
    exit 1
  fi
done

echo "OK: build/web/main.dart.js targets $HOST (no local API fallback)"
