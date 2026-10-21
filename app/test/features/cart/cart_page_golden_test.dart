@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/golden.dart';
import '../../support/harness.dart';

// 화면 전체 골든 — 화면이 바뀌면 안 되는 정리의 안전망이자, 디자인을 바꿀 때 전후를 보는 검토 화면.
// 상태(로딩·빈 목록·결과)와 폭(390 모바일·1024 와이드)마다 한 장. 정본은 CI(ubuntu) 렌더. 갱신: Actions → Update goldens.
void main() {
  setUpDoguTest();
  setUpAll(loadGoldenFonts);

  testWidgets('cart tab — mobile 390px', (tester) async {
    await pumpGoldenApp(tester, const Size(390, 1500), tab: 4);
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/cart_page_mobile.png'));
    await disposeTree(tester);
  });

  testWidgets('cart tab — wide 1024px', (tester) async {
    await pumpGoldenApp(tester, const Size(1024, 1300), tab: 4);
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/cart_page_wide.png'));
    await disposeTree(tester);
  });

  testWidgets('cart tab — empty (mobile)', (tester) async {
    final store = goldenStore()..cartQuantities = {};
    await pumpGoldenApp(tester, const Size(390, 1300), tab: 4, store: store);
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/cart_empty_mobile.png'));
    await disposeTree(tester);
  });

  testWidgets('cart toast over the shell (mobile)', (tester) async {
    final store = goldenStore();
    await pumpGoldenApp(tester, const Size(390, 844), tab: 0, store: store);
    store.showCartToast('${goldenProducts[7].name} 1개를 장바구니에 담았습니다.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // 등장 애니메이션 끝
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/cart_toast_mobile.png'));
    await disposeTree(tester);
    await tester.pump(const Duration(seconds: 3)); // 토스트 자동 해제 타이머
  });

  testWidgets('payment sheet over the cart (mobile)', (tester) async {
    await pumpGoldenApp(tester, const Size(390, 844), tab: 4);
    await tester.tap(find.textContaining('결제하기 ('));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // 시트가 올라오는 애니메이션 끝
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/payment_sheet_mobile.png'));
    await disposeTree(tester);
  });
}
