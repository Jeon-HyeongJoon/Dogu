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

# 배포본이 방금 빌드한 번들과 같은지 확인한다(JS·WebAssembly 둘 다).
# alias가 막 바뀐 직후엔 엣지가 옛 파일을 줄 수 있어(실제로 거짓 실패가 났다) 몇 번 다시 받아 본다.
DEPLOYED_URL="${DEPLOY_VERIFY_URL:-https://app-drab-six-24.vercel.app}"
for FILE in main.dart.js main.dart.wasm; do
  LOCAL_SHA="$(shasum -a 256 "build/web/$FILE" | cut -d' ' -f1)"
  for TRY in 1 2 3 4 5; do
    REMOTE_SHA="$(curl -fsSL "$DEPLOYED_URL/$FILE" | shasum -a 256 | cut -d' ' -f1)"
    [ "$LOCAL_SHA" = "$REMOTE_SHA" ] && break
    [ "$TRY" -lt 5 ] && sleep 3
  done
  if [ "$LOCAL_SHA" != "$REMOTE_SHA" ]; then
    echo "::error::deployed $FILE ($REMOTE_SHA) differs from the local build ($LOCAL_SHA)" >&2
    exit 1
  fi
  echo "OK: $DEPLOYED_URL/$FILE matches the local build ($LOCAL_SHA)"
done
