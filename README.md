# Dogu

욕망의장바구니 (Dogu) — a Flutter web shopping app with a FastAPI seed backend.

- `app/` — Flutter web frontend
- `backend/` — FastAPI backend (see [backend/README.md](backend/README.md))

CI (GitHub Actions, `.github/workflows/ci.yml`) runs on every push/PR:
backend `pytest`, plus Flutter `analyze`, widget tests, a web build, and a
gzipped `main.dart.js` load-size budget.

## Local run

Run the FastAPI backend and Flutter frontend in separate terminal windows.

## 1. Backend

```sh
cd backend
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt "uvicorn[standard]>=0.30,<1.0"
cp .env.local.example .env.local
./scripts/run_local.sh
```

The backend local env allows the Flutter web app on `127.0.0.1:8080` and `localhost:8080`.

Check the backend:

```sh
curl http://localhost:8000/health
curl http://localhost:8000/api/home
```

API docs are available at `http://localhost:8000/docs`.

## 2. Frontend

Open a second terminal:

```sh
cd app
flutter pub get
cp .env.local.example .env.local
./scripts/run_local.sh
```

Open `http://127.0.0.1:8080` in a browser. The frontend script reads `app/.env.local` and passes `API_BASE_URL` to Flutter with `--dart-define`.

## Quick checks

```sh
cd backend
# Without the ~26MB crawled dogu.db, run against the committed CI fixture:
DOGU_DB_PATH=$PWD/app/data/test_fixture.db pytest
```

```sh
cd app
flutter analyze
flutter test
```

## Seed data (single source of truth)

The catalog seed has one canonical file, `backend/app/data/seed.json`. Two
build-time copies are derived from it (never hand-edited): `app/assets/seed.json`
(the bundled async offline source) and `app/lib/src/bundled_seed.g.dart` (the
same JSON embedded so the app can build its synchronous fallback catalog). Edit
the canonical file, then regenerate the derived copies and commit them:

```sh
python3 scripts/sync_seed.py          # canonical -> app mirror
python3 scripts/sync_seed.py --check  # verify (CI's SSOT guard enforces this)
```

## Notes

- Start the backend before the frontend so Flutter can load `/api/home` from `API_BASE_URL`.
- Local `.env.local` files are for machine-specific values. Keep committed defaults in `.env.local.example`.
- If port `8080` is already in use, stop the existing Flutter process or choose another `--web-port` in `app/scripts/run_local.sh`.
- The Flutter app falls back to local seed data if the backend is unavailable.
- The `/admin` surface and order listing require HTTP Basic auth; set `ADMIN_API_KEY` in `backend/.env.local` to enable them (empty ⇒ admin disabled).
