import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dogu_mobile_shop/main.dart';

// v2 화면의 상호작용이 v1과 동일하게 공유 AppStore에 배선됐는지 CI에서 검증한다.
// (골든과 달리 폰트/플랫폼 렌더에 의존하지 않으므로 CI에서 그대로 실행된다.)
Future<AppStore> _pumpShell(WidgetTester tester, int tab, {Map<String, int>? cart, List<String>? recent}) async {
  SharedPreferences.setMockInitialValues({});
  final store = AppStore();
  if (cart != null) store.cartQuantities = cart;
  if (recent != null) store.recentSearches = recent;
  await tester.pumpWidget(
    AppStateScope(
      store: store,
      child: MaterialApp(home: V2Shell(initialTab: tab)),
    ),
  );
  await tester.pump();
  return store;
}

void main() {
  testWidgets('v2 category quick filter updates the store', (tester) async {
    final store = await _pumpShell(tester, 1);
    expect(store.categoryQuickFilter, 'all');
    await tester.tap(find.text('딜'));
    await tester.pump();
    expect(store.categoryQuickFilter, 'deal');
  });

  testWidgets('v2 cart quantity stepper increments the cart', (tester) async {
    final store = await _pumpShell(tester, 4, cart: {'p01': 1});
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pump();
    expect(store.cartQuantities['p01'], 2);
  });

  testWidgets('v2 cart select-all toggles selection', (tester) async {
    final store = await _pumpShell(tester, 4, cart: {'p01': 1, 'p03': 1});
    expect(store.selectedCartIds.length, 2);
    await tester.tap(find.text('전체 선택'));
    await tester.pump();
    expect(store.selectedCartIds, isEmpty);
  });

  testWidgets('v2 product card heart toggles the wishlist', (tester) async {
    final store = await _pumpShell(tester, 0);
    expect(store.wishlistIds, isEmpty);
    await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
    await tester.pump();
    expect(store.wishlistIds, isNotEmpty);
  });

  testWidgets('v2 search "전체 삭제" clears recent searches', (tester) async {
    final store = await _pumpShell(tester, 2, recent: const ['린넨 셔츠', '스피커']);
    expect(store.recentSearches, isNotEmpty);
    await tester.tap(find.textContaining('전체 삭제'));
    await tester.pump();
    expect(store.recentSearches, isEmpty);
  });

  testWidgets('v2 detail add-to-cart adds the product and offers go-to-cart', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    final product = store.newProducts.first;
    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: MaterialApp(home: V2ProductDetailPage(product: product, onGoToCart: () {})),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('장바구니에 담기'));
    await tester.pumpAndSettle();
    expect(store.cartQuantities[product.id], 1);
    expect(find.text('장바구니 보기'), findsOneWidget);
    // showCartToast가 건 3초 타이머를 소진해 teardown의 pending-timer 검사를 통과시킨다.
    await tester.pump(const Duration(seconds: 4));
  });
}
