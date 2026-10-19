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

  testWidgets('product detail — mobile 390px', (tester) async {
    setGoldenViewport(tester, const Size(390, 1400));
    final store = goldenStore();
    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          // 앱과 같은 기본 본문체 — 없으면 fontFamily가 없는 Text가 테마 기본 폰트(한글 없음)로 잡힌다.
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.bg,
            fontFamily: doguFontFamily,
            textTheme: const TextTheme(bodyMedium: TextStyle(color: AppColors.ink, height: 1.5)),
          ),
          home: ProductDetailPage(product: goldenProducts[7]),
        ),
      ),
    );
    await tester.pump(); // 상세 응답(같은 상품) 반영
    await tester.pump();

    await expectLater(find.byType(ProductDetailPage), matchesGoldenFile('goldens/product_page_mobile.png'));
    await disposeTree(tester);
  });
}
