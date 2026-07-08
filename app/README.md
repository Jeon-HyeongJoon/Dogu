# 욕망의장바구니 Flutter mobile tabs

This directory is a Flutter source project for a cross-platform, mobile-first shopping app inspired by `../design/mobile-page.html`, `../design/mobile-category.html`, `../design/mobile-search.html`, `../design/mobile-wish.html`, `../design/mobile-cart.html`, and `../design/mobile.css`.

The implementation keeps the original design DNA: a 390px-like centered mobile canvas on web/desktop, white and soft-gray surfaces, black ink, dark green `#13402d` accents, thin borders, mono-style labels, abstract patterned product placeholders, Korean ecommerce copy, safe-area-aware chrome, and a five-page bottom tab bar for 홈, 카테고리, 검색, 찜, and 장바구니.

## Files

- `pubspec.yaml` declares the Flutter app, logo asset, `http`, and `shared_preferences`.
- `lib/main.dart` contains the safe-area tab shell, five visual pages, design tokens, API models/repository, local persisted app state, fallback seed data, widgets, and custom pattern painters.
- `assets/logo-square.png` is copied from `../design/assets/logo-square.png`.
- `assets/seed.json` and `lib/src/bundled_seed.g.dart` are **generated** from the
  canonical backend seed (`../backend/app/data/seed.json`) for the offline
  instant-paint fallback (the asset is the async source; the `.g.dart` embeds the
  JSON for the synchronous 0ms/last-resort fallback catalog). Do not hand-edit
  them — edit the canonical file and regenerate with `python3 ../scripts/sync_seed.py`
  from the repo root. CI fails if either drifts.

## v2 design (유희왕 마법 카드 테마)

A v2 visual theme — modelled on the "욕망의 항아리 (Pot of Greed)" Yu-Gi-Oh! Spell
card (teal frame, gold trim, cream effect panels, card-frame product tiles,
attribute badges, bracketed type-lines, corner set-codes) — lives alongside v1 and
is reachable at the **`/v2`** route. It is a full five-tab app (홈·카테고리·검색·
찜·장바구니) with a card-styled bottom tab bar, reuses the same data (`AppStore`),
mirrors the v1 layout, and is responsive for mobile and tablet widths. Files:

- `lib/src/v2_theme.dart` — design tokens (`V2Colors`/`V2Space`/`V2Text`) + card-frame component kit.
- `lib/src/v2_home.dart` — v2 home body.
- `lib/src/v2_shell.dart` — v2 shell, bottom tab bar, and the category/search/wish/cart tab bodies.

Finished screens are snapshotted as golden images under `test/goldens/`
(`v2_{home,category,search,wish,cart}_{mobile,tablet}.png`). These golden tests
are tagged `golden` and excluded from CI (font/anti-aliasing rendering differs
across platforms); regenerate them locally with:

```sh
flutter test --update-goldens --tags golden
```

## Backend integration

The app reads catalog/home/search/newsletter data from the FastAPI backend and falls back to local seed data if the network is unavailable, so the five tabs still render offline.

Target endpoints:

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

Local-only state is persisted with `shared_preferences` on Android and web:

- cart product IDs and quantities
- wishlist product IDs
- recent searches

Coupons, auth, payment, and checkout submission are intentionally out of scope; the cart tab only summarizes local cart contents.

### API base URL

By default the Flutter app uses:

- mobile web: `http://localhost:8000`
- Android emulator: `http://10.0.2.2:8000`

For local web testing, keep the backend URL in `app/.env.local` and use the local runner:

```sh
cp .env.local.example .env.local
./scripts/run_local.sh
```

The runner reads `API_BASE_URL` from `.env.local` and passes it to Flutter with `--dart-define`. Override native targets directly when needed:

```sh
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Generate platform runners

If this checkout does not yet have platform folders, install Flutter and run this inside `app`:

```sh
flutter create .
```

That generates iOS, Android, Web, macOS, Windows, and Linux runners around the existing `pubspec.yaml` and `lib/main.dart` source files.

## Verify locally

Verify with:

```sh
flutter pub get
flutter analyze
flutter test
./scripts/run_local.sh
```

For native targets, select an installed device or simulator with `flutter devices`, then run `flutter run -d <device-id>`.
