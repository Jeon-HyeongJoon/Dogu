// 골든(화면 스냅샷) 테스트 공용 준비 — 폰트 등록, 로고 디코딩, 결정적인 화면 데이터.
//
// 화면 전체 골든은 디자인 시스템 분리(packages/dogu_ui) 같은 "화면이 바뀌면 안 되는" 정리의 안전망이다.
// 정본 PNG는 CI(ubuntu) 렌더 — 로컬 macOS에선 폰트/AA 차이로 깨진다(scripts/test_modules.sh 기본 제외).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import 'fakes.dart';

/// 앱이 쓰는 폰트를 테스트 엔진에 등록한다(setUpAll에서 한 번).
Future<void> loadGoldenFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFont(doguFontFamily, doguFontAssets);
  await _loadFont(doguTitleFontFamily, doguTitleEssentialFontAssets);
  await _loadFont(doguJokeFontFamily, doguJokeFontAssets);
  // MonoText의 'monospace'는 테스트 환경에서 Ahem(모든 글리프를 사각형으로 그리는 테스트 폰트)으로
  // 잡혀 폴백이 걸리지 않는다. 실제 기기의 시스템 고정폭 폰트를 대신해 본문체를 그 이름으로 등록한다.
  await _loadFont('monospace', doguFontAssets);
  final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

Future<void> _loadFont(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}

/// 뷰포트를 고정한다(테스트가 끝나면 원래대로).
void setGoldenViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 헤더·푸터 로고는 PNG 에셋이라 디코딩을 강제해야 골든에 실제로 찍힌다.
Future<void> precacheLogo(WidgetTester tester, Finder context) async {
  await tester.runAsync(() async {
    await precacheImage(const AssetImage(DoguLogoMark.assetKey), tester.element(context));
  });
  await tester.pump();
}

/// 골든을 찍은 뒤 위젯 트리를 내려 딜 카운트다운·티커 같은 타이머를 정리한다.
Future<void> disposeTree(WidgetTester tester) => tester.pumpWidget(const SizedBox());

ProductItem _product(int i, String brand, String name, int price, int oldPrice, {String? badge, List<String> tags = const []}) {
  String won(int v) => '₩${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
  final discount = oldPrice > price ? '-${((oldPrice - price) * 100 / oldPrice).round()}%' : '-0%';
  return ProductItem(
    id: 'g-$i',
    brand: brand,
    name: name,
    price: won(price),
    oldPrice: won(oldPrice),
    discount: discount,
    pattern: PatternKind.values[i % PatternKind.values.length],
    badge: badge,
    rating: 4.6,
    reviews: 1200 + i * 37,
    tags: tags,
  );
}

/// 화면 골든용 상품 — 이미지 URL이 없어 네트워크 없이 항상 같은 '이미지 준비 중' 자리로 그려진다.
final goldenProducts = <ProductItem>[
  _product(1, '스파클Mart', '스파클 생수 2L 12병', 9900, 13900, badge: 'BEST', tags: ['today_deal']),
  _product(2, '매일유업', '소화가 잘되는 우유 190ml 24팩', 21900, 26900, tags: ['today_deal']),
  _product(3, '닥터바이', '강아지 관절 영양제 60정', 32000, 45000, tags: ['today_deal']),
  _product(4, '헤븐센스', '유아 저자극 로션 300ml', 18500, 18500, tags: ['new_arrival']),
  _product(5, '미엘물티슈', '도톰한 엠보싱 물티슈 100매 10팩', 15900, 22900, tags: ['new_arrival']),
  _product(6, '밴더마켓', '무드 조명 LED 스탠드', 39000, 52000, badge: 'NEW', tags: ['new_arrival']),
  _product(7, '슈퍼언더웨어', '여성 심리스 드로즈 5매', 24900, 29900),
  _product(8, '건지울른스', '메리노울 라운드넥 가디건', 142400, 178000),
];

/// 화면 골든용 스토어 — 백엔드 응답이 끝난 뒤(로딩 아님)의 결정적인 상태.
AppStore goldenStore() {
  final store = AppStore(repository: FakeRepository(detailProduct: goldenProducts[7]));
  const labels = ['식품', '생활용품', '반려동물용품', '건강/의료용품', '화장품/미용', '출산/유아동', '조명/인테리어', '여성의류', '남성의류'];
  store.categories = [
    for (final (i, label) in labels.indexed)
      CategoryItem(label, '100', PatternKind.dots, id: 'c$i', featured: true, homeRank: i + 1),
    const CategoryItem('공구', '100', PatternKind.dots, id: 'tools'),
    const CategoryItem('가구', '100', PatternKind.dots, id: 'furniture'),
  ]..sort((a, b) => a.name.compareTo(b.name));
  store
    ..usingFallback = false
    ..catalogLoading = false
    ..dealProducts = goldenProducts.sublist(0, 3)
    ..newProducts = goldenProducts.sublist(3, 6)
    ..catalogProducts = goldenProducts
    ..featuredProduct = goldenProducts[7]
    ..recommendedProducts = goldenProducts.sublist(4, 8)
    ..heroStats = const [('6', '신상품'), ('16,092', '브랜드'), ('−32%', '평균 할인')]
    ..heroDate = ''
    ..suggestions = const ['스파클Mart', '아모레퍼시픽몰 헤어바디', '닥터바이', '털보네 액상공장', '미엘물티슈', '헤븐센스']
    ..recentSearches = const ['가디건', '생수']
    ..wishlistIds = {goldenProducts[2].id, goldenProducts[6].id}
    ..cartQuantities = {goldenProducts[0].id: 2, goldenProducts[7].id: 1};
  return store;
}
