# Dogu local run

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
pytest
```

```sh
cd app
flutter analyze
flutter test
```

## Notes

- Start the backend before the frontend so Flutter can load `/api/home` from `API_BASE_URL`.
- Local `.env.local` files are for machine-specific values. Keep committed defaults in `.env.local.example`.
- If port `8080` is already in use, stop the existing Flutter process or choose another `--web-port` in `app/scripts/run_local.sh`.
- The Flutter app falls back to local seed data if the backend is unavailable.
