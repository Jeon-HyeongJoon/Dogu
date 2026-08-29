@Tags(['golden'])
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dogu_mobile_shop/main.dart';

// 주문 완료 흐름(배송 안내 → 주문 결과) 두 화면을 모바일 뷰포트로 스냅샷한다.
// golden 태그 → CI 제외. (재)생성: flutter test --update-goldens --tags golden
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // 앱 폰트는 pubspec `fonts:`가 아니라 런타임 FontLoader로 등록되어 FontManifest에
    // 없으므로, 앱의 폰트 상수로 직접 로드한다(한글 글리프 보장).
    await _loadFont(doguFontFamily, doguFontAssets);
    // 브랜드 손글씨체(폴백)와 농담 한 줄이 실제로 쓰는 Gaegu Bold 서브셋.
    await _loadFont(doguTitleFontFamily, doguTitleEssentialFontAssets);
    await _loadFont(doguJokeFontFamily, doguJokeFontAssets);
    // MonoText의 'monospace'는 테스트 환경에서 Ahem(모든 글리프를 사각형으로 그리는
    // 테스트 폰트)으로 잡혀 폴백이 걸리지 않는다. 실제 기기/브라우저의 시스템 고정폭
    // 폰트를 대신해 본문체를 그 이름으로 등록해 골든이 읽히게 한다.
    await _loadFont('monospace', doguFontAssets);
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

  // 모바일과 넓은 뷰포트 둘 다 — 두 화면이 앱의 다른 페이지들처럼 브라우저 폭을
  // 그대로 따라가는지(390px 고정 컬럼으로 굳지 않는지) 회귀로 잡는다.
  const sizes = <({String name, Size size})>[
    (name: 'mobile', size: Size(390, 844)),
    (name: 'wide', size: Size(1024, 844)),
  ];

  for (final s in sizes) {
    testWidgets('order delivery notice renders on ${s.name}', (tester) async {
      await _pumpOrder(tester, size: s.size, reveal: false);
      await expectLater(
        find.byType(OrderDeliveryPage),
        matchesGoldenFile('goldens/order_delivery_${s.name}.png'),
      );
    });

    testWidgets('order result renders on ${s.name}', (tester) async {
      await _pumpOrder(tester, size: s.size, reveal: true);
      await expectLater(
        find.byType(OrderRevealPage),
        matchesGoldenFile('goldens/order_reveal_${s.name}.png'),
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

/// 날짜·주문번호·누적액을 고정한 영수증으로 결정적으로 렌더한다.
Future<void> _pumpOrder(WidgetTester tester, {required Size size, required bool reveal}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  // initialize()를 부르지 않아 store 필드는 seed 파생 fallback(결정적 데이터)로 유지된다.
  final store = AppStore();
  final products = store.newProducts;
  final receipt = OrderReceipt(
    code: 'ord_local_002608',
    lines: [
      (product: products[0], quantity: 1),
      (product: products[1], quantity: 2),
    ],
    total: products[0].numericPrice + products[1].numericPrice * 2,
    placedAt: DateTime(2026, 8, 28, 21, 4),
    savedThisMonth: 412300,
  );
  await tester.pumpWidget(
    AppStateScope(
      store: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // 앱과 동일하게 기본 본문체를 지정한다 — 없으면 테마 기본 폰트에 한글 글리프가 없어
        // 명시 fontFamily가 없는 Text가 전부 두부(⊠)로 찍힌다.
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.bg,
          fontFamily: doguFontFamily,
          textTheme: const TextTheme(bodyMedium: TextStyle(color: AppColors.ink, height: 1.5)),
        ),
        home: reveal ? OrderRevealPage(receipt: receipt) : OrderDeliveryPage(receipt: receipt),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
