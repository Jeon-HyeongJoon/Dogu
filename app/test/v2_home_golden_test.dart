@Tags(['golden'])
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dogu_mobile_shop/main.dart';

// v2(유희왕 마법 카드 테마) 5탭을 모바일/태블릿 뷰포트로 이미지 스냅샷한다.
// 크로스플랫폼 렌더 차이가 있어 CI의 flutter test는 `--exclude-tags golden`으로 제외한다.
// 이미지 (재)생성:  flutter test --update-goldens --tags golden
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // 앱 폰트는 pubspec `fonts:`가 아니라 런타임 FontLoader로 등록되어 FontManifest에
    // 없으므로, 앱의 폰트 상수로 직접 로드한다(한글 글리프 보장).
    await _loadFont(doguFontFamily, doguFontAssets);
    await _loadFont(doguHeroFontFamily, doguHeroFontAssets);
    // MaterialIcons 등 프레임워크/pubspec 등록 폰트는 FontManifest에서 로드(아이콘 글리프).
    final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
    for (final entry in manifest.cast<Map<String, dynamic>>()) {
      final loader = FontLoader(entry['family'] as String);
      for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  });

  const tabs = <({int index, String name})>[
    (index: 0, name: 'home'),
    (index: 1, name: 'category'),
    (index: 2, name: 'search'),
    (index: 3, name: 'wish'),
    (index: 4, name: 'cart'),
  ];
  const sizes = <({String name, Size size})>[
    (name: 'mobile', size: Size(390, 844)),
    (name: 'tablet', size: Size(834, 1112)),
  ];

  for (final tab in tabs) {
    for (final s in sizes) {
      testWidgets('v2 ${tab.name} tab renders on ${s.name}', (tester) async {
        await _pumpShell(tester, s.size, tab.index);
        await expectLater(
          find.byType(V2Shell),
          matchesGoldenFile('goldens/v2_${tab.name}_${s.name}.png'),
        );
      });
    }
  }

  for (final s in sizes) {
    testWidgets('v2 product detail renders on ${s.name}', (tester) async {
      await _pumpDetail(tester, s.size);
      await expectLater(
        find.byType(V2ProductDetailPage),
        matchesGoldenFile('goldens/v2_detail_${s.name}.png'),
      );
    });
  }
}

Future<void> _loadFont(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}

Future<void> _pumpShell(WidgetTester tester, Size size, int initialTab) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  // initialize()를 부르지 않아 store 필드는 seed 파생 fallback(결정적 데이터)로 유지된다.
  final store = AppStore();
  await tester.pumpWidget(
    AppStateScope(
      store: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: V2Shell(initialTab: initialTab),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpDetail(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final store = AppStore();
  final product = store.newProducts.first;
  await tester.pumpWidget(
    AppStateScope(
      store: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: V2ProductDetailPage(product: product),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
