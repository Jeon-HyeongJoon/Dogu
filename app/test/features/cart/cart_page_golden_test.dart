@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/golden.dart';
import '../../support/harness.dart';

// 화면 전체 골든 — 디자인 시스템 분리(packages/dogu_ui)처럼 "화면이 바뀌면 안 되는" 정리의 안전망.
// 정본은 CI(ubuntu) 렌더. 갱신: Actions → Update goldens.
void main() {
  setUpDoguTest();
  setUpAll(loadGoldenFonts);

  testWidgets('cart tab — mobile 390px', (tester) async {
    setGoldenViewport(tester, const Size(390, 1500));
    await tester.pumpWidget(DoguApp(store: goldenStore(), initializeStore: false, initialTabIndex: 4));
    await precacheLogo(tester, find.byType(Header));

    await expectLater(find.byType(DoguApp), matchesGoldenFile('goldens/cart_page_mobile.png'));
    await disposeTree(tester);
  });
}
