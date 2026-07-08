#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

if [ ! -f .env.local ]; then
  cp .env.local.example .env.local
fi

API_BASE_URL="$(grep '^API_BASE_URL=' .env.local | tail -n 1 | cut -d= -f2-)"
if [ -z "$API_BASE_URL" ]; then
  echo "API_BASE_URL is missing in app/.env.local" >&2
  exit 1
fi

echo "Building Dogu frontend with API_BASE_URL=$API_BASE_URL"
flutter build web --dart-define=API_BASE_URL="$API_BASE_URL"
echo "Serving Dogu frontend at http://localhost:8080"
exec python3 -m http.server 8080 --bind 127.0.0.1 --directory build/web
