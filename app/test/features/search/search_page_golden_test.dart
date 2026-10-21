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

  testWidgets('search tab — mobile 390px', (tester) async {
    await pumpGoldenApp(tester, const Size(390, 900), tab: 2);
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/search_page_mobile.png'));
    await disposeTree(tester);
  });

  testWidgets('search tab — wide 1024px', (tester) async {
    await pumpGoldenApp(tester, const Size(1024, 900), tab: 2);
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/search_page_wide.png'));
    await disposeTree(tester);
  });

  testWidgets('search tab — results (mobile)', (tester) async {
    final store = goldenStore()
      ..lastSearchTerm = '생수'
      ..searchResults = [goldenProducts[0], goldenProducts[1]];
    await pumpGoldenApp(tester, const Size(390, 1700), tab: 2, store: store);
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/search_results_mobile.png'));
    await disposeTree(tester);
  });

  testWidgets('search tab — no results (mobile)', (tester) async {
    final store = goldenStore()
      ..lastSearchTerm = '없는 상품'
      ..searchResults = const []
      ..recentSearches = const [];
    await pumpGoldenApp(tester, const Size(390, 900), tab: 2, store: store);
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/search_empty_mobile.png'));
    await disposeTree(tester);
  });
}
