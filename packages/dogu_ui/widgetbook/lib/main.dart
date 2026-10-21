// dogu_ui 디자인 시스템 카탈로그. 사례는 use_cases.dart — 컴포넌트 골든 테스트와 같은 목록이다.
//   cd packages/dogu_ui/widgetbook && flutter run -d chrome
import 'package:dogu_ui/dogu_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:widgetbook/widgetbook.dart';

import 'use_cases.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 앱과 같은 글꼴로 그린다 — 폰트는 디자인 시스템이 담고, 이름으로 등록해 쓴다.
  await loadCatalogFonts();
  runApp(const DoguCatalog());
}

Future<void> loadCatalogFonts() => Future.wait([
      _loadFontFamily(doguFontFamily, doguFontAssets),
      _loadFontFamily(doguTitleFontFamily, doguTitleEssentialFontAssets),
      _loadFontFamily(doguJokeFontFamily, doguJokeFontAssets),
      _loadFontFamily(doguSerifFontFamily, doguSerifFontAssets),
    ]);

Future<void> _loadFontFamily(String family, List<String> assets) {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  return loader.load();
}

class DoguCatalog extends StatelessWidget {
  const DoguCatalog({super.key});

  @override
  Widget build(BuildContext context) {
    const groups = ['atoms', 'molecules', 'organisms', 'brand'];
    return Widgetbook.material(
      lightTheme: buildDoguTheme(),
      directories: [
        for (final group in groups)
          WidgetbookFolder(
            name: group,
            children: [
              for (final entry in doguComponentCases.where((c) => c.group == group))
                WidgetbookComponent(
                  name: entry.component,
                  useCases: [
                    for (final useCase in entry.cases)
                      WidgetbookUseCase(name: useCase.name, builder: (context) => CatalogFrame(useCase: useCase)),
                  ],
                ),
            ],
          ),
      ],
      addons: [
        ViewportAddon([Viewports.none, IosViewports.iPhone13, AndroidViewports.samsungGalaxyS20]),
        TextScaleAddon(min: 1.0, max: 2.0),
        ZoomAddon(),
        InspectorAddon(),
      ],
    );
  }
}

/// 사례를 그 바탕(페이지 초록 / 가장 깊은 초록 띠) 위 가운데에 놓는다 — 골든도 같은 틀로 찍는다.
class CatalogFrame extends StatelessWidget {
  const CatalogFrame({required this.useCase, super.key});

  final DoguUseCase useCase;

  @override
  Widget build(BuildContext context) {
    // Material — 앱 화면의 Scaffold처럼 기본 글자 스타일을 준다(없으면 글자에 노란 경고 밑줄이 붙는다).
    return Material(
      color: useCase.dark ? AppColors.deep : AppColors.bg,
      child: Center(child: Builder(builder: useCase.build)),
    );
  }
}
