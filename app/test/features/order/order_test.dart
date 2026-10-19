import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/fakes.dart';
import '../../support/harness.dart';

void main() {
  setUpDoguTest();

  // ── TDD P1-1: 결제 완료 → 배송 안내 → 주문 결과 → 홈 이동 ────────────────────

  testWidgets('payment confirm opens the delivery notice, then the not-shipped result, then home', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
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

    // 확인 → 배송 안내 화면(주문은 접수된 척한다)
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(OrderDeliveryPage), findsOneWidget);
    expect(find.text('배송 준비 중'), findsOneWidget);
    // 결제 금액은 이번 달 '참은 돈'으로 적립된다.
    expect(store.savedInMonth(DateTime.now()), 10000);

    // 확인 → 반전: 아무것도 보내지 않았다
    await tester.tap(find.byKey(const Key('order_confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(OrderRevealPage), findsOneWidget);
    expect(find.text('사실은요,\n안 보냈습니다'), findsOneWidget);
    expect(find.byKey(const Key('order_joke')), findsOneWidget);
    expect(find.text('미발송'), findsOneWidget);
    // 배송 안내로는 돌아갈 수 없다(pushReplacement).
    expect(find.byType(OrderDeliveryPage), findsNothing);

    // 마지막 CTA → 홈 탭으로 이동
    await tester.tap(find.byKey(const Key('order_done')));
    await tester.pumpAndSettle();

    // 홈 탭의 검색바 플레이스홀더가 보여야 함
    expect(find.text('찾고 싶은 욕망을 입력하세요'), findsOneWidget);
  });
}
