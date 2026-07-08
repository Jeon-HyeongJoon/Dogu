# 욕망의장바구니 Flutter mobile tabs

This directory is a Flutter source project for a cross-platform, mobile-first shopping app inspired by `../design/mobile-page.html`, `../design/mobile-category.html`, `../design/mobile-search.html`, `../design/mobile-wish.html`, `../design/mobile-cart.html`, and `../design/mobile.css`.

The implementation keeps the original design DNA: a 390px-like centered mobile canvas on web/desktop, white and soft-gray surfaces, black ink, dark green `#13402d` accents, thin borders, mono-style labels, abstract patterned product placeholders, Korean ecommerce copy, safe-area-aware chrome, and a five-page bottom tab bar for 홈, 카테고리, 검색, 찜, and 장바구니.

## Files

- `pubspec.yaml` declares the Flutter app, logo asset, `http`, and `shared_preferences`.
- `lib/main.dart` contains the safe-area tab shell, five visual pages, design tokens, API models/repository, local persisted app state, fallback seed data, widgets, and custom pattern painters.
- `assets/logo-square.png` is copied from `../design/assets/logo-square.png`.

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
