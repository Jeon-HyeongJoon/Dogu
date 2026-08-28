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
  testWidgets('DoguApp(useV2: true) opens the v2 shell as the default route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DoguApp(useV2: true, initializeStore: false));
    await tester.pump();
    expect(find.byType(V2Shell), findsOneWidget);
  });

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
    // 히어로 높이에 따라 첫 상품 카드가 폴드 밖일 수 있어 하트를 뷰포트로 끌어온다.
    await tester.ensureVisible(find.byIcon(Icons.favorite_border_rounded).first);
    await tester.pump();
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

  testWidgets('v2 checkout opens the delivery notice, empties the cart and banks the amount', (tester) async {
    final store = await _pumpShell(tester, 4, cart: {'p01': 2, 'p03': 1});
    final total = store.selectedCartTotal;
    expect(total, greaterThan(0));

    await tester.tap(find.text('결제하기'));
    await tester.pumpAndSettle();

    expect(find.byType(V2OrderDeliveryPage), findsOneWidget);
    expect(find.text('배송 준비 중'), findsOneWidget);
    // 결제한 상품은 장바구니에서 빠지고, 그 금액은 이번 달 '참은 돈'으로 적립된다.
    expect(store.cartQuantities, isEmpty);
    expect(store.savedInMonth(DateTime.now()), total);
  });

  testWidgets('v2 delivery notice confirm reveals the not-shipped result', (tester) async {
    await _pumpShell(tester, 4, cart: {'p01': 1});
    await tester.tap(find.text('결제하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('v2_order_confirm')));
    await tester.pumpAndSettle();

    expect(find.byType(V2OrderRevealPage), findsOneWidget);
    expect(find.text('사실은요,\n안 보냈습니다'), findsOneWidget);
    expect(find.byKey(const Key('v2_order_joke')), findsOneWidget);
    expect(find.text('미발송'), findsOneWidget);
    expect(find.text('₩0'), findsOneWidget);
    // 배송 안내로는 돌아갈 수 없다(pushReplacement) — 마지막 CTA는 셸로 되돌린다.
    expect(find.byType(V2OrderDeliveryPage), findsNothing);

    await tester.tap(find.byKey(const Key('v2_order_done')));
    await tester.pumpAndSettle();
    expect(find.byType(V2Shell), findsOneWidget);
    expect(find.byType(V2OrderRevealPage), findsNothing);
  });
}
