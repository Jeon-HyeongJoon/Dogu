@Tags(['golden'])
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dogu_mobile_shop/main.dart';

// v1 상단 헤더(로고 + '욕망의 장바구니' 손글씨 타이틀)의 크기 정렬을 이미지로 확인한다.
// golden 태그 → CI 제외. (재)생성: flutter test --update-goldens --tags golden
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFont(doguFontFamily, doguFontAssets);
    await _loadFont(doguHeroFontFamily, doguHeroFontAssets);
    await _loadFont(doguTitleFontFamily, doguTitleEssentialFontAssets);
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
    // 로고는 벡터 마크(DoguBrandMark)라 이미지 디코딩 없이 바로 렌더된다.
    await tester.pumpAndSettle();

    await expectLater(find.byType(Header), matchesGoldenFile('goldens/v1_header.png'));
  });
}

Future<void> _loadFont(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}
