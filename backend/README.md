# Dogu FastAPI backend

Backend for the 욕망의장바구니 (Dogu) shopping app. It serves catalog, home,
search, and newsletter content, accepts orders, and exposes a password-protected
admin surface for editing the seed content. Cart, wishlist, recent searches,
coupons, and payments are handled client-side and are intentionally not part of
this backend.

## Requirements

- Python 3.11+

## Install

```sh
cd backend
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt "pytest>=8,<9" "uvicorn[standard]>=0.30,<1.0"
```

## Run locally

```sh
cd backend
cp .env.local.example .env.local
./scripts/run_local.sh
```

Open `http://127.0.0.1:8000/docs` for the generated API docs.

## Configuration (environment variables)

| Variable | Purpose | Default |
| --- | --- | --- |
| `CORS_ORIGINS` | Comma-separated allowed origins. Set explicitly in production. | `http://localhost:8080,http://127.0.0.1:8080` |
| `ADMIN_API_KEY` | Password for the HTTP Basic-protected `/admin` surface. Empty ⇒ admin disabled (fail closed). | *(empty)* |
| `DOGU_DB_PATH` | SQLite catalog DB. If present it is the read source; otherwise the app falls back to `app/data/seed.json`. | `app/data/dogu.db` |
| `DOGU_STATE_DIR` | Writable dir for mutable state (orders DB + admin seed overrides). Point at a persistent path/volume for durability. | system temp dir |

## Endpoints

Public:

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
- `POST /api/orders`
- `GET /api/proxy/image` — proxies whitelisted Naver image hosts

Admin (HTTP Basic, user `admin`, password `ADMIN_API_KEY`):

- `GET /admin` — admin HTML page
- `GET /api/orders` — list submitted orders
- `GET /api/manage/seed` — read current seed content
- `POST /api/manage/seed` — save seed content (written to the writable override)

## Data source

Catalog responses come from the SQLite DB at `DOGU_DB_PATH` when it exists; if it
is absent the app serves the small `app/data/seed.json` stub (product IDs
`p01`, `p02`, …). The full crawled DB (`dogu.db`, ~26 MB) is git-excluded, so
tests and CI run against the committed deterministic fixture
`app/data/test_fixture.db` (regenerate with `scripts/make_test_fixture.py`).

Mutable state (orders, admin seed edits) is stored separately under
`DOGU_STATE_DIR`, never written back into the read-only bundled data.

## Test

```sh
cd backend
# CI parity (no crawled dogu.db present): use the committed fixture
DOGU_DB_PATH=$PWD/app/data/test_fixture.db pytest
```
