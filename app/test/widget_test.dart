import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:dogu_mobile_shop/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProductItem homeProduct;
  late ProductItem searchProduct;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    homeProduct = const ProductItem(
      id: 'home-soft-knit',
      brand: 'HOME',
      name: '홈 니트',
      price: '₩39,000',
      oldPrice: '₩49,000',
      discount: '-20%',
      pattern: PatternKind.dots,
    );
    searchProduct = const ProductItem(
      id: 'search-lamp',
      brand: 'SEARCH',
      name: '검색 램프',
      price: '₩79,000',
      oldPrice: '₩99,000',
      discount: '-20%',
      pattern: PatternKind.grid,
    );
  });

  test('performSearch keeps home catalog and stores dedicated search results', () async {
    final store = AppStore(repository: _FakeRepository(results: [searchProduct]));
    store.newProducts = [homeProduct];

    await store.performSearch('램프');

    expect(store.recentSearches.first, '램프');
    expect(store.newProducts.map((item) => item.id), ['home-soft-knit']);
    expect(store.searchResults.map((item) => item.id), ['search-lamp']);
    expect(store.lastSearchTerm, '램프');
  });

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

  testWidgets('DoguApp applies the bundled Korean font family', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));

    await tester.pumpWidget(DoguApp(store: store, initializeStore: false));

    final theme = Theme.of(tester.element(find.byType(AppShell)));
    expect(theme.textTheme.bodyMedium?.fontFamily, doguFontFamily);
  });

  // ── [ui] 폰트 적용: 브랜드 타이틀=둥근 고딕(NanumSquareRound), 광고 헤드라인=각진 Pretendard ──
  testWidgets('brand title uses rounded font; hero headline uses the angular base font', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.dealProducts = const [];
    await tester.pumpWidget(DoguApp(store: store, initializeStore: false));

    // 상단 브랜드 타이틀은 둥근 굴림체(NanumSquareRound)
    final brandTitle = tester.widget<Text>(find.text('욕망의 장바구니'));
    expect(brandTitle.style?.fontFamily, doguHeroFontFamily);

    // 광고 메인 문구(44px 헤드라인)는 각진 기본 폰트(Pretendard)
    final heroHeadline = tester
        .widgetList<Text>(find.byType(Text))
        .firstWhere((t) => t.style?.fontSize == 44);
    expect(heroHeadline.style?.fontFamily, doguFontFamily);
  });

  testWidgets('product cards render the reusable fallback image surface without image URLs', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: ProductCard(product: ProductItem(
                  id: 'fallback-card',
                  brand: 'Fallback',
                  name: '기본 이미지 상품',
                  price: '₩10,000',
                  oldPrice: '₩12,000',
                  discount: '-16%',
                  pattern: PatternKind.lines,
                )),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PreparingImageSurface), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is Image && widget.image is NetworkImage), findsNothing);
  });

  testWidgets('product cards prefer network images when image URLs exist', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: ProductCard(product: ProductItem(
                  id: 'network-card',
                  brand: 'Remote',
                  name: '원격 이미지 상품',
                  price: '₩10,000',
                  oldPrice: '₩12,000',
                  discount: '-16%',
                  pattern: PatternKind.grid,
                  imageUrl: 'https://cdn.example.test/product.png',
                )),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byWidgetPredicate((widget) => widget is Image && widget.image is NetworkImage), findsOneWidget);
  });

  testWidgets('product image surface shows the unified preparing placeholder when image url is absent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 220,
            child: ProductImageSurface(
              pattern: PatternKind.grid,
              artwork: const ProductArtwork(hue: 220, saturation: 25, lightness: 70, mono: '⌬', motif: 'circle'),
              child: const Center(child: Text('Artwork overlay')),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PreparingImageSurface), findsOneWidget);
    expect(find.text('이미지 준비 중'), findsOneWidget);
    expect(find.text('Artwork overlay'), findsOneWidget);
  });

  testWidgets('product image surface preserves fallback overlay when network image loading fails', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 220,
            child: ProductImageSurface(
              pattern: PatternKind.grid,
              imageUrl: 'https://cdn.example.test/broken.png',
              child: Center(child: Text('Overlay label')),
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image).first);
    final fallback = image.errorBuilder!(tester.element(find.byType(Image).first), Exception('broken'), StackTrace.empty);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: fallback),
      ),
    );

    expect(find.byType(PreparingImageSurface), findsOneWidget);
    expect(find.text('Overlay label'), findsOneWidget);
    expect(find.text('이미지 준비 중'), findsOneWidget);
  });

  testWidgets('product image surface shows fallback while network image is still loading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 220,
            child: ProductImageSurface(
              pattern: PatternKind.diag,
              imageUrl: 'https://cdn.example.test/loading.png',
              child: Center(child: Text('Loading overlay')),
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image).first);
    final loadingFallback = image.loadingBuilder!(
      tester.element(find.byType(Image).first),
      const SizedBox.shrink(),
      const ImageChunkEvent(cumulativeBytesLoaded: 1, expectedTotalBytes: 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: loadingFallback),
      ),
    );

    expect(find.byType(PreparingImageSurface), findsOneWidget);
    expect(find.text('Loading overlay'), findsOneWidget);
  });

  testWidgets('category and promo surfaces use neutral placeholders without pattern boxes', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2600);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AppStore(repository: _FakeRepository(results: const []));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  FeaturedCard(),
                  SizedBox(height: 220, child: CategoryCard(index: 1, item: CategoryItem('의류', '12', PatternKind.dots))),
                  EditorialSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(NeutralImageSurface), findsNWidgets(2));
    expect(find.byType(PatternBox), findsNothing);
    expect(find.textContaining('// linen overshirt'), findsNothing);
    expect(find.textContaining('// editorial spread'), findsNothing);
  });

  testWidgets('tapping a product card opens product detail page', (tester) async {
    final detailProduct = const ProductItem(
      id: 'detail-card',
      brand: 'DETAIL',
      name: '상세 페이지 상품',
      price: '₩55,000',
      oldPrice: '₩75,000',
      discount: '-27%',
      pattern: PatternKind.diag,
      meta: '4.9 · 120 reviews',
    );
    final store = AppStore(repository: _FakeRepository(detailProduct: detailProduct));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 220, child: ProductCard(product: ProductItem(
                id: 'detail-card',
                brand: 'DETAIL',
                name: '상세 페이지 상품',
                price: '₩55,000',
                oldPrice: '₩75,000',
                discount: '-27%',
                pattern: PatternKind.diag,
                meta: '4.9 · 120 reviews',
              ))),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('상세 페이지 상품'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailPage), findsOneWidget);
    expect(find.text('상세 페이지 상품'), findsWidgets);
    expect(find.text('DETAIL'), findsWidgets);
    expect(find.text('장바구니 담기'), findsOneWidget);
  });

  testWidgets('featured card opens the backend featured product detail page', (tester) async {
    final featured = const ProductItem(
      id: 'featured-1',
      brand: 'FEATURED',
      name: '특집 상품',
      price: '₩88,000',
      oldPrice: '₩120,000',
      discount: '-27%',
      pattern: PatternKind.diag,
    );
    final store = AppStore(repository: _FakeRepository(detailProduct: featured));
    store.featuredProduct = featured;

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1400);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: FeaturedCard()),
          ),
        ),
      ),
    );

    await tester.tap(find.text('특집 상품'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailPage), findsOneWidget);
    expect(find.text('특집 상품'), findsWidgets);
  });

  testWidgets('recommended and deal sections hide when backend-driven data is empty', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.dealProducts = const [];
    store.recommendedProducts = const [];

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [DealSection(), RecommendedCartBlock()],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('오늘의 딜'), findsNothing);
    expect(find.text('[ → ] 함께 담으면 좋은'), findsNothing);
  });

  testWidgets('product detail refreshes with fetched product data by id', (tester) async {
    final fetchedProduct = const ProductItem(
      id: 'detail-fetch',
      brand: 'FETCHED',
      name: '서버 상세 상품',
      price: '₩88,000',
      oldPrice: '₩120,000',
      discount: '-27%',
      pattern: PatternKind.grid,
      meta: '4.8 · fetched',
    );
    final store = AppStore(repository: _FakeRepository(detailProduct: fetchedProduct));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: MaterialApp(
          home: ProductDetailPage(
            product: const ProductItem(
              id: 'detail-fetch',
              brand: 'LOCAL',
              name: '로컬 상품',
              price: '₩10,000',
              oldPrice: '₩12,000',
              discount: '-16%',
              pattern: PatternKind.lines,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('서버 상세 상품'), findsOneWidget);
    expect(find.text('FETCHED'), findsWidgets);
  });

  testWidgets('product detail keeps local product when fetch fails', (tester) async {
    final store = AppStore(repository: _FakeRepository(shouldThrowDetail: true));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: MaterialApp(
          home: ProductDetailPage(
            product: const ProductItem(
              id: 'detail-fallback',
              brand: 'LOCAL',
              name: '로컬 유지 상품',
              price: '₩10,000',
              oldPrice: '₩12,000',
              discount: '-16%',
              pattern: PatternKind.lines,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('로컬 유지 상품'), findsOneWidget);
    expect(find.text('LOCAL'), findsWidgets);
  });

  testWidgets('wishlist tap on product card does not open detail page', (tester) async {
    final product = const ProductItem(
      id: 'wish-only',
      brand: 'DETAIL',
      name: '찜 전용 상품',
      price: '₩15,000',
      oldPrice: '₩20,000',
      discount: '-25%',
      pattern: PatternKind.cross,
    );
    final store = AppStore(repository: _FakeRepository(detailProduct: product));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 220, child: ProductCard(product: ProductItem(
                id: 'wish-only',
                brand: 'DETAIL',
                name: '찜 전용 상품',
                price: '₩15,000',
                oldPrice: '₩20,000',
                discount: '-25%',
                pattern: PatternKind.cross,
              ))),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('WISH +'));
    await tester.pumpAndSettle();

    expect(store.wishlistIds.contains('wish-only'), isTrue);
    expect(find.byType(ProductDetailPage), findsNothing);
  });

  test('performSearch keeps successful empty backend results empty', () async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.newProducts = [searchProduct];

    await store.performSearch('램프');

    expect(store.lastSearchTerm, '램프');
    expect(store.searchResults, isEmpty);
  });

  test('performSearch falls back to local results when repository throws', () async {
    final store = AppStore(repository: _FakeRepository(results: const [], shouldThrow: true));
    store.catalogProducts = [searchProduct];
    store.newProducts = [searchProduct];
    store.dealProducts = const [];

    await store.performSearch('램프');

    expect(store.lastSearchTerm, '램프');
    expect(store.searchResults.map((item) => item.id), ['search-lamp']);
  });

  test('performSearch ignores stale results from earlier in-flight searches', () async {
    final knitCompleter = Completer<List<ProductItem>>();
    final lampCompleter = Completer<List<ProductItem>>();
    final store = AppStore(
      repository: _FakeRepository(
        searchHandler: (query) {
          switch (query) {
            case '니트':
              return knitCompleter.future;
            case '램프':
              return lampCompleter.future;
            default:
              throw Exception('unexpected query: $query');
          }
        },
      ),
    );
    store.newProducts = [homeProduct, searchProduct];
    store.dealProducts = const [];

    final first = store.performSearch('니트');
    final second = store.performSearch('램프');

    lampCompleter.complete([searchProduct]);
    await second;

    knitCompleter.complete([homeProduct]);
    await first;

    expect(store.lastSearchTerm, '램프');
    expect(store.searchResults.map((item) => item.id), ['search-lamp']);
  });

  test('resetSearch prevents pending search from restoring cancelled results', () async {
    final lampCompleter = Completer<List<ProductItem>>();
    final store = AppStore(
      repository: _FakeRepository(searchHandler: (_) => lampCompleter.future),
    );
    store.newProducts = [searchProduct];
    store.dealProducts = const [];

    final pending = store.performSearch('램프');
    await Future<void>.delayed(Duration.zero);
    store.resetSearch();
    lampCompleter.complete([searchProduct]);
    await pending;

    expect(store.lastSearchTerm, isEmpty);
    expect(store.searchResults, isEmpty);
  });

  testWidgets('search submission renders results in the search tab', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: [searchProduct]));
    store.newProducts = [homeProduct];

    await tester.pumpWidget(
      DoguApp(
        store: store,
        initializeStore: false,
        initialTabIndex: 2,
      ),
    );

    await tester.enterText(find.byType(TextField), '램프');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('검색 결과'), findsOneWidget);
    expect(find.text('검색 램프'), findsOneWidget);
    expect(find.text('홈 니트'), findsNothing);
    expect(find.textContaining('램프'), findsWidgets);
  });

  testWidgets('category quick filters update their active visual state on tap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuickFilterRow(items: ['전체  12', '신상', '베스트']),
        ),
      ),
    );

    Text activeText(String label) {
      final containers = tester.widgetList<Container>(
        find.ancestor(of: find.text(label), matching: find.byType(Container)),
      );
      final container = containers.firstWhere(
        (widget) => widget.decoration is BoxDecoration && (widget.decoration! as BoxDecoration).color != null,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.accent);
      return tester.widget<Text>(find.text(label));
    }

    expect(activeText('전체  12').style!.color, AppColors.invert);

    await tester.tap(find.text('베스트'));
    await tester.pumpAndSettle();

    expect(activeText('베스트').style!.color, AppColors.invert);
    final previous = tester.widget<Text>(find.text('전체  12'));
    expect(previous.style!.color, AppColors.ink2);
  });

  testWidgets('category card tap opens category tab and shows filtered product list', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.categories = const [
      CategoryItem('의류', '12', PatternKind.dots),
      CategoryItem('홈·리빙', '9', PatternKind.grid),
    ];
    store.newProducts = const [
      ProductItem(id: 'cloth-1', brand: 'CLOTH', name: '코튼 셔츠', price: '₩10,000', oldPrice: '₩12,000', discount: '-16%', pattern: PatternKind.lines, categoryKey: 'clothing'),
      ProductItem(id: 'home-1', brand: 'HOME', name: '세라믹 머그', price: '₩20,000', oldPrice: '₩24,000', discount: '-16%', pattern: PatternKind.grid, categoryKey: 'home'),
    ];
    store.dealProducts = const [];

    await tester.pumpWidget(DoguApp(store: store, initializeStore: false));

    await tester.tap(find.text('의류').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const PageStorageKey('category-tab')), findsOneWidget);
    expect(find.text('← 전체 카테고리'), findsOneWidget);
    expect(find.text('코튼 셔츠'), findsOneWidget);
    expect(find.text('세라믹 머그'), findsNothing);
    expect(find.text('홈·리빙'), findsNothing);
  });

  testWidgets('top nav items navigate into category browse results', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.newProducts = const [
      ProductItem(id: 'best-1', brand: 'BEST', name: '베스트 상품', price: '₩10,000', oldPrice: '₩12,000', discount: '-16%', pattern: PatternKind.lines, badge: 'BEST'),
      ProductItem(id: 'new-1', brand: 'NEW', name: '신상품 항목', price: '₩20,000', oldPrice: '₩24,000', discount: '-16%', pattern: PatternKind.grid, badge: 'NEW'),
    ];
    store.dealProducts = const [];

    await tester.pumpWidget(DoguApp(store: store, initializeStore: false));

    await tester.tap(find.byType(NavLabel).at(1));
    await tester.pumpAndSettle();

    expect(find.byKey(const PageStorageKey('category-tab')), findsOneWidget);
    expect(store.categoryQuickFilter, 'best');
  });

  testWidgets('hero block renders backend-driven promo text from store state', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.heroEyebrow = '● TEST DROP';
    store.heroDate = '06.01 — 06.15';
    store.heroTitle = '관리페이지에서 바꾼\n광고 문구';
    store.heroSubtitle = '관리페이지 수정 내용이 앱에도 반영됩니다.';
    store.heroPrimaryAction = 'test 이번 드랍 보기 →';
    store.heroSecondaryAction = '보조 액션';
    store.heroStats = const [('99', '상품'), ('7', '브랜드')];

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: HeroBlock())),
      ),
    );

    expect(find.text('● TEST DROP'), findsOneWidget);
    expect(find.text('06.01 — 06.15'), findsOneWidget);
    expect(find.text('관리페이지에서 바꾼\n광고 문구'), findsOneWidget);
    expect(find.text('관리페이지 수정 내용이 앱에도 반영됩니다.'), findsOneWidget);
    expect(find.text('test 이번 드랍 보기 →'), findsOneWidget);
    expect(find.text('보조 액션'), findsOneWidget);
  });

  testWidgets('recent search tags run searches through the app store', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: [searchProduct]));
    store.recentSearches = const ['램프'];
    store.trendingTerms = const ['머그'];
    store.suggestions = const ['SEARCH'];

    await tester.pumpWidget(
      DoguApp(
        store: store,
        initializeStore: false,
        initialTabIndex: 2,
      ),
    );

    await tester.tap(find.text('램프'));
    await tester.pumpAndSettle();

    expect(store.lastSearchTerm, '램프');
    expect(find.text('검색 램프'), findsOneWidget);
  });

  testWidgets('recent search x removes only that search term', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.recentSearches = const ['램프', '머그'];

    await tester.pumpWidget(
      DoguApp(
        store: store,
        initializeStore: false,
        initialTabIndex: 2,
      ),
    );

    await tester.tap(find.byKey(const Key('recent-remove-램프')));
    await tester.pumpAndSettle();

    expect(store.recentSearches, ['머그']);
    expect(find.text('램프'), findsNothing);
  });

  testWidgets('trending list renders backend movement labels', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.trendingItems = const [
      SearchTrend(term: '머그', movement: '▲ 5'),
      SearchTrend(term: '선풍기', movement: 'NEW'),
    ];

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: TrendingBlock())),
      ),
    );

    expect(find.text('머그'), findsOneWidget);
    expect(find.text('▲ 5'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
  });

  testWidgets('wishlist sale filter narrows items and shows an empty state', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.newProducts = const [
      ProductItem(
        id: 'wish-sale',
        brand: 'SALE',
        name: '세일 상품',
        price: '₩10,000',
        oldPrice: '₩20,000',
        discount: '-50%',
        pattern: PatternKind.dots,
      ),
      ProductItem(
        id: 'wish-regular',
        brand: 'REGULAR',
        name: '정가 상품',
        price: '₩20,000',
        oldPrice: '₩20,000',
        discount: '-0%',
        pattern: PatternKind.grid,
      ),
    ];
    store.dealProducts = const [];
    store.wishlistIds = {'wish-sale', 'wish-regular'};

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: WishTabPage(bottomPadding: 0))),
      ),
    );

    expect(find.text('세일 상품'), findsOneWidget);
    expect(find.text('정가 상품'), findsOneWidget);

    await tester.tap(find.text('세일 중'));
    await tester.pumpAndSettle();

    expect(find.text('세일 상품'), findsOneWidget);
    expect(find.text('정가 상품'), findsNothing);

    await tester.tap(find.text('♥'));
    await tester.pumpAndSettle();

    expect(find.text('세일 중인 찜 상품이 없습니다.'), findsOneWidget);
  });

  testWidgets('cart selection controls totals checkout and empty state locally', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.newProducts = const [
      ProductItem(
        id: 'cart-a',
        brand: 'CART',
        name: '선택 상품',
        price: '₩10,000',
        oldPrice: '₩20,000',
        discount: '-50%',
        pattern: PatternKind.dots,
      ),
      ProductItem(
        id: 'cart-b',
        brand: 'CART',
        name: '해제 상품',
        price: '₩30,000',
        oldPrice: '₩30,000',
        discount: '-0%',
        pattern: PatternKind.grid,
      ),
    ];
    store.dealProducts = const [];
    store.cartQuantities = {'cart-a': 1, 'cart-b': 1};

    await tester.pumpWidget(
      DoguApp(
        store: store,
        initializeStore: false,
        initialTabIndex: 4,
      ),
    );

    expect(find.text('2개 상품 선택됨'), findsOneWidget);
    expect(find.text('결제하기 (2)  →'), findsOneWidget);
    expect(find.text('₩40,000'), findsWidgets);

    await tester.tap(find.text('해제 상품'));
    await tester.pumpAndSettle();

    expect(find.text('1개 상품 선택됨'), findsOneWidget);
    expect(find.text('결제하기 (1)  →'), findsOneWidget);
    expect(find.text('₩10,000'), findsWidgets);

    await tester.tap(find.text('모두 선택'));
    await tester.pumpAndSettle();

    expect(find.text('2개 상품 선택됨'), findsOneWidget);
    expect(find.text('결제하기 (2)  →'), findsOneWidget);

    await tester.tap(find.text('모두 선택'));
    await tester.pumpAndSettle();

    expect(find.text('0개 상품 선택됨'), findsOneWidget);
    expect(find.text('결제하기 (0)  →'), findsOneWidget);

    await store.changeCartQuantity('cart-a', -1);
    await store.changeCartQuantity('cart-b', -1);
    await tester.pumpAndSettle();

    expect(find.text('장바구니가 비어 있습니다.'), findsOneWidget);
  });

  testWidgets('checkout button opens bottom payment sheet and completes payment', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.newProducts = const [
      ProductItem(id: 'cart-a', brand: 'CART', name: '선택 상품', price: '₩10,000', oldPrice: '₩20,000', discount: '-50%', pattern: PatternKind.dots),
    ];
    store.cartQuantities = {'cart-a': 2};

    await tester.pumpWidget(DoguApp(store: store, initializeStore: false, initialTabIndex: 4));

    await tester.tap(find.text('결제하기 (2)  →'));
    await tester.pumpAndSettle();

    expect(find.byType(PaymentToastOverlay), findsOneWidget);
    expect(find.text('결제 진행'), findsOneWidget);
    expect(find.text('실패 테스트'), findsNothing);
    expect(find.text('테스트 결제 진행'), findsNothing);

    await tester.tap(find.text('결제하기'));
    await tester.pumpAndSettle();

    expect(find.text('결제가 완료되었습니다.'), findsOneWidget);
    expect(find.textContaining('ord_local_'), findsOneWidget);
    expect(find.text('선택 상품 × 2'), findsOneWidget);
    expect(store.cartQuantities, isEmpty);
  });

  testWidgets('detail quantity control uses a larger width than cart quantity control', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: MaterialApp(
          home: ProductDetailPage(
            product: const ProductItem(
              id: 'detail-size',
              brand: 'DETAIL',
              name: '수량 조절 상품',
              price: '₩10,000',
              oldPrice: '₩12,000',
              discount: '-16%',
              pattern: PatternKind.lines,
            ),
          ),
        ),
      ),
    );

    final qtyBoxes = find.byType(QtyBox);
    final detailQty = tester.widget<QtyBox>(qtyBoxes.first);
    expect(detailQty.buttonExtent, 56);
    expect(detailQty.valueExtent, 48);
  });

  testWidgets('cart quantity controls expose larger touch targets', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QtyBox(value: '1'),
        ),
      ),
    );

    final minus = tester.widget<SizedBox>(find.descendant(of: find.byType(QtyBox), matching: find.byType(SizedBox)).first);
    expect(minus.width, 48);
    expect(minus.height, 48);
  });

  testWidgets('home header search and cart buttons switch to their tabs', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.newProducts = [homeProduct];
    store.dealProducts = const [];
    store.cartQuantities = {'home-soft-knit': 1};

    await tester.pumpWidget(
      DoguApp(
        store: store,
        initializeStore: false,
      ),
    );

    await tester.tap(find.byType(IconBox).at(1));
    await tester.pumpAndSettle();

    expect(find.byType(BigSearchBox), findsOneWidget);

    await tester.tap(find.byType(IconBox).at(2));
    await tester.pumpAndSettle();

    expect(find.text('1개 상품 선택됨'), findsOneWidget);
  });

  testWidgets('home search bar opens the search tab', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));

    await tester.pumpWidget(
      DoguApp(
        store: store,
        initializeStore: false,
      ),
    );

    await tester.tap(find.text('찾고 싶은 욕망을 입력하세요').first);
    await tester.pumpAndSettle();

    expect(find.byType(BigSearchBox), findsOneWidget);
  });

  testWidgets('app shell pages expand with the available width like product detail', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AppStore(repository: _FakeRepository(results: const []));

    await tester.pumpWidget(DoguApp(store: store, initializeStore: false));

    final headerBox = tester.renderObject<RenderBox>(find.byType(Header).first);
    expect(headerBox.size.width, greaterThan(390));
  });

  testWidgets('AppButton invokes its callback when supplied', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: '누르기',
            onTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('누르기'));

    expect(taps, 1);
  });

  testWidgets('more products button expands the locally visible product count', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 3600); // 8개 상품(4행) + 버튼을 뷰포트에 담기 위해 높이 증가
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AppStore(repository: _FakeRepository(results: const []));
    store.usingFallback = false; // 스켈레톤 대신 실제 카드 표시
    store.newProducts = List<ProductItem>.generate(
      9, // initialVisibleCount=8 이므로 9번째(index 8) 상품이 처음엔 숨겨져야 함
      (index) => ProductItem(
        id: 'local-product-$index',
        brand: 'LOCAL',
        name: '로컬 상품 $index',
        price: '₩10,000',
        oldPrice: '₩12,000',
        discount: '-16%',
        pattern: PatternKind.values[index % PatternKind.values.length],
      ),
    );
    store.dealProducts = const [];

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProductSectionContent(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('로컬 상품 8'), findsNothing); // 9번째 항목(index 8)은 초기에 숨겨짐

    final moreButton = find.text('더 보기  +8');
    await tester.tap(moreButton);
    await tester.pumpAndSettle();

    expect(find.text('로컬 상품 8'), findsOneWidget);
  });

  testWidgets('home new-arrivals chips filter the visible products', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.usingFallback = false; // 스켈레톤 대신 실제 카드 표시
    store.newProducts = const [
      ProductItem(
        id: 'cloth-1',
        brand: 'CLOTH',
        name: '코튼 셔츠',
        price: '₩10,000',
        oldPrice: '₩12,000',
        discount: '-16%',
        pattern: PatternKind.lines,
        categoryKey: 'clothing',
      ),
      ProductItem(
        id: 'home-1',
        brand: 'HOME',
        name: '세라믹 머그',
        price: '₩20,000',
        oldPrice: '₩24,000',
        discount: '-16%',
        pattern: PatternKind.grid,
        categoryKey: 'home',
      ),
      ProductItem(
        id: 'tech-1',
        brand: 'TECH',
        name: '블루투스 스피커',
        price: '₩30,000',
        oldPrice: '₩36,000',
        discount: '-16%',
        pattern: PatternKind.wave,
        categoryKey: 'tech',
      ),
      ProductItem(
        id: 'beauty-1',
        brand: 'BEAUTY',
        name: '페이스 크림',
        price: '₩40,000',
        oldPrice: '₩48,000',
        discount: '-16%',
        pattern: PatternKind.dots,
        categoryKey: 'beauty',
      ),
    ];
    store.dealProducts = const [];

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProductSectionContent(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('코튼 셔츠'), findsOneWidget);
    expect(find.text('세라믹 머그'), findsOneWidget);

    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();

    expect(find.text('세라믹 머그'), findsOneWidget);
    expect(find.text('코튼 셔츠'), findsNothing);
    expect(find.text('블루투스 스피커'), findsNothing);

    await tester.tap(find.text('테크'));
    await tester.pumpAndSettle();

    expect(find.text('블루투스 스피커'), findsOneWidget);
    expect(find.text('세라믹 머그'), findsNothing);
  });

  testWidgets('deal section countdown decrements once per second', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(body: DealSection()),
        ),
      ),
    );

    expect(find.text('07:42:18'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('07:42:17'), findsOneWidget);
  });

  testWidgets('footer groups expand and collapse like details sections', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: FooterSection()),
        ),
      ),
    );

    final footerGroup = find.ancestor(of: find.text('SHOP'), matching: find.byType(FooterGroup));
    expect(find.descendant(of: footerGroup, matching: find.text('신상품')), findsNothing);

    await tester.tap(find.text('SHOP'));
    await tester.pumpAndSettle();

    expect(find.descendant(of: footerGroup, matching: find.text('신상품')), findsOneWidget);

    await tester.tap(find.text('SHOP'));
    await tester.pumpAndSettle();

    expect(find.descendant(of: footerGroup, matching: find.text('신상품')), findsNothing);
  });

  testWidgets('successful empty search renders empty results state', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.newProducts = [searchProduct];

    await tester.pumpWidget(
      DoguApp(
        store: store,
        initializeStore: false,
        initialTabIndex: 2,
      ),
    );

    await tester.enterText(find.byType(TextField), '램프');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('검색 결과'), findsOneWidget);
    expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
    expect(find.text('검색 램프'), findsNothing);
  });

  testWidgets('search cancel clears text field and active search state', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: [searchProduct]));
    store.newProducts = [homeProduct];

    await tester.pumpWidget(
      DoguApp(
        store: store,
        initializeStore: false,
        initialTabIndex: 2,
      ),
    );

    await tester.enterText(find.byType(TextField), '램프');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('검색 램프'), findsOneWidget);
    expect(store.lastSearchTerm, '램프');

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(store.lastSearchTerm, isEmpty);
    expect(store.searchResults, isEmpty);
    expect(find.text('검색 결과'), findsNothing);
    expect(find.text('검색 램프'), findsNothing);
  });

  testWidgets('offline search renders local fallback results in search tab', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const [], shouldThrow: true));
    store.catalogProducts = [searchProduct];
    store.newProducts = [searchProduct];
    store.dealProducts = const [];

    await tester.pumpWidget(
      DoguApp(
        store: store,
        initializeStore: false,
        initialTabIndex: 2,
      ),
    );

    await tester.enterText(find.byType(TextField), '램프');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('검색 결과'), findsOneWidget);
    expect(find.text('검색 램프'), findsOneWidget);
    expect(find.text('검색 결과가 없습니다.'), findsNothing);
  });

  // ── TDD: 카트 뱃지 ──────────────────────────────────────────────────────────

  testWidgets('cart icon hides badge when cart is empty', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    // cartQuantities 비어 있음 → cartCount == 0

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: Header())),
      ),
    );

    expect(find.byType(BadgePill), findsNothing);
  });

  testWidgets('cart icon shows count badge when cart has items', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.cartQuantities = {'p1': 3, 'p2': 2}; // cartCount == 5

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: Header())),
      ),
    );

    expect(find.byType(BadgePill), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  // ── TDD: CategoryNav 활성 상태 ─────────────────────────────────────────────

  testWidgets('category nav marks active filter item based on store state', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.setCategoryQuickFilter('new'); // '신상품' → ('new', null) 이 활성이어야 함

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: CategoryNav(),
            ),
          ),
        ),
      ),
    );

    // '신상품': active → AppColors.ink
    final activeText = tester.widget<Text>(find.text('신상품'));
    expect(activeText.style!.color, AppColors.ink);

    // '베스트': not active → AppColors.ink3
    final inactiveText = tester.widget<Text>(find.text('베스트'));
    expect(inactiveText.style!.color, AppColors.ink3);
  });

  testWidgets('category nav marks category key item active when category selected', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.setCategoryQuickFilter('all');
    store.selectCategoryBrowse('clothing'); // '의류' → ('all', 'clothing') 이 활성이어야 함

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: CategoryNav(),
            ),
          ),
        ),
      ),
    );

    final activeText = tester.widget<Text>(find.text('의류'));
    expect(activeText.style!.color, AppColors.ink);

    final inactiveText = tester.widget<Text>(find.text('베스트'));
    expect(inactiveText.style!.color, AppColors.ink3);
  });

  testWidgets('category nav shows no active item in default state', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    // default: categoryQuickFilter='all', selectedCategoryKey=null → 아무것도 활성 아님

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: CategoryNav(),
            ),
          ),
        ),
      ),
    );

    for (final label in ['신상품', '베스트', '의류', '홈·리빙', '전자제품', '뷰티']) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.style!.color, AppColors.ink3,
          reason: '$label should not be active by default');
    }
  });

  // ── TDD: initialVisibleCount 4 → 8 ────────────────────────────────────────

  testWidgets('product section shows 8 items initially', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AppStore(repository: _FakeRepository(results: const []));
    store.usingFallback = false; // 스켈레톤 대신 실제 카드 표시
    store.newProducts = List<ProductItem>.generate(
      9,
      (index) => ProductItem(
        id: 'vis-product-$index',
        brand: 'VIS',
        name: '표시 상품 $index',
        price: '₩10,000',
        oldPrice: '₩12,000',
        discount: '-16%',
        pattern: PatternKind.values[index % PatternKind.values.length],
      ),
    );
    store.dealProducts = const [];

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ProductSectionContent()),
          ),
        ),
      ),
    );

    // 8번째(index 7)는 보여야 하고
    expect(find.text('표시 상품 7'), findsOneWidget);
    // 9번째(index 8)는 안 보여야 함
    expect(find.text('표시 상품 8'), findsNothing);
    // '더 보기' 버튼도 있어야 함
    expect(find.text('더 보기  +8'), findsOneWidget);
  });

  // ── TDD P2-1: 스켈레톤 로딩 UI ───────────────────────────────────────────────

  testWidgets('product section shows skeleton cards while store is loading', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AppStore(repository: _FakeRepository(results: const []));
    // usingFallback == true 기본값 (초기 로딩 상태)
    store.newProducts = const [
      ProductItem(id: 'p1', brand: 'B', name: '실제 상품', price: '₩10,000', oldPrice: '₩12,000', discount: '-16%', pattern: PatternKind.dots),
    ];
    store.dealProducts = const [];

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: ProductSectionContent()))),
      ),
    );

    expect(find.byType(SkeletonProductCard), findsWidgets);
    expect(find.text('실제 상품'), findsNothing); // 실제 카드 숨겨짐
  });

  testWidgets('product section shows product cards after remote data loads', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AppStore(repository: _FakeRepository(results: const []));
    store.usingFallback = false; // 원격 데이터 로드 완료 상태
    store.newProducts = const [
      ProductItem(id: 'p1', brand: 'B', name: '원격 상품', price: '₩10,000', oldPrice: '₩12,000', discount: '-16%', pattern: PatternKind.dots),
    ];
    store.dealProducts = const [];

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: ProductSectionContent()))),
      ),
    );

    expect(find.byType(SkeletonProductCard), findsNothing);
    expect(find.text('원격 상품'), findsOneWidget);
  });

  // ── TDD P2-2: ProductCard 탭 피드백 ──────────────────────────────────────────

  testWidgets('product card is stateful to support press animation', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              child: ProductCard(
                product: ProductItem(
                  id: 'anim-test',
                  brand: 'ANIM',
                  name: '애니메이션 테스트',
                  price: '₩10,000',
                  oldPrice: '₩12,000',
                  discount: '-16%',
                  pattern: PatternKind.dots,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // StatefulWidget으로 변환됐는지 확인 (StatelessWidget이면 throws)
    expect(tester.state(find.byType(ProductCard)), isNotNull);
  });

  testWidgets('product card scale drops to 0.97 on press and returns to 1.0 on release', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    const product = ProductItem(
      id: 'scale-test',
      brand: 'SCALE',
      name: '스케일 테스트',
      price: '₩10,000',
      oldPrice: '₩12,000',
      discount: '-16%',
      pattern: PatternKind.dots,
    );

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 220, child: ProductCard(product: product)),
          ),
        ),
      ),
    );

    AnimatedScale cardScale() => tester.widget<AnimatedScale>(find.byType(AnimatedScale, skipOffstage: false));

    expect(cardScale().scale, 1.0); // 초기 상태

    final gesture = await tester.startGesture(tester.getCenter(find.byType(ProductCard)));
    await tester.pump();

    expect(cardScale().scale, 0.97); // 눌린 상태

    await gesture.up();
    await tester.pumpAndSettle();

    expect(cardScale().scale, 1.0); // 복원
  });

  // ── TDD P2-3: TickerStrip 자동 스크롤 ────────────────────────────────────────

  testWidgets('ticker strip is a stateful widget with auto-scroll', (tester) async {
    tester.view.physicalSize = const Size(390, 80);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TickerStrip())));

    // StatefulWidget으로 변환됐는지 확인 (현재 StatelessWidget → throws)
    expect(tester.state(find.byType(TickerStrip)), isNotNull);
  });

  testWidgets('ticker strip renders all content items', (tester) async {
    tester.view.physicalSize = const Size(390, 80);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TickerStrip())));

    // 아이템이 두 배로 렌더링됨 (무한 스크롤을 위해)
    expect(find.text('FREE SHIPPING'), findsWidgets);
    expect(find.text('14-DAY RETURNS'), findsWidgets);
  });

  testWidgets('ticker strip animation advances without error', (tester) async {
    tester.view.physicalSize = const Size(390, 80);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TickerStrip())));
    await tester.pump(); // postFrameCallback → 스크롤 시작

    // 여러 초 진행해도 오류 없음
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
  });

  // ── TDD P1-1: 결제 완료 후 홈 이동 ───────────────────────────────────────────

  testWidgets('payment confirm navigates to home tab after order completes', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.newProducts = const [
      ProductItem(
        id: 'pay-nav',
        brand: 'TEST',
        name: '결제 네비 테스트 상품',
        price: '₩10,000',
        oldPrice: '₩12,000',
        discount: '-16%',
        pattern: PatternKind.dots,
      ),
    ];
    store.dealProducts = const [];
    store.cartQuantities = {'pay-nav': 1};

    await tester.pumpWidget(DoguApp(store: store, initializeStore: false, initialTabIndex: 4));

    // 결제 오버레이 열기
    await tester.tap(find.text('결제하기 (1)  →'));
    await tester.pumpAndSettle();
    expect(find.text('결제 진행'), findsOneWidget);

    // 결제 완료
    await tester.tap(find.text('결제하기'));
    await tester.pumpAndSettle();
    expect(find.text('결제가 완료되었습니다.'), findsOneWidget);

    // 확인 → 홈 탭으로 이동
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    // 홈 탭의 검색바 플레이스홀더가 보여야 함
    expect(find.text('찾고 싶은 욕망을 입력하세요'), findsOneWidget);
  });

  // ── TDD P1-2: WishTab 뱃지 ────────────────────────────────────────────────

  testWidgets('bottom tabs shows wish badge when wishlist has items', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.wishlistIds = {'w1', 'w2', 'w3'}; // 3개

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: MaterialApp(
          home: Scaffold(
            body: BottomTabs(currentIndex: 0, onTap: (_) {}, bottomInset: 0),
          ),
        ),
      ),
    );

    expect(find.byType(BadgePill), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('bottom tabs hides wish badge when wishlist is empty', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    // wishlistIds 비어 있음, cartQuantities 비어 있음

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: MaterialApp(
          home: Scaffold(
            body: BottomTabs(currentIndex: 0, onTap: (_) {}, bottomInset: 0),
          ),
        ),
      ),
    );

    expect(find.byType(BadgePill), findsNothing);
  });

  testWidgets('bottom tabs shows both cart and wish badges when both non-empty', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.wishlistIds = {'w1', 'w2'};
    store.cartQuantities = {'c1': 3};

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: MaterialApp(
          home: Scaffold(
            body: BottomTabs(currentIndex: 0, onTap: (_) {}, bottomInset: 0),
          ),
        ),
      ),
    );

    expect(find.byType(BadgePill), findsNWidgets(2));
    expect(find.text('2'), findsOneWidget); // wish
    expect(find.text('3'), findsOneWidget); // cart
  });

  // ── TDD P1-3: 메뉴 현재 탭 하이라이트 ────────────────────────────────────────

  testWidgets('menu drawer highlights the current active tab item', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.dealProducts = const [];

    await tester.pumpWidget(DoguApp(store: store, initializeStore: false));
    // 기본: 홈 탭(index 0) 활성

    // 햄버거 메뉴 열기
    await tester.tap(find.byType(IconBox).first);
    await tester.pumpAndSettle();

    // 메뉴 항목 텍스트(fontSize=18)로 판별
    Text menuText(String label) => tester
        .widgetList<Text>(find.text(label))
        .firstWhere((t) => t.style?.fontSize == 18.0);

    // '홈'(index 0) → accent 색상으로 하이라이트
    expect(menuText('홈').style!.color, AppColors.accent);

    // 나머지 항목 → ink 색상(하이라이트 없음)
    for (final label in ['카테고리', '검색', '찜', '장바구니']) {
      expect(menuText(label).style!.color, AppColors.ink,
          reason: '$label should not be highlighted');
    }
  });

  testWidgets('menu drawer highlights correct item after tab switch', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.dealProducts = const [];

    await tester.pumpWidget(DoguApp(store: store, initializeStore: false));

    // 카테고리 탭(index 1)으로 이동 후 홈으로 복귀 → 메뉴 열기
    await tester.tap(find.byType(BottomTabs)); // 탭 영역 탭
    await tester.pumpAndSettle();

    // 검색 탭(index 2)으로 이동
    await tester.tap(find.byIcon(Icons.search).last); // bottom tab search
    await tester.pumpAndSettle();

    // 홈으로 복귀해서 메뉴 열기
    await tester.tap(find.byIcon(Icons.home_outlined).last); // home tab
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconBox).first); // hamburger
    await tester.pumpAndSettle();

    Text menuText(String label) => tester
        .widgetList<Text>(find.text(label))
        .firstWhere((t) => t.style?.fontSize == 18.0);

    expect(menuText('홈').style!.color, AppColors.accent);
    expect(menuText('검색').style!.color, AppColors.ink);
  });

  // ── [ui] u3: 드롭다운 메뉴가 상단 타이틀 구간 아래로 내려와 일체화 — 풀폭 + 헤더 아래 밀착 ──
  testWidgets('menu dropdown drops below the title bar: full-width and flush under header', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.dealProducts = const [];
    await tester.pumpWidget(DoguApp(store: store, initializeStore: false));

    await tester.tap(find.byType(IconBox).first); // 햄버거
    await tester.pumpAndSettle();

    final appRect = tester.getRect(find.byType(MaterialApp));
    final panel = tester.getRect(find.byKey(const ValueKey('menuDropdown')));
    expect(panel.left, appRect.left, reason: '좌측 여백 없이 상단 바와 동일 정렬');
    expect(panel.width, appRect.width, reason: '상단 바와 동일한 풀폭');
    expect(panel.top, closeTo(appRect.top + AppSpace.headerHeight, 1.0),
        reason: '타이틀 구간(헤더) 아래로 내려와 밀착');
  });

  testWidgets('menu dropdown closes and switches tab when an item is tapped', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.dealProducts = const [];
    await tester.pumpWidget(DoguApp(store: store, initializeStore: false));

    await tester.tap(find.byType(IconBox).first); // 햄버거
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('menuDropdown')), findsOneWidget);

    // 드롭다운 내부의 '검색'(index 2) 항목 탭
    await tester.tap(find.descendant(
      of: find.byKey(const ValueKey('menuDropdown')),
      matching: find.text('검색'),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('menuDropdown')), findsNothing, reason: '선택 시 닫힘');
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 2,
        reason: '검색 탭(index 2)으로 전환');
  });

  // ── [ui] 뒤로가기: 탭 전환 히스토리를 따라 이전 탭으로 복원 ──
  testWidgets('system back navigates to previously visited tabs', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.dealProducts = const [];
    await tester.pumpWidget(DoguApp(store: store, initializeStore: false));

    int currentTab() => tester.widget<IndexedStack>(find.byType(IndexedStack)).index!;
    expect(currentTab(), 0, reason: '시작은 홈(0)');

    // 홈(0) → 카테고리(1) → 찜(3)
    await tester.tap(find.byIcon(Icons.grid_view_outlined).last);
    await tester.pumpAndSettle();
    expect(currentTab(), 1);
    await tester.tap(find.byIcon(Icons.favorite_border).last);
    await tester.pumpAndSettle();
    expect(currentTab(), 3);

    // 뒤로가기 → 카테고리(1)로 복원, 앱은 유지(pop이 가로채짐)
    final handled1 = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled1, isTrue, reason: '뒤로가기를 앱이 가로채 처리');
    expect(currentTab(), 1, reason: '이전 탭(카테고리)으로 복원');

    // 한 번 더 뒤로가기 → 홈(0)으로 복원
    final handled2 = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled2, isTrue);
    expect(currentTab(), 0, reason: '이전 탭(홈)으로 복원');
  });

  // ── [ui] 장바구니 토스트: 결제바가 보이면 그 위로 올라가고, 없으면 내려온다 ──
  testWidgets('cart toast slides above the checkout bar when it is visible', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));
    store.dealProducts = const [];
    await tester.pumpWidget(DoguApp(store: store, initializeStore: false));
    await tester.pump(); // 초기 결제바 동기화(post-frame)

    store.showCartToast('상품을 담았습니다.');
    await tester.pump(); // 토스트 표시 반영
    expect(find.text('상품을 담았습니다.'), findsOneWidget);

    AnimatedPositioned toastPos() => tester.widget<AnimatedPositioned>(
          find.ancestor(
            of: find.text('상품을 담았습니다.'),
            matching: find.byType(AnimatedPositioned),
          ),
        );

    final normalBottom = toastPos().bottom!;

    // 결제바 노출 → 토스트가 결제바 높이만큼 위로 이동
    store.setCheckoutBarVisible(true);
    await tester.pump();
    final raisedBottom = toastPos().bottom!;
    expect(raisedBottom, greaterThan(normalBottom), reason: '결제바 위로 올라감');
    expect(raisedBottom - normalBottom, AppSpace.checkoutHeight,
        reason: '결제바 높이만큼 위로 이동');

    // 결제바 사라짐 → 다시 원위치
    store.setCheckoutBarVisible(false);
    await tester.pump();
    expect(toastPos().bottom!, normalBottom, reason: '결제바 없으면 다시 내려옴');

    // 자동 해제 타이머 소진(대기 중 타이머 방지)
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    store.dispose();
  });

  // ── (기존) search cancel does not render late in-flight results ────────────

  // ── TDD P3-1: DealSection 타이머 분리 ────────────────────────────────────────

  testWidgets('deal section is a stateless widget after timer extraction', (tester) async {
    final store = AppStore(repository: _FakeRepository(results: const []));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: DealSection())),
      ),
    );

    // DealSection은 StatelessWidget이어야 함 (StatefulWidget이면 state() 는 StateError를 던지지 않음)
    expect(() => tester.state(find.byType(DealSection)), throwsStateError);
  });

  testWidgets('countdown timer widget decrements independently of deal section', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CountdownTimer(initialSeconds: 10))),
    );

    expect(find.text('00:00:10'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:00:09'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('00:00:04'), findsOneWidget);
  });

  // ── TDD P3-2: API timeout 차등 설정 ──────────────────────────────────────────

  testWidgets('checkHealth times out after 1.5 s not the old 4 s', (tester) async {
    final repo = DoguRepository(client: _SlowHttpClient());
    var threw = false;
    repo.checkHealth().catchError((_) { threw = true; }); // ignore: unawaited_futures

    await tester.pump(const Duration(seconds: 1));
    expect(threw, isFalse); // 1 s < 1.5 s timeout

    await tester.pump(const Duration(milliseconds: 600)); // 누적 1.6 s
    expect(threw, isTrue);  // 1.6 s > 1.5 s → 타임아웃
  });

  testWidgets('fetchHome does not time out at 5 s but times out by 7 s', (tester) async {
    final repo = DoguRepository(client: _SlowHttpClient());
    var threw = false;
    repo.fetchHome().catchError((_) { threw = true; return const <String, dynamic>{}; }); // ignore: unawaited_futures

    await tester.pump(const Duration(seconds: 5));
    expect(threw, isFalse); // 5 s < 6 s home timeout

    await tester.pump(const Duration(seconds: 2)); // 누적 7 s
    expect(threw, isTrue);  // 7 s > 6 s → 타임아웃
  });

  testWidgets('fetchProducts times out after 3 s not the old 4 s', (tester) async {
    final repo = DoguRepository(client: _SlowHttpClient());
    var threw = false;
    repo.fetchProducts().catchError((_) { threw = true; return const <ProductItem>[]; }); // ignore: unawaited_futures

    await tester.pump(const Duration(seconds: 2));
    expect(threw, isFalse); // 2 s < 3 s timeout

    await tester.pump(const Duration(milliseconds: 1500)); // 누적 3.5 s
    expect(threw, isTrue);  // 3.5 s > 3 s (< 4 s old timeout) → currently FAILS
  });

  // ── TDD P3-3: allProducts getter 캐시화 ──────────────────────────────────────

  test('allProducts returns same instance on repeated calls without data change', () {
    final store = AppStore(repository: _FakeRepository(results: const []));
    final first = store.allProducts;
    final second = store.allProducts;
    expect(identical(first, second), isTrue); // currently FAILS: 매번 새 리스트 생성
  });

  test('allProducts recomputes and returns new instance after notifyListeners', () {
    final store = AppStore(repository: _FakeRepository(results: const []));
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

  // ── (기존) search cancel does not render late in-flight results ────────────

  testWidgets('search cancel does not render late in-flight results', (tester) async {
    final lampCompleter = Completer<List<ProductItem>>();
    final store = AppStore(
      repository: _FakeRepository(searchHandler: (_) => lampCompleter.future),
    );
    store.newProducts = [searchProduct];
    store.dealProducts = const [];

    await tester.pumpWidget(
      DoguApp(
        store: store,
        initializeStore: false,
        initialTabIndex: 2,
      ),
    );

    await tester.enterText(find.byType(TextField), '램프');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    await tester.tap(find.text('취소'));
    await tester.pump();

    lampCompleter.complete([searchProduct]);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(store.lastSearchTerm, isEmpty);
    expect(store.searchResults, isEmpty);
    expect(find.text('검색 결과'), findsNothing);
    expect(find.text('검색 램프'), findsNothing);
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
    final bundle = _StubAssetBundle(jsonEncode({
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
    final store = AppStore(repository: _FakeRepository(results: const [], shouldThrow: true));
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
      repository: _FakeRepository(results: const [], shouldThrow: true),
      seedSource: LocalSeedSource(bundle: _StubAssetBundle('this is not valid json')),
    );
    await store.initialize();
    expect(store.usingFallback, isTrue);
    expect(store.catalogProducts, isNotEmpty); // 손상 seed에도 fallback 보호 데이터 유지
    store.dispose();
  });

  // ── [perf] 첫 페인트 전 필수 한글 폰트만 로드(두부 박스 방지), 나머지 무거운 폰트는 post-frame 지연 ──
  testWidgets('bootstrap loads the essential Korean font before first paint and defers the rest', (tester) async {
    Widget? handedToRunner;
    var essentialLoadedBeforePaint = false;
    var heavyFontsStartedSynchronously = false;
    await bootstrap(
      loadEssentialFont: () async => essentialLoadedBeforePaint = true,
      runner: (app) {
        handedToRunner = app;
        // runner(첫 페인트) 시점에 필수 한글 폰트는 이미 로드되어 있어야 한다 → 두부(⊠) 박스 방지
        expect(essentialLoadedBeforePaint, isTrue,
            reason: '필수 한글 폰트는 첫 페인트 전에 등록');
      },
      loadFonts: () async => heavyFontsStartedSynchronously = true,
    );
    expect(handedToRunner, isA<DoguApp>());
    // 나머지 굵기/둥근 폰트(무거움)는 첫 페인트 경로에서 동기 시작되지 않고 post-frame으로 지연됨
    expect(heavyFontsStartedSynchronously, isFalse,
        reason: '무거운 폰트 로드는 post-frame으로 지연되어 첫 페인트를 막지 않음');
  });

  // ── [perf] perf2: instant-paint 하이브리드 — 번들 seed로 즉시 채운 뒤 백엔드 최신 데이터로 덮어쓴다 ──
  test('AppStore.initialize paints bundled seed first, then overlays fresh backend data', () async {
    final fresh = ProductItem(
      id: 'backend-fresh', brand: 'NET', name: '백엔드 신상품',
      price: '₩1,000', oldPrice: '₩2,000', discount: '-50%', pattern: PatternKind.dots,
    );
    final store = AppStore(
      seedSource: LocalSeedSource(), // 번들 → 즉시 12개로 첫 페인트
      repository: _FakeRepository(
        backendHome: const {'hero': {'title': '백엔드에서 온 타이틀'}},
        backendProducts: [fresh],
      ),
    );
    await store.initialize();
    expect(store.usingFallback, isFalse);
    expect(store.catalogProducts.any((p) => p.id == 'backend-fresh'), isTrue,
        reason: '백엔드 최신 카탈로그가 번들 seed를 덮어씀');
    expect(store.heroTitle, '백엔드에서 온 타이틀', reason: '백엔드 hero로 갱신');
  });

  test('AppStore.initialize keeps bundled seed when backend refresh fails (offline)', () async {
    final store = AppStore(
      seedSource: LocalSeedSource(),
      repository: _FakeRepository(shouldThrow: true), // 백엔드 다운
    );
    await store.initialize();
    // 백엔드 갱신 실패해도 번들 seed로 정상 동작
    expect(store.usingFallback, isFalse);
    expect(store.catalogProducts.length, 12);
  });

  // ── [ui] 이미지 로딩 전 placeholder를 통일된 "준비 이미지"로 ──
  testWidgets('product image surface shows the unified preparing placeholder without an image url', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 220,
            child: ProductImageSurface(pattern: PatternKind.lines),
          ),
        ),
      ),
    );
    expect(find.byType(PreparingImageSurface), findsOneWidget);
    expect(find.text('이미지 준비 중'), findsOneWidget);
    expect(find.byType(PatternBox), findsNothing, reason: '랜덤 패턴 배경 대신 준비 이미지');
  });

  // ── [ui] empty state에서 '// empty state' 디버그 라벨 제거 ──
  testWidgets('empty state block does not render the debug label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyStateBlock(title: '조건에 맞는 상품이 없습니다.', body: '다른 필터를 선택하세요.'),
        ),
      ),
    );
    expect(find.text('// empty state'), findsNothing);
    expect(find.text('조건에 맞는 상품이 없습니다.'), findsOneWidget);
  });

  // ── [bug] 카테고리 선택 시 해당 카테고리 상품을 서버에서 받아 표시(대용량 카탈로그 대응) ──
  test('selectCategoryBrowse fetches the category products from the backend', () async {
    final inInitialCatalog = const ProductItem(
      id: 'other-cat', brand: 'B', name: '다른 카테고리 상품', price: '₩1,000', oldPrice: '₩2,000',
      discount: '-50%', pattern: PatternKind.dots, categoryKey: '20000000', categoryIds: ['20000000'],
    );
    final furniture = const ProductItem(
      id: 'furn-1', brand: 'B', name: '원목 의자', price: '₩1,000', oldPrice: '₩2,000',
      discount: '-50%', pattern: PatternKind.grid, categoryKey: '10000112', categoryIds: ['10000112'],
    );
    final store = AppStore(
      repository: _CategoryFakeRepository(
        initialCatalog: [inInitialCatalog], // 첫 fetchProducts()는 다른 카테고리 상품만(=메모리 부분집합)
        byCategory: {'10000112': [furniture]},
      ),
    );
    await store.initialize();
    // 메모리 카탈로그에는 10000112 상품이 없지만, 카테고리 선택 시 서버에서 받아온다
    await store.selectCategoryBrowse('10000112');
    expect(store.categoryBrowseProducts.map((p) => p.id), contains('furn-1'),
        reason: '서버에서 카테고리 상품을 받아 표시');
  });
}

