@Tags(['golden'])
library;

import 'dart:convert';

import 'package:dogu_ui/dogu_ui.dart';
import 'package:dogu_ui_catalog/main.dart';
import 'package:dogu_ui_catalog/use_cases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// 컴포넌트 골든 — 카탈로그 사례마다 한 장. 카탈로그에서 보는 모습이 그대로 고정된다.
// 정본은 CI(ubuntu) 렌더. 갱신: Actions → Update goldens.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadCatalogFonts();
    // 머티리얼 아이콘 등 매니페스트 폰트.
    final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
    for (final entry in manifest.cast<Map<String, dynamic>>()) {
      final loader = FontLoader(entry['family'] as String);
      for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  });

  String slug(String name) => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');

  for (final entry in doguComponentCases) {
    for (final useCase in entry.cases) {
      testWidgets('${entry.group}/${entry.component} — ${useCase.name}', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = useCase.frame;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildDoguTheme(),
          home: CatalogFrame(useCase: useCase),
        ));
        // 로고는 PNG 에셋이라 디코딩을 강제해야 골든에 찍힌다.
        await tester.runAsync(() => precacheImage(const AssetImage(DoguLogoMark.assetKey), tester.element(find.byType(CatalogFrame))));
        await tester.pump();

        await expectLater(
          find.byType(CatalogFrame),
          matchesGoldenFile('goldens/${entry.group}/${entry.component}/${slug(useCase.name)}.png'),
        );
        await tester.pumpWidget(const SizedBox()); // 카운트다운·로딩 점 타이머 정리
      });
    }
  }
}
