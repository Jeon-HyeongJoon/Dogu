@Tags(['golden'])
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dogu_mobile_shop/main.dart';

// v2(aggressive-clean 테마) 5탭을 모바일/태블릿 뷰포트로 이미지 스냅샷한다.
// 크로스플랫폼 렌더 차이가 있어 CI의 flutter test는 `--exclude-tags golden`으로 제외한다.
// 이미지 (재)생성:  flutter test --update-goldens --tags golden
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // 앱 폰트는 pubspec `fonts:`가 아니라 런타임 FontLoader로 등록되어 FontManifest에
    // 없으므로, 앱의 폰트 상수로 직접 로드한다(한글 글리프 보장).
    await _loadFont(doguFontFamily, doguFontAssets);
    await _loadFont(doguHeroFontFamily, doguHeroFontAssets);
    // 주문 결과 화면의 농담 한 줄이 쓰는 손글씨체(HSBombaram).
    await _loadFont(doguTitleFontFamily, doguTitleEssentialFontAssets);
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

  // 주문 완료 흐름 — 배송 안내와 그 다음 장(주문 결과)을 각각 스냅샷한다.
  testWidgets('v2 order delivery notice renders', (tester) async {
    await _pumpOrder(tester, const Size(390, 844), reveal: false);
    await expectLater(
      find.byType(V2OrderDeliveryPage),
      matchesGoldenFile('goldens/v2_order_delivery.png'),
    );
  });

  testWidgets('v2 order result renders', (tester) async {
    await _pumpOrder(tester, const Size(390, 844), reveal: true);
    await expectLater(
      find.byType(V2OrderRevealPage),
      matchesGoldenFile('goldens/v2_order_reveal.png'),
    );
  });

  // 액션바의 수량 스테퍼(− 1 +)만 정밀 스냅샷 — +/- 버튼 크기·정렬 회귀를 좁게 잡는다.
  testWidgets('v2 detail quantity stepper renders', (tester) async {
    await _pumpDetail(tester, const Size(390, 844));
    await expectLater(
      find.byKey(const Key('v2_qty_stepper')),
      matchesGoldenFile('goldens/v2_detail_qty_stepper.png'),
    );
  });
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
  // 장바구니/찜 탭은 기능 레이아웃이 보이도록 샘플 상품을 시드한다.
  if (initialTab == 4) {
    store.cartQuantities = {'p01': 2, 'p03': 1};
  } else if (initialTab == 3) {
    store.wishlistIds = {'p01', 'p03'};
  }
  await tester.pumpWidget(
    AppStateScope(
      store: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: V2Shell(initialTab: initialTab),
      ),
    ),
  );
  // 항아리 엠블럼(PNG) 디코딩을 강제해 골든에 실제로 렌더되게 한다.
  await tester.runAsync(() async {
    await precacheImage(const AssetImage('assets/logo-square.png'), tester.element(find.byType(V2Shell)));
  });
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

/// 주문 흐름 골든 — 날짜·주문번호·누적액을 고정한 영수증으로 결정적으로 렌더한다.
Future<void> _pumpOrder(WidgetTester tester, Size size, {required bool reveal}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final store = AppStore();
  final products = store.newProducts;
  final receipt = V2OrderReceipt(
    code: 'DD-2608-0417',
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
        home: reveal ? V2OrderRevealPage(receipt: receipt) : V2OrderDeliveryPage(receipt: receipt),
      ),
    ),
  );
  if (reveal) {
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/logo-square.png'),
        tester.element(find.byType(V2OrderRevealPage)),
      );
    });
  }
  await tester.pumpAndSettle();
}
