#!/usr/bin/env sh
# 프론트 기능 모듈 테스트 — test/features/<기능>/ 디렉터리 하나가 모듈 하나이고, CI에서는 잡 하나다
# (.github/workflows/ci.yml의 'Frontend · <기능>'). 새 기능은 디렉터리만 추가하면 CI에 자동으로 들어간다.
#
#   scripts/test_modules.sh                  # 모든 모듈을 하나씩 돌리고 모듈별 결과 요약
#   scripts/test_modules.sh cart search      # 고른 모듈만
#   scripts/test_modules.sh --list           # 모듈 목록
#   scripts/test_modules.sh --json           # 모듈 목록(JSON 배열) — CI 매트릭스용
#   scripts/test_modules.sh --check          # 구조 검사 — 모든 *_test.dart가 모듈(또는 integration/) 안에 있는가
#   WITH_GOLDENS=1 scripts/test_modules.sh home   # 골든 포함
#
# 골든 정본은 CI(ubuntu) 렌더라 로컬(macOS)에선 폰트/AA 차이로 깨진다 — 그래서 로컬 기본은 골든 제외.
# CI의 모듈 잡은 골든까지 돌린다.
set -eu

cd "$(dirname "$0")/.."

FEATURES="test/features"

modules() {
  for dir in "$FEATURES"/*/; do
    basename "$dir"
  done
}

case "${1:-}" in
  --list)
    modules
    exit 0
    ;;
  --json)
    printf '['
    sep=''
    for module in $(modules); do
      printf '%s"%s"' "$sep" "$module"
      sep=','
    done
    printf ']\n'
    exit 0
    ;;
  --check)
    status=0
    # 모듈 밖에 떨어진 테스트 파일 — CI 매트릭스에 안 잡혀서 조용히 안 돈다.
    stray="$(find test -name '*_test.dart' -not -path "$FEATURES/*/*" -not -path 'test/integration/*' | sort)"
    if [ -n "$stray" ]; then
      echo "::error::test files outside a feature module (move them under $FEATURES/<feature>/):" >&2
      echo "$stray" >&2
      status=1
    fi
    for module in $(modules); do
      case "$module" in
        *[!a-z0-9_]*|[!a-z]*) echo "::error::module name '$module' must be lower_snake_case" >&2; status=1 ;;
      esac
      if [ -z "$(find "$FEATURES/$module" -name '*_test.dart' | head -n 1)" ]; then
        echo "::error::module '$module' has no *_test.dart" >&2
        status=1
      fi
    done
    [ "$status" -eq 0 ] && echo "OK: $(modules | wc -l | tr -d ' ') feature modules, every test file belongs to one"
    exit "$status"
    ;;
esac

if [ "$#" -gt 0 ]; then
  selected="$*"
else
  selected="$(modules)"
fi

if [ -n "${WITH_GOLDENS:-}" ]; then
  set --
else
  set -- --exclude-tags golden
fi

passed=''
failed=''
for module in $selected; do
  if [ ! -d "$FEATURES/$module" ]; then
    echo "unknown module '$module' — see: scripts/test_modules.sh --list" >&2
    exit 2
  fi
  echo "── $module"
  if flutter test "$FEATURES/$module" "$@"; then
    passed="$passed $module"
  else
    failed="$failed $module"
  fi
done

echo
echo "passed:${passed:- -}"
echo "failed:${failed:- -}"
[ -z "$failed" ]
