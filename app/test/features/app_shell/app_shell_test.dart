import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/fakes.dart';
import '../../support/fixtures.dart';
import '../../support/harness.dart';

void main() {
  setUpDoguTest();

  testWidgets('DoguApp applies the bundled Korean font family', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));

    await tester.pumpWidget(DoguApp(store: store, initializeStore: false));

    final theme = Theme.of(tester.element(find.byType(AppShell)));
    expect(theme.textTheme.bodyMedium?.fontFamily, doguFontFamily);
  });

  testWidgets('home header search and cart buttons switch to their tabs', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
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

  testWidgets('app shell pages expand with the available width like product detail', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AppStore(repository: FakeRepository(results: const []));

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

  // ── TDD: 카트 뱃지 ──────────────────────────────────────────────────────────

  testWidgets('cart icon hides badge when cart is empty', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
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
    final store = AppStore(repository: FakeRepository(results: const []));
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

  testWidgets('unknown route (e.g. the retired /v2) lands on the home tab', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
    await tester.pumpWidget(DoguApp(store: store, initializeStore: false));
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.byType(AppShell)));
    router.go('/v2');
    await tester.pumpAndSettle();

    expect(find.text('찾고 싶은 욕망을 입력하세요'), findsOneWidget);
  });

  // ── TDD P1-2: WishTab 뱃지 ────────────────────────────────────────────────

  testWidgets('bottom tabs shows wish badge when wishlist has items', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
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
    final store = AppStore(repository: FakeRepository(results: const []));
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
    final store = AppStore(repository: FakeRepository(results: const []));
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
    final store = AppStore(repository: FakeRepository(results: const []));
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
    final store = AppStore(repository: FakeRepository(results: const []));
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
    final store = AppStore(repository: FakeRepository(results: const []));
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
    final store = AppStore(repository: FakeRepository(results: const []));
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
    final store = AppStore(repository: FakeRepository(results: const []));
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
}