/// 테스트용 인메모리 AssetBundle — seed.json 대신 임의 JSON을 주입한다.
class _StubAssetBundle extends CachingAssetBundle {
  _StubAssetBundle(this._payload);
  final String _payload;

  @override
  Future<ByteData> load(String key) async {
    final bytes = utf8.encode(_payload);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => _payload;
}

class _FakeRepository extends DoguRepository {
  _FakeRepository({
    this.results = const [],
    this.shouldThrow = false,
    this.searchHandler,
    this.detailProduct,
    this.shouldThrowDetail = false,
    this.backendHome,
    this.backendProducts = const [],
  });

  final List<ProductItem> results;
  final bool shouldThrow;
  final Future<List<ProductItem>> Function(String query)? searchHandler;
  final ProductItem? detailProduct;
  final bool shouldThrowDetail;
  final Map<String, dynamic>? backendHome;
  final List<ProductItem> backendProducts;

  @override
  Future<Map<String, dynamic>> fetchHome() async {
    if (shouldThrow) throw Exception('offline');
    return backendHome ?? const {};
  }

  @override
  Future<List<ProductItem>> fetchProducts({String? section, String? categoryId, String? tag, int limit = 100}) async {
    if (shouldThrow) throw Exception('offline');
    return backendProducts;
  }

