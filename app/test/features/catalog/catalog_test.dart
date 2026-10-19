import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/fakes.dart';
import '../../support/harness.dart';

void main() {
  setUpDoguTest();

  test('ProductItem parses optional product image URLs from backend payloads', () {
    final product = ProductItem.fromJson(const {
      'id': 'remote-vase',
      'brand': 'Objet',
      'name': '세라믹 베이스',
      'price': 42000,
      'image_url': 'https://cdn.example.test/vase.png',
    });

    expect(product.imageUrl, 'https://cdn.example.test/vase.png');
  });

  test('ProductItem parses backend detail fields and artwork metadata', () {
    final product = ProductItem.fromJson(const {
      'id': 'p01',
      'name': '폴더블 무선 충전 거치대 3 in 1',
      'subtitle': '아이폰·워치·에어팟 동시충전',
      'brand': 'NovaTech',
      'category_ids': ['gadget'],
      'price': 24900,
      'old_price': 49000,
      'discount_percent': 49,
      'badge': 'BEST',
      'rating': 4.8,
      'reviews': 12840,
      'blurb': '한 번에 세 기기를 충전.',
      'tags': ['new_arrival', 'best'],
      'artwork': {'hue': 220, 'saturation': 25, 'lightness': 70, 'mono': '⌬', 'motif': 'circle'}
    });

    expect(product.subtitle, '아이폰·워치·에어팟 동시충전');
    expect(product.categoryIds, ['tech']);
    expect(product.rating, 4.8);
    expect(product.reviews, 12840);
    expect(product.blurb, '한 번에 세 기기를 충전.');
    expect(product.tags, ['new_arrival', 'best']);
    expect(product.artwork?.mono, '⌬');
    expect(product.artwork?.motif, 'circle');
  });

  // ── [ssot] 카테고리 키 매핑 단일 원천 ──
  // raw seed id·영문 키·한글 표시명이 모두 하나의 정규 키로 매핑되는지 public API로 고정.
  // (과거 `_categoryKeyFromName` 중복 구현은 스포츠/키즈 한글명을 누락했다 — 통일 후 회귀 방지.)
  test('normalizes every category alias to its canonical key via ProductItem.fromJson', () {
    const expected = <String, String>{
      'fashion': 'clothing',
      'clothing': 'clothing',
      '의류': 'clothing',
      'gadget': 'tech',
      'tech': 'tech',
      '전자제품': 'tech',
      'home': 'home',
      'home_living': 'home',
      '홈·리빙': 'home',
      'beauty': 'beauty',
      '뷰티': 'beauty',
      'sports': 'sports',
      '스포츠': 'sports',
      'kids': 'kids',
      '키즈': 'kids',
    };
    expected.forEach((alias, key) {
      final product = ProductItem.fromJson({
        'id': 'p-$alias',
        'name': 'x',
        'brand': 'y',
        'price': 1000,
        'category_ids': [alias],
      });
      expect(product.categoryIds, [key], reason: 'alias "$alias" should normalize to "$key"');
      expect(product.categoryKey, key, reason: 'categoryKey for "$alias" should be "$key"');
    });
  });

  test('unknown category alias falls back to its lowercased raw value', () {
    final product = ProductItem.fromJson(const {
      'id': 'p-unknown',
      'name': 'x',
      'brand': 'y',
      'price': 1000,
      'category_ids': ['GARDEN'],
    });
    expect(product.categoryIds, ['garden']);
  });

  // ── [ssot] instant-paint fallback 카탈로그는 단일 원천 seed.json에서 파생 ──
  // (과거엔 seed 상품을 손으로 옮겨 적은 const 리스트였다 — 이제 임베드 seed에서 파생해 중복 제거.)
  group('fallback catalog derives from the single seed source', () {
    test('fallback lists are non-empty (0ms paint + last-resort safety)', () {
      expect(fallbackCategories, isNotEmpty);
      expect(fallbackDealProducts, isNotEmpty);
      expect(fallbackNewProducts, isNotEmpty);
    });

    test('fallback products carry seed product ids, not hand-authored ones', () {
      // seed.json uses p01.. ids; the old transcription used deal-/new- ids.
      expect(fallbackDealProducts.every((p) => p.id.startsWith('p')), isTrue);
      expect(fallbackNewProducts.every((p) => p.id.startsWith('p')), isTrue);
    });

    test('fallback categories are exactly the seed category set', () {
      expect(
        fallbackCategories.map((c) => c.id).toSet(),
        {'gadget', 'home', 'fashion', 'beauty', 'sports', 'kids'},
      );
    });
  });

  // ── TDD P3-2: API timeout 차등 설정 ──────────────────────────────────────────

  testWidgets('checkHealth times out after 1.5 s not the old 4 s', (tester) async {
    final repo = DoguRepository(client: SlowHttpClient());
    var threw = false;
    repo.checkHealth().catchError((_) { threw = true; }); // ignore: unawaited_futures

    await tester.pump(const Duration(seconds: 1));
    expect(threw, isFalse); // 1 s < 1.5 s timeout

    await tester.pump(const Duration(milliseconds: 600)); // 누적 1.6 s
    expect(threw, isTrue);  // 1.6 s > 1.5 s → 타임아웃
  });

  testWidgets('fetchHome does not time out at 5 s but times out by 7 s', (tester) async {
    final repo = DoguRepository(client: SlowHttpClient());
    var threw = false;
    repo.fetchHome().catchError((_) { threw = true; return const <String, dynamic>{}; }); // ignore: unawaited_futures

    await tester.pump(const Duration(seconds: 5));
    expect(threw, isFalse); // 5 s < 6 s home timeout

    await tester.pump(const Duration(seconds: 2)); // 누적 7 s
    expect(threw, isTrue);  // 7 s > 6 s → 타임아웃
  });

  testWidgets('fetchProducts times out after 3 s not the old 4 s', (tester) async {
    final repo = DoguRepository(client: SlowHttpClient());
    var threw = false;
    repo.fetchProducts().catchError((_) { threw = true; return const <ProductItem>[]; }); // ignore: unawaited_futures

    await tester.pump(const Duration(seconds: 2));
    expect(threw, isFalse); // 2 s < 3 s timeout

    await tester.pump(const Duration(milliseconds: 1500)); // 누적 3.5 s
    expect(threw, isTrue);  // 3.5 s > 3 s (< 4 s old timeout) → currently FAILS
  });

  // ── TDD P3-3: allProducts getter 캐시화 ──────────────────────────────────────

  test('allProducts returns same instance on repeated calls without data change', () {
    final store = AppStore(repository: FakeRepository(results: const []));
    final first = store.allProducts;
    final second = store.allProducts;
    expect(identical(first, second), isTrue); // currently FAILS: 매번 새 리스트 생성
  });

  test('allProducts recomputes and returns new instance after notifyListeners', () {
    final store = AppStore(repository: FakeRepository(results: const []));
    store.usingFallback = false;
    store.catalogProducts = const [];
    store.newProducts = const [];
    store.dealProducts = const [];

    final before = store.allProducts; // empty

    store.newProducts = const [
      ProductItem(id: 'cache-p1', brand: 'B', name: 'N', price: '₩1', oldPrice: '₩1', discount: '-0%', pattern: PatternKind.dots),
    ];
    store.notifyListeners(); // 캐시 무효화

    final after = store.allProducts;
    expect(identical(before, after), isFalse);
    expect(after.any((p) => p.id == 'cache-p1'), isTrue);
  });

  // ── [serverless] s1a: 번들 seed 로더 (네트워크 없이 로컬 asset에서 카탈로그 적재) ──
  test('LocalSeedSource loads the full product catalog from the bundled asset', () async {
    final products = await LocalSeedSource().fetchProducts();
    expect(products.length, 12);
    expect(products.every((p) => p.id.isNotEmpty && p.name.isNotEmpty), isTrue);
  });

  test('LocalSeedSource loads all categories from the bundled asset', () async {
    final categories = await LocalSeedSource().fetchCategories();
    expect(categories.length, 6);
  });

  test('LocalSeedSource home resolves deal/new/featured product references', () async {
    final home = await LocalSeedSource().fetchHome();
    expect(home['hero'], isNotNull);
    expect((home['deal_products'] as List), isNotEmpty);
    expect((home['new_products'] as List), isNotEmpty);
    expect(home['featured_product'], isNotNull);
    // resolved entries must be full product maps, not bare id strings
    expect((home['deal_products'] as List).first, isA<Map>());
    expect(((home['deal_products'] as List).first as Map)['name'], isNotNull);
  });

  test('LocalSeedSource section/category filters work offline', () async {
    final source = LocalSeedSource();
    final deals = await source.fetchProducts(section: 'deals');
    final clothing = await source.fetchProducts(categoryId: 'clothing');
    expect(deals, isNotEmpty);
    expect(deals.every((p) => p.tags.contains('today_deal')), isTrue);
    expect(clothing, isNotEmpty);
    expect(clothing.every((p) => p.categoryIds.contains('clothing')), isTrue);
  });

  test('LocalSeedSource loads trending, suggestions and newsletter offline', () async {
    final source = LocalSeedSource();
    expect(await source.fetchTrending(), isNotEmpty);
    expect(await source.fetchSuggestions(), isNotEmpty);
    final newsletter = await source.fetchNewsletter();
    expect(newsletter['title'], isNotNull);
  });

  test('LocalSeedSource normalizes raw category ids when filtering (gadget→tech)', () async {
    final source = LocalSeedSource();
    final gadget = await source.fetchProducts(categoryId: 'gadget'); // raw seed id
    final tech = await source.fetchProducts(categoryId: 'tech'); // normalized key
    expect(gadget, isNotEmpty);
    expect(gadget.length, tech.length); // raw and normalized resolve to the same set
  });

  test('LocalSeedSource respects limit boundaries without throwing', () async {
    final source = LocalSeedSource();
    expect(await source.fetchProducts(limit: 0), isEmpty);
    expect((await source.fetchProducts(limit: 3)).length, 3);
    expect(await source.fetchProducts(limit: -5), isEmpty); // no RangeError
  });

  test('LocalSeedSource skips missing product references and absent featured id', () async {
    final bundle = StubAssetBundle(jsonEncode({
      'categories': [],
      'products': [
        {'id': 'a', 'name': 'A', 'category_ids': <String>[], 'tags': <String>[]},
      ],
      'home': {
        'hero': {'title': 'H'},
        'deal_product_ids': ['a', 'ghost'], // 'ghost' does not exist
        'new_product_ids': <String>[],
        // featured_product_id intentionally absent
        'collections': [],
      },
      'trending': [],
      'suggestions': [],
      'newsletter': {'title': 'N'},
    }));
    final source = LocalSeedSource(bundle: bundle);
    final home = await source.fetchHome();
    expect((home['deal_products'] as List).length, 1); // ghost skipped
    expect(home['featured_product'], isNull); // absent id resolves to null, not a throw
  });

  test('LocalSeedSource fetchHome preserves editorial and brands passthrough', () async {
    final home = await LocalSeedSource().fetchHome();
    expect(home.containsKey('editorial'), isTrue);
    expect(home.containsKey('brands'), isTrue);
  });

  // ── [serverless] s1b: AppStore가 네트워크 없이 번들 seed로 카탈로그를 채운다 ──
  // (순수 비동기 + 실제 asset I/O라 testWidgets의 fake-time 존이 아닌 plain test 사용)
  test('AppStore.initialize populates full catalog from bundled seed without network', () async {
    // 네트워크가 끊겨도(연결 거부되는 기본 클라이언트) 번들 seed로 완전한 카탈로그가 채워져야 함
    final store = AppStore(repository: FakeRepository(results: const [], shouldThrow: true));
    await store.initialize();
    expect(store.usingFallback, isFalse);
    expect(store.catalogProducts.length, 12);
    expect(store.categories.length, 6);
    expect(store.featuredProduct, isNotNull);
    expect(store.dealProducts, isNotEmpty);
    expect(store.newProducts, isNotEmpty);
    expect(store.heroTitle, isNotEmpty);
    store.dispose();
  });

  test('AppStore.initialize falls back to safe data when the bundled seed is invalid', () async {
    final store = AppStore(
      repository: FakeRepository(results: const [], shouldThrow: true),
      seedSource: LocalSeedSource(bundle: StubAssetBundle('this is not valid json')),
    );
    await store.initialize();
    expect(store.usingFallback, isTrue);
    expect(store.catalogProducts, isNotEmpty); // 손상 seed에도 fallback 보호 데이터 유지
    store.dispose();
  });

  // ── [perf] perf2: instant-paint 하이브리드 — 번들 seed로 즉시 채운 뒤 백엔드 최신 데이터로 덮어쓴다 ──
  test('AppStore.initialize paints bundled seed first, then overlays fresh backend data', () async {
    final fresh = ProductItem(
      id: 'backend-fresh', brand: 'NET', name: '백엔드 신상품',
      price: '₩1,000', oldPrice: '₩2,000', discount: '-50%', pattern: PatternKind.dots,
    );
    final store = AppStore(
      seedSource: LocalSeedSource(), // 번들 → 즉시 12개로 첫 페인트
      repository: FakeRepository(
        backendHome: const {'hero': {'title': '백엔드에서 온 타이틀'}},
        backendProducts: [fresh],
      ),
    );
    await store.initialize();
    expect(store.usingFallback, isFalse);
    expect(store.catalogLoading, isFalse);
    expect(store.catalogProducts.any((p) => p.id == 'backend-fresh'), isTrue,
        reason: '백엔드 최신 카탈로그가 번들 seed를 덮어씀');
    expect(store.heroTitle, '백엔드에서 온 타이틀', reason: '백엔드 hero로 갱신');
  });

  test('AppStore.initialize keeps bundled seed when backend refresh fails (offline)', () async {
    final store = AppStore(
      seedSource: LocalSeedSource(),
      repository: FakeRepository(shouldThrow: true), // 백엔드 다운
    );
    await store.initialize();
    // 백엔드 갱신 실패해도 번들 seed로 정상 동작 — 로딩 표시도 끝나고 seed 카테고리를 보여준다.
    expect(store.usingFallback, isFalse);
    expect(store.catalogProducts.length, 12);
    expect(store.catalogLoading, isFalse);
    expect(store.categories.map((c) => c.id), containsAll(['gadget', 'fashion']));
  });

  test('AppStore.catalogLoading stays true until the backend answers', () async {
    final gate = Completer<void>();
    final store = AppStore(seedSource: LocalSeedSource(), repository: GatedRepository(gate.future));
    final init = store.initialize();
    await pumpEventQueue();

    // 번들 seed는 이미 들어왔지만 백엔드는 아직 — 카테고리 칸은 로딩 표시.
    expect(store.catalogLoading, isTrue);
    expect(store.categories, isNotEmpty);

    gate.complete();
    await init;
    expect(store.catalogLoading, isFalse);
  });
}
