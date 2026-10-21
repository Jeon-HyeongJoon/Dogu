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

  testWidgets('category tab — mobile 390px', (tester) async {
    await pumpGoldenApp(tester, const Size(390, 1700), tab: 1);
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/category_page_mobile.png'));
    await disposeTree(tester);
  });

  testWidgets('category tab — wide 1024px', (tester) async {
    await pumpGoldenApp(tester, const Size(1024, 1400), tab: 1);
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/category_page_wide.png'));
    await disposeTree(tester);
  });

  testWidgets('category tab — one category chosen, its products listed (mobile)', (tester) async {
    final store = goldenStore()
      ..selectedCategoryKey = 'c0'
      ..categoryProducts = goldenProducts.sublist(0, 4);
    await pumpGoldenApp(tester, const Size(390, 1500), tab: 1, store: store);
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/category_products_mobile.png'));
    await disposeTree(tester);
  });

  testWidgets('category tab — chosen category still loading (mobile)', (tester) async {
    final store = goldenStore()
      ..selectedCategoryKey = 'c0'
      ..categoryProductsLoading = true;
    await pumpGoldenApp(tester, const Size(390, 1700), tab: 1, store: store);
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/category_loading_mobile.png'));
    await disposeTree(tester);
  });
}
