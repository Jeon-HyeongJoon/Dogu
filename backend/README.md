# Dogu FastAPI backend

Seed-data backend for the 욕망의장바구니 (Dogu) shopping app. It serves catalog, home, search, and newsletter content only. Cart, wishlist, recent searches, auth, coupons, and payments intentionally remain outside this backend.

## Requirements

- Python 3.11+

## Install

```sh
cd backend
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt "uvicorn[standard]>=0.30,<1.0"
```

## Run locally

```sh
cd backend
cp .env.local.example .env.local
./scripts/run_local.sh
```

`backend/.env.local` configures CORS for the local Flutter web app on `http://127.0.0.1:8080` and `http://localhost:8080`.

Open `http://127.0.0.1:8000/docs` for the generated API docs.

## Test

```sh
cd backend
pytest
```

## Endpoints

- `GET /health`
- `GET /api/home`
- `GET /api/categories`
- `GET /api/products`
- `GET /api/products/{product_id}`
- `GET /api/search`
- `GET /api/search/trending`
- `GET /api/search/suggestions`
- `GET /api/newsletter`
- `POST /api/newsletter/subscribe`

## Data source

All API responses are derived from `app/data/seed.json`, using stable product IDs (`p01`, `p02`, ...). The seed is based on the existing Dogu frontend/design content.
