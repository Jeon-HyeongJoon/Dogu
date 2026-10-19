import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/fakes.dart';
import '../../support/harness.dart';

void main() {
  setUpDoguTest();

  // ── [ui] 폰트 적용: 브랜드 타이틀=손글씨체(Dogu Hand), 광고 헤드라인=본문체(Dogu Sans) ──
  testWidgets('brand title uses the handwriting font; hero headline uses the angular base font', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
    store.dealProducts = const [];
    await tester.pumpWidget(DoguApp(store: store, initializeStore: false));

    // 상단 브랜드 타이틀은 손글씨체(Dogu Hand)
    final brandTitle = tester.widget<Text>(find.text('욕망의 장바구니'));
    expect(brandTitle.style?.fontFamily, doguTitleFontFamily);

    // 광고 메인 문구(44px 헤드라인)는 각진 기본 본문체
    final heroHeadline = tester
        .widgetList<Text>(find.byType(Text))
        .firstWhere((t) => t.style?.fontSize == 44);
    expect(heroHeadline.style?.fontFamily, doguFontFamily);
  });

  testWidgets('category and promo surfaces use neutral placeholders without pattern boxes', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2600);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AppStore(repository: FakeRepository(results: const []));

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
    final store = AppStore(repository: FakeRepository(detailProduct: featured));
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
    final store = AppStore(repository: FakeRepository(results: const []));
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

  testWidgets('home category grid shows the backend picks in demand order and hides counts', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 백엔드는 가나다순으로 주고 메인 노출분에만 featured + home_rank(수요 순)를 단다.
    CategoryItem category(String name, {int? rank}) =>
        CategoryItem(name, '100', PatternKind.dots, id: name, featured: rank != null, homeRank: rank);
    final store = AppStore(repository: FakeRepository(results: const []));
    store.categories = [
      category('E쿠폰/티켓/생활편의'),
      category('가공식품', rank: 2),
      category('건강/의료용품', rank: 6),
      category('건강식품', rank: 3),
      category('공구'),
      category('반려동물용품', rank: 5),
      category('생활용품', rank: 4),
      category('신선식품', rank: 1),
      category('여성의류', rank: 9),
      category('출산/유아동', rank: 8),
      category('화장품/미용', rank: 7),
    ];

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: CategorySection()))),
      ),
    );

    final cards = tester.widgetList<CategoryCard>(find.byType(CategoryCard)).map((card) => card.item.name);
    expect(cards, ['신선식품', '가공식품', '건강식품', '생활용품', '반려동물용품', '건강/의료용품', '화장품/미용', '출산/유아동', '여성의류']);
    expect(find.text('공구'), findsNothing);
    // 상품 수(크롤링 한도라 전부 100)는 그리지 않는다.
    expect(find.text('100'), findsNothing);

    // 순위가 없는 featured(번들 seed)는 받은 순서, featured가 없으면(구 백엔드) 앞에서부터 9개.
    final seeded = [for (final name in ['b', 'a', 'c']) CategoryItem(name, '1', PatternKind.dots, id: name, featured: true)];
    expect(homeCategories(seeded).map((item) => item.name), ['b', 'a', 'c']);
    final plain = List.generate(12, (i) => CategoryItem('c$i', '1', PatternKind.dots, id: 'c$i'));
    expect(homeCategories(plain).map((item) => item.name), List.generate(9, (i) => 'c$i'));
  });

  testWidgets('home category grid shows loading dots in the nine-slot space until the backend answers', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 번들 seed의 옛 카테고리가 이미 들어 있어도, 백엔드 응답 전에는 그리지 않는다.
    final store = AppStore(repository: FakeRepository(results: const []));
    store.categories = const [
      CategoryItem('전자제품', '186', PatternKind.dots, id: 'gadget', featured: true),
      CategoryItem('의류', '412', PatternKind.dots, id: 'fashion', featured: true),
    ];
    store.catalogLoading = true;

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: CategorySection()))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LoadingDots), findsOneWidget);
    expect(find.byType(CategoryCard), findsNothing);
    expect(find.text('전자제품'), findsNothing);
    final loadingHeight = tester.getSize(find.byType(CategorySection)).height;

    // 응답 도착 → 9칸. 섹션 높이가 그대로라 아래 내용이 밀리지 않는다.
    store.categories = [
      for (var i = 1; i <= 9; i++) CategoryItem('카테고리$i', '100', PatternKind.dots, id: 'c$i', featured: true, homeRank: i),
    ];
    store.catalogLoading = false;
    store.notifyListeners();
    await tester.pump();

    expect(find.byType(LoadingDots), findsNothing);
    expect(find.byType(CategoryCard), findsNWidgets(9));
    expect(tester.getSize(find.byType(CategorySection)).height, loadingHeight);
  });

  testWidgets('top nav, featured card and deals wait for the backend, then nav shows the top home categories', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 3000);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AppStore(repository: FakeRepository(results: const []));
    store.catalogLoading = true;
    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: Column(children: [CategoryNav(), FeaturedCard(), DealSection()]))),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // 응답 전: 칩은 신상품·베스트·SALE + 로딩 점, 추천 카드·딜은 seed 상품 대신 자리만.
    expect(find.text('신상품'), findsOneWidget);
    expect(find.text('SALE'), findsOneWidget);
    expect(find.text('전자제품'), findsNothing, reason: 'seed의 옛 카테고리를 칩으로 그리지 않는다');
    expect(find.byType(LoadingDots), findsNWidgets(2)); // 칩 + 추천 카드
    expect(find.byType(SkeletonProductCard), findsNWidgets(3)); // 오늘의 딜
    expect(find.byType(ProductCard), findsNothing);

    // 응답 후: 칩 가운데는 메인 카테고리 칸과 같은 순위의 상위 4개.
    store.categories = [
      for (final (i, name) in ['식품', '생활용품', '반려동물용품', '건강/의료용품', '화장품/미용'].indexed)
        CategoryItem(name, '100', PatternKind.dots, id: 'c$i', featured: true, homeRank: i + 1),
      const CategoryItem('공구', '100', PatternKind.dots, id: 'tools'),
    ];
    store.catalogLoading = false;
    store.notifyListeners();
    await tester.pump();

    for (final label in ['식품', '생활용품', '반려동물용품', '건강/의료용품']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('화장품/미용'), findsNothing, reason: '상위 4개만');
    expect(find.text('공구'), findsNothing);
    expect(find.byType(LoadingDots), findsNothing);
    expect(find.byType(SkeletonProductCard), findsNothing);

    await tester.pumpWidget(const SizedBox()); // 딜 카운트다운 타이머 정리
  });

  testWidgets('hero block renders backend-driven promo text from store state', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
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

  testWidgets('hero numbers wait for the backend and hide when absent; no fixed date', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
    expect(store.heroStats, isEmpty, reason: '고정값(218 · 14 · −42%)을 두지 않는다');
    expect(store.heroDate, isEmpty, reason: '고정 기간 날짜(05.12 — 05.26)를 두지 않는다');
    store.featuredProduct = null;
    store.catalogLoading = true;

    await tester.pumpWidget(
      AppStateScope(store: store, child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: HeroBlock())))),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(StatGrid), findsOneWidget);
    expect(find.byType(LoadingDots), findsOneWidget);

    // 백엔드가 계산한 숫자가 오면 그대로.
    store.heroStats = const [('6', '신상품'), ('16,092', '브랜드'), ('−32%', '평균 할인')];
    store.catalogLoading = false;
    store.notifyListeners();
    await tester.pump();
    expect(find.text('16,092'), findsOneWidget);
    expect(find.byType(LoadingDots), findsNothing);

    // 숫자가 없으면(오프라인 seed) 숫자 줄을 숨긴다.
    store.heroStats = const [];
    store.notifyListeners();
    await tester.pump();
    expect(find.byType(StatGrid), findsNothing);
  });

  testWidgets('home search bar opens the search tab', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));

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

  testWidgets('more products button expands the locally visible product count', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 3600); // 8개 상품(4행) + 버튼을 뷰포트에 담기 위해 높이 증가
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AppStore(repository: FakeRepository(results: const []));
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

  testWidgets('home new-arrivals show every product without the legacy category chips, skeleton while loading', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
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

    for (final name in ['코튼 셔츠', '세라믹 머그', '블루투스 스피커', '페이스 크림']) {
      expect(find.text(name), findsOneWidget);
    }
    // 옛 키(clothing/home/tech/beauty)로 거르던 칩 — 실제 상품에선 항상 비어서 뺐다.
    for (final chip in ['의류', '홈', '테크', '뷰티']) {
      expect(find.text(chip), findsNothing);
    }

    // 백엔드 응답 전엔 seed 상품 대신 스켈레톤.
    store.catalogLoading = true;
    store.notifyListeners();
    await tester.pump();
    expect(find.byType(SkeletonProductCard), findsWidgets);
    expect(find.text('코튼 셔츠'), findsNothing);
  });

  testWidgets('deal section countdown decrements once per second', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));

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

  // ── TDD: CategoryNav 활성 상태 ─────────────────────────────────────────────

  testWidgets('category nav marks active filter item based on store state', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
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
    final store = AppStore(repository: FakeRepository(results: const []));
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
    final store = AppStore(repository: FakeRepository(results: const []));
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

    final store = AppStore(repository: FakeRepository(results: const []));
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

    final store = AppStore(repository: FakeRepository(results: const []));
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

    final store = AppStore(repository: FakeRepository(results: const []));
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

  // ── (기존) search cancel does not render late in-flight results ────────────

  // ── TDD P3-1: DealSection 타이머 분리 ────────────────────────────────────────

  testWidgets('deal section is a stateless widget after timer extraction', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));

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
}
