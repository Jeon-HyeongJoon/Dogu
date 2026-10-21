@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/fakes.dart';
import '../../support/golden.dart';
import '../../support/harness.dart';

// 화면 전체 골든 — 화면이 바뀌면 안 되는 정리의 안전망이자, 디자인을 바꿀 때 전후를 보는 검토 화면.
// 상태(로딩·빈 목록·결과)와 폭(390 모바일·1024 와이드)마다 한 장. 정본은 CI(ubuntu) 렌더. 갱신: Actions → Update goldens.
void main() {
  setUpDoguTest();
  setUpAll(loadGoldenFonts);

  Future<void> pumpProduct(WidgetTester tester, Size size, AppStore store, ProductItem product) async {
    setGoldenViewport(tester, size);
    await tester.pumpWidget(goldenMaterialApp(store, ProductDetailPage(product: product)));
    await tester.pump(); // 상세 응답 반영
    await tester.pump();
  }

  testWidgets('product detail — mobile 390px', (tester) async {
    await pumpProduct(tester, const Size(390, 1400), goldenStore(), goldenProducts[7]);
    await expectLater(find.byType(ProductDetailPage), matchesGoldenFile('goldens/product_page_mobile.png'));
    await disposeTree(tester);
  });

  testWidgets('product detail — wide 1024px', (tester) async {
    await pumpProduct(tester, const Size(1024, 1400), goldenStore(), goldenProducts[7]);
    await expectLater(find.byType(ProductDetailPage), matchesGoldenFile('goldens/product_page_wide.png'));
    await disposeTree(tester);
  });

  testWidgets('product detail — opened by address, still loading (mobile)', (tester) async {
    final store = goldenStore(repository: GatedDetailRepository(Completer<void>().future));
    await pumpProduct(tester, const Size(390, 844), store, ProductItem.pending('g-8'));
    await expectLater(find.byType(ProductDetailPage), matchesGoldenFile('goldens/product_loading_mobile.png'));
    await disposeTree(tester);
  });

  testWidgets('product detail — opened by address, not found (mobile)', (tester) async {
    final store = goldenStore(repository: FakeRepository(shouldThrowDetail: true));
    await pumpProduct(tester, const Size(390, 844), store, ProductItem.pending('gone'));
    await expectLater(find.byType(ProductDetailPage), matchesGoldenFile('goldens/product_missing_mobile.png'));
    await disposeTree(tester);
  });
}
