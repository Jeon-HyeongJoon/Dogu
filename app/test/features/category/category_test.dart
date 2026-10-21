import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/fakes.dart';
import '../../support/fixtures.dart';
import '../../support/harness.dart';

void main() {
  setUpDoguTest();

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

  testWidgets('category tab list shows loading dots instead of the bundled categories while loading', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
    store.categories = const [CategoryItem('의류', '412', PatternKind.dots, id: 'fashion')];
    store.catalogLoading = true;

    // 애니메이션 끄기 설정이면 점이 멈춘다 — pumpAndSettle이 끝나야 한다.
    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: SingleChildScrollView(child: CategoryListBlock())),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoadingDots), findsOneWidget);
    expect(find.text('의류'), findsNothing);
  });

  testWidgets('choosing a category shows a skeleton until the server answers instead of the local guess', (tester) async {
    final gate = Completer<void>();
    final store = AppStore(repository: GatedProductsRepository(gate.future, [homeProduct]));
    store.selectCategoryBrowse('food');
    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Builder(
                builder: (context) => CategoryProductsBlock(
                  products: AppStateScope.watch(context).categoryBrowseProducts,
                  loading: AppStateScope.watch(context).categoryProductsLoading,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(store.categoryProductsLoading, isTrue);
    expect(find.byType(SkeletonProductCard), findsWidgets);
    expect(find.text('조건에 맞는 상품이 없습니다.'), findsNothing, reason: "'상품 없음'이 깜빡이지 않는다");

    gate.complete();
    await tester.pumpAndSettle();
    expect(store.categoryProductsLoading, isFalse);
    expect(find.text(homeProduct.name), findsOneWidget);
  });

  testWidgets('category card tap opens category tab and shows filtered product list', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
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
    final store = AppStore(repository: FakeRepository(results: const []));
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
      repository: CategoryFakeRepository(
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

  testWidgets('SHOP BY BRAND lists the real brands and searches on tap', (tester) async {
    // 세로로 길게 — 브랜드 태그가 하단 탭 바에 가리지 않게. 폭은 다른 앱 테스트처럼 넓게
    // (테스트 폰트는 손글씨 타이틀을 정사각형으로 그려 390px 헤더가 넘친다 — 실제 폰트 골든은 정상).
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1700);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = AppStore(repository: FakeRepository(results: const [homeProduct]));
    store.suggestions = const ['스파클Mart', '닥터바이'];
    await tester.pumpWidget(DoguApp(store: store, initializeStore: false, initialTabIndex: 1));
    await tester.pump();

    final brands = find.ancestor(of: find.text('[ + ] SHOP BY BRAND'), matching: find.byType(TagSection));
    expect(find.descendant(of: brands, matching: find.text('닥터바이')), findsOneWidget);
    expect(find.text('soft·studio  42'), findsNothing, reason: '고정돼 있던 가짜 브랜드');
    expect(find.text('전체 보기 →'), findsNothing, reason: '눌러도 아무 일 없던 링크');

    await tester.tap(find.descendant(of: brands, matching: find.text('닥터바이')));
    await tester.pumpAndSettle();
    expect(store.lastSearchTerm, '닥터바이');
    expect(find.byKey(const PageStorageKey('search-tab')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
