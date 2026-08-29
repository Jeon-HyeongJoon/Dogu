#!/usr/bin/env sh
# 프로덕션 배포 — 빌드 가드를 통과한 번들만 올린다.
#
# build_prod.sh가 API_BASE_URL 주입을 강제하고 번들을 검증한다. 그 검증에 실패하면
# 여기서 멈추므로, 백엔드를 못 부르는 번들이 프로덕션에 올라갈 수 없다.
# (같은 가드가 CI frontend 잡에서도 돌아 머지 전에 먼저 걸린다.)
set -eu

cd "$(dirname "$0")/.."

./scripts/build_prod.sh

echo "Deploying build/web to Vercel production"
vercel --prod --yes

# 배포본이 방금 빌드한 번들과 같은지 확인한다.
DEPLOYED_URL="${DEPLOY_VERIFY_URL:-https://app-drab-six-24.vercel.app}"
LOCAL_SHA="$(shasum -a 256 build/web/main.dart.js | cut -d' ' -f1)"
REMOTE_SHA="$(curl -fsSL "$DEPLOYED_URL/main.dart.js" | shasum -a 256 | cut -d' ' -f1)"
if [ "$LOCAL_SHA" != "$REMOTE_SHA" ]; then
  echo "::error::deployed bundle ($REMOTE_SHA) differs from the local build ($LOCAL_SHA)" >&2
  exit 1
fi
echo "OK: $DEPLOYED_URL serves the bundle just built ($LOCAL_SHA)"
