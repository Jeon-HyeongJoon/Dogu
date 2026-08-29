@Tags(['golden'])
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dogu_mobile_shop/main.dart';

// 브랜드 락업(로고 + '욕망의 장바구니' 손글씨 타이틀)을 상단 헤더와 하단 푸터
// 양쪽에서 이미지로 확인한다 — 둘은 DoguBrandLockup 하나를 공유하므로 같아야 한다.
// golden 태그 → CI 제외. (재)생성: flutter test --update-goldens --tags golden
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFont(doguFontFamily, doguFontAssets);
    await _loadFont(doguTitleFontFamily, doguTitleEssentialFontAssets);
    // MonoText의 'monospace'는 테스트 환경에서 Ahem(모든 글리프를 사각형으로 그리는
    // 테스트 폰트)으로 잡혀 폴백이 걸리지 않는다. 실제 기기/브라우저의 시스템 고정폭
    // 폰트를 대신해 본문체를 그 이름으로 등록해 골든이 읽히게 한다.
    await _loadFont('monospace', doguFontAssets);
    final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
    for (final entry in manifest.cast<Map<String, dynamic>>()) {
      final loader = FontLoader(entry['family'] as String);
      for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  });

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
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: Align(alignment: Alignment.topCenter, child: Header())),
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
          // 앱과 동일하게 기본 본문체를 지정한다 — 없으면 명시 fontFamily가 없는 Text가
          // 테마 기본 폰트(한글 글리프 없음)로 잡혀 전부 두부(⊠)로 찍힌다.
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.bg,
            fontFamily: doguFontFamily,
            textTheme: const TextTheme(bodyMedium: TextStyle(color: AppColors.ink, height: 1.5)),
          ),
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

Future<void> _loadFont(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}
