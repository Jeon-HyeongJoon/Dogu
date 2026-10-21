@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/golden.dart';

// 브랜드 락업(로고 + '욕망의 장바구니' 손글씨 타이틀)을 상단 헤더와 하단 푸터
// 양쪽에서 이미지로 확인한다 — 둘은 DoguBrandLockup 하나를 공유하므로 같아야 한다.
// 골든 정본은 CI(ubuntu) 렌더 — 이 모듈의 CI 잡이 함께 돌린다. 로컬(macOS)에선 폰트/AA 차이로 깨지니
// scripts/test_modules.sh는 기본으로 제외한다. 정본 갱신: Actions → Update goldens.
void main() {
  setUpAll(loadGoldenFonts);

  testWidgets('v1 header — logo and title sizing', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(390 * 3, 90 * 3);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildDoguTheme(),
          home: const Scaffold(body: Align(alignment: Alignment.topCenter, child: Header())),
        ),
      ),
    );
    // 헤더 로고는 PNG 에셋이라 디코딩을 강제해야 골든에 실제로 찍힌다.
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage(DoguLogoMark.assetKey),
        tester.element(find.byType(Header)),
      );
    });
    await tester.pumpAndSettle();

    await expectLater(find.byType(Header), matchesGoldenFile('goldens/v1_header.png'));
  });

  testWidgets('v1 footer — brand lockup matches the header', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildDoguTheme(), // 앱과 같은 테마(본문체·색)
          home: const Scaffold(
            body: SingleChildScrollView(child: FooterSection()),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage(DoguLogoMark.assetKey),
        tester.element(find.byType(FooterSection)),
      );
    });
    await tester.pumpAndSettle();

    await expectLater(find.byType(FooterSection), matchesGoldenFile('goldens/v1_footer.png'));
  });
}

