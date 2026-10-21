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

  testWidgets('home page — mobile 390px', (tester) async {
    await pumpGoldenApp(tester, const Size(390, 4600), tab: 0);
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/home_page_mobile.png'));
    await disposeTree(tester);
  });

  testWidgets('home page — wide 1024px', (tester) async {
    await pumpGoldenApp(tester, const Size(1024, 3800), tab: 0);
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/home_page_wide.png'));
    await disposeTree(tester);
  });

  testWidgets('home page — loading (seed in, backend not yet) mobile 390px', (tester) async {
    final store = await goldenLoadingStore(tester);
    await pumpGoldenApp(tester, const Size(390, 2400), tab: 0, store: store);
    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/home_loading_mobile.png'));
    await disposeTree(tester);
  });
}
