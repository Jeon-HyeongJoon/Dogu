@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/golden.dart';

// 주문 완료 흐름(배송 안내 → 주문 결과) 두 화면을 모바일 뷰포트로 스냅샷한다.
// 골든 정본은 CI(ubuntu) 렌더 — 이 모듈의 CI 잡이 함께 돌린다. 로컬(macOS)에선 폰트/AA 차이로 깨지니
// scripts/test_modules.sh는 기본으로 제외한다. 정본 갱신: Actions → Update goldens.
void main() {
  setUpAll(loadGoldenFonts);

  // 모바일과 넓은 뷰포트 둘 다 — 두 화면이 앱의 다른 페이지들처럼 브라우저 폭을
  // 그대로 따라가는지(390px 고정 컬럼으로 굳지 않는지) 회귀로 잡는다.
  const sizes = <({String name, Size size})>[
    (name: 'mobile', size: Size(390, 844)),
    (name: 'wide', size: Size(1024, 844)),
  ];

  for (final s in sizes) {
    testWidgets('order delivery notice renders on ${s.name}', (tester) async {
      await _pumpOrder(tester, size: s.size, reveal: false);
      await expectLater(
        find.byType(OrderDeliveryPage),
        matchesGoldenFile('goldens/order_delivery_${s.name}.png'),
      );
    });

    testWidgets('order result renders on ${s.name}', (tester) async {
      await _pumpOrder(tester, size: s.size, reveal: true);
      await expectLater(
        find.byType(OrderRevealPage),
        matchesGoldenFile('goldens/order_reveal_${s.name}.png'),
      );
    });
  }
}


/// 날짜·주문번호·누적액을 고정한 영수증으로 결정적으로 렌더한다.
Future<void> _pumpOrder(WidgetTester tester, {required Size size, required bool reveal}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  // initialize()를 부르지 않아 store 필드는 seed 파생 fallback(결정적 데이터)로 유지된다.
  final store = AppStore();
  final products = store.newProducts;
  final receipt = OrderReceipt(
    code: 'ord_local_002608',
    lines: [
      (product: products[0], quantity: 1),
      (product: products[1], quantity: 2),
    ],
    total: products[0].numericPrice + products[1].numericPrice * 2,
    placedAt: DateTime(2026, 8, 28, 21, 4),
    savedThisMonth: 412300,
  );
  await tester.pumpWidget(
    AppStateScope(
      store: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildDoguTheme(), // 앱과 같은 테마(본문체·색)
        home: reveal ? OrderRevealPage(receipt: receipt) : OrderDeliveryPage(receipt: receipt),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
