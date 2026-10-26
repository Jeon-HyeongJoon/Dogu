import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/fakes.dart';
import '../../support/fixtures.dart';
import '../../support/harness.dart';

void main() {
  setUpDoguTest();

  testWidgets('cart selection controls totals checkout and empty state locally', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
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
    final store = AppStore(repository: FakeRepository(results: const []));
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
    final store = AppStore(repository: FakeRepository(results: const []));

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

  // ── [ui] 장바구니 토스트: 결제바가 보이면 그 위로 올라가고, 없으면 내려온다 ──
  testWidgets('cart toast slides above the checkout bar when it is visible', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
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
    expect(raisedBottom - normalBottom, AppLayout.checkoutHeight,
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

  test('ProductItem snapshot round-trips through toJson/fromJson', () {
    final restored = ProductItem.fromJson(knit.toJson());
    expect(
      [restored.id, restored.brand, restored.name, restored.price, restored.oldPrice, restored.discount, restored.imageUrl, restored.reviews, restored.tags, restored.categoryIds],
      [knit.id, knit.brand, knit.name, knit.price, knit.oldPrice, knit.discount, knit.imageUrl, knit.reviews, knit.tags, knit.categoryIds],
    );
    expect(restored.artwork?.toJson(), knit.artwork?.toJson());
  });

  test('cart and wishlist reopen with the right product even when it is outside the startup catalog', () async {
    // 1) 상세에서 담는다 — 시작 카탈로그(백엔드 상위 100개 + 홈)에 없는 상품.
    final first = AppStore(seedSource: LocalSeedSource(), repository: FakeRepository(shouldThrow: true));
    first.cacheProduct(knit);
    await first.changeCartQuantity(knit.id, 2);
    await first.toggleWishlist(knit);

    // 2) 다시 연다 — 백엔드가 아직(또는 아예) 답하지 않아도 맞는 상품으로 보인다.
    final reopened = AppStore(seedSource: LocalSeedSource(), repository: FakeRepository(shouldThrow: true));
    await reopened.initialize();
    expect(reopened.cartLines.map((line) => (line.product.name, line.product.price, line.quantity)), [('천연 아카시아꿀', '₩23,900', 2)]);
    expect(reopened.wishlistProducts.map((p) => p.name), ['천연 아카시아꿀']);
  });

  test('saved products without a snapshot are fetched from the backend, and removed when gone', () async {
    // 스냅샷 도입 전에 담긴 항목: id만 있다. 하나는 백엔드에 있고, 하나는 없어진 상품(404).
    SharedPreferences.setMockInitialValues({
      'cartQuantities': jsonEncode({'still-sold': 1, 'discontinued': 3}),
      'wishlistIds': ['discontinued'],
    });
    final store = AppStore(seedSource: LocalSeedSource(), repository: MissingProductRepository(missing: {'discontinued'}));
    await store.initialize();
    await pumpEventQueue();

    expect(store.cartLines.map((line) => line.product.name), ['Fetched still-sold'], reason: '엉뚱한 기본 상품 대신 백엔드에서 받은 상품');
    expect(store.cartQuantities.keys, ['still-sold'], reason: '없어진 상품은 장바구니에서 뺀다');
    expect(store.wishlistIds, isEmpty);
    expect(store.findProduct('never-seen'), isNull, reason: '못 찾으면 기본 상품이 아니라 null');
  });

  testWidgets('cart shows no developer notes to shoppers', (tester) async {
    // 예전엔 장바구니 줄에 'local cart · persisted on this device', 합계 아래에 '// API에는 …' 같은 개발용 문구가 보였다.
    final store = AppStore(repository: FakeRepository(results: const []));
    store.catalogProducts = const [homeProduct];
    store.cartQuantities = {homeProduct.id: 1};
    await tester.pumpWidget(DoguApp(store: store, initializeStore: false, initialTabIndex: 4));
    await tester.pump();

    expect(find.text(homeProduct.name), findsOneWidget);
    expect(find.textContaining('persisted'), findsNothing);
    expect(find.textContaining('// '), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('payment sheet: outside tap cancels before paying, waits while paying, and continues to the delivery notice after', (tester) async {
    // 운영에서 결제가 끝난 뒤(또는 결제 중) 바깥을 누르면 장바구니만 비고 배송 안내·참은 돈 적립이 건너뛰어졌다.
    final store = AppStore(repository: FakeRepository(results: const []));
    store.newProducts = const [
      ProductItem(id: 'cart-a', brand: 'CART', name: '선택 상품', price: '₩10,000', oldPrice: '₩20,000', discount: '-50%', pattern: PatternKind.dots),
    ];
    store.cartQuantities = {'cart-a': 1};
    await tester.pumpWidget(DoguApp(store: store, initializeStore: false, initialTabIndex: 4));
    const outside = Offset(10, 10);

    await tester.tap(find.text('결제하기 (1)  →'));
    await tester.pumpAndSettle();
    await tester.tapAt(outside);
    await tester.pumpAndSettle();
    expect(find.byType(PaymentToastOverlay), findsNothing, reason: '결제 전에는 바깥을 누르면 취소');
    expect(store.cartQuantities, {'cart-a': 1});

    await tester.tap(find.text('결제하기 (1)  →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('결제하기'));
    await tester.pump();
    await tester.tapAt(outside);
    await tester.pump();
    expect(find.byType(PaymentToastOverlay), findsOneWidget, reason: '결제 중엔 닫히지 않는다');

    await tester.pumpAndSettle();
    expect(find.text('결제가 완료되었습니다.'), findsOneWidget);
    await tester.tapAt(outside);
    await tester.pumpAndSettle();
    expect(find.byType(PaymentToastOverlay), findsNothing);
    expect(find.byType(OrderDeliveryPage), findsOneWidget, reason: "결제 뒤 바깥을 누르면 '확인'처럼 배송 안내로");
    expect(store.savedInMonth(DateTime.now()), 10000, reason: '참은 돈도 적립된다');
  });
}
