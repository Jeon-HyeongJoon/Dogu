import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/fakes.dart';
import '../../support/fixtures.dart';
import '../../support/harness.dart';

void main() {
  setUpDoguTest();

  test('performSearch keeps home catalog and stores dedicated search results', () async {
    final store = AppStore(repository: FakeRepository(results: [searchProduct]));
    store.newProducts = [homeProduct];

    await store.performSearch('램프');

    expect(store.recentSearches.first, '램프');
    expect(store.newProducts.map((item) => item.id), ['home-soft-knit']);
    expect(store.searchResults.map((item) => item.id), ['search-lamp']);
    expect(store.lastSearchTerm, '램프');
  });

  test('performSearch keeps successful empty backend results empty', () async {
    final store = AppStore(repository: FakeRepository(results: const []));
    store.newProducts = [searchProduct];

    await store.performSearch('램프');

    expect(store.lastSearchTerm, '램프');
    expect(store.searchResults, isEmpty);
  });

  test('performSearch falls back to local results when repository throws', () async {
    final store = AppStore(repository: FakeRepository(results: const [], shouldThrow: true));
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
      repository: FakeRepository(
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
      repository: FakeRepository(searchHandler: (_) => lampCompleter.future),
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
    final store = AppStore(repository: FakeRepository(results: [searchProduct]));
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

  testWidgets('search blocks: no fake recent searches, loading dots for suggestions', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
    expect(store.recentSearches, isEmpty, reason: '처음 온 사용자에게 검색한 적 없는 기본값을 보이지 않는다');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(children: [
            TagSection(title: '[ 01 ] 최근 검색', action: '전체 삭제', tags: [], emptyText: '최근 검색어가 없어요'),
            TagSection(title: '[ 02 ] 추천 브랜드', tags: ['아무거나'], loading: true),
          ]),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('최근 검색어가 없어요'), findsOneWidget);
    expect(find.text('전체 삭제'), findsNothing, reason: '지울 게 없으면 버튼도 없다');
    expect(find.byType(LoadingDots), findsOneWidget);
    expect(find.text('아무거나'), findsNothing);
  });

  testWidgets('recent search tags run searches through the app store', (tester) async {
    final store = AppStore(repository: FakeRepository(results: [searchProduct]));
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
    final store = AppStore(repository: FakeRepository(results: const []));
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
    final store = AppStore(repository: FakeRepository(results: const []));
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

  testWidgets('successful empty search renders empty results state', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
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
    final store = AppStore(repository: FakeRepository(results: [searchProduct]));
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
    final store = AppStore(repository: FakeRepository(results: const [], shouldThrow: true));
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

  // ── (기존) search cancel does not render late in-flight results ────────────

  testWidgets('search cancel does not render late in-flight results', (tester) async {
    final lampCompleter = Completer<List<ProductItem>>();
    final store = AppStore(
      repository: FakeRepository(searchHandler: (_) => lampCompleter.future),
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

  test('performSearch searches the whole catalog even after a category was picked in the category tab', () async {
    // 운영에서 카테고리를 고른 뒤 '스파클Mart'를 누르면 결과가 0개였다 — 고른 카테고리가 화면에 안 보인 채 범위로 붙었다.
    final repository = _ScopeRecordingRepository();
    final store = AppStore(repository: repository);
    store.selectedCategoryKey = '50000003';

    await store.performSearch('스파클Mart');

    expect(repository.searchedCategoryIds, [null]);
  });
}

class _ScopeRecordingRepository extends FakeRepository {
  final searchedCategoryIds = <String?>[];

  @override
  Future<List<ProductItem>> searchProducts(String query, {String? categoryId}) async {
    searchedCategoryIds.add(categoryId);
    return super.searchProducts(query, categoryId: categoryId);
  }
}