  @override
  Future<List<SearchTrend>> fetchTrending() async {
    if (shouldThrow) throw Exception('offline');
    return const [];
  }

  @override
  Future<List<String>> fetchSuggestions() async {
    if (shouldThrow) throw Exception('offline');
    return const [];
  }

  @override
  Future<Map<String, String>> fetchNewsletter() async {
    if (shouldThrow) throw Exception('offline');
    return const {};
  }

  @override
  Future<List<ProductItem>> searchProducts(String query, {String? categoryId}) async {
    if (searchHandler != null) return searchHandler!(query);
    if (shouldThrow) throw Exception('offline');
    return results;
  }

  @override
  Future<ProductItem> fetchProduct(String productId) async {
    if (shouldThrowDetail) throw Exception('detail offline');
    return detailProduct ??
        ProductItem(
          id: productId,
          brand: 'DETAIL',
          name: 'Fetched $productId',
          price: '₩0',
          oldPrice: '₩0',
          discount: '-0%',
          pattern: PatternKind.dots,
        );
  }

}

// 카테고리별 서버 필터링을 흉내내는 저장소 — fetchProducts(categoryId)로 다른 결과를 돌려준다
class _CategoryFakeRepository extends DoguRepository {
  _CategoryFakeRepository({required this.initialCatalog, required this.byCategory});
  final List<ProductItem> initialCatalog;
  final Map<String, List<ProductItem>> byCategory;

  @override
  Future<Map<String, dynamic>> fetchHome() async => const {};

  @override
  Future<List<ProductItem>> fetchProducts({String? section, String? categoryId, String? tag, int limit = 100}) async {
    if (categoryId != null && categoryId.isNotEmpty) return byCategory[categoryId] ?? const [];
    return initialCatalog;
  }

  @override
  Future<List<SearchTrend>> fetchTrending() async => const [];
  @override
  Future<List<String>> fetchSuggestions() async => const [];
  @override
  Future<Map<String, String>> fetchNewsletter() async => const {};
}

// 절대 응답하지 않는 HTTP 클라이언트 — timeout 타이머만 남아 FakeAsync 안전
class _SlowHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Completer<http.StreamedResponse>().future; // 절대 complete 안 됨
}
