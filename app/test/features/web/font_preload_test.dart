import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/assets.dart';

// web/index.html은 첫 페인트 전에 등록하는 폰트를 엔진과 나란히 미리 받는다(preload).
// 코드의 폰트 목록과 어긋나면 지운 파일을 계속 받거나(Task 56 뒤 Pretendard 4개를 받던 사고),
// 필요한 폰트를 미리 못 받아 첫 화면이 늦어진다. 그 어긋남을 여기서 잡는다.
void main() {
  final html = File('web/index.html').readAsStringSync();
  final preloads = RegExp(r'<link rel="preload"[^>]*>').allMatches(html).map((m) => m.group(0)!).toList();

  test('index.html preloads exactly the fonts registered before first paint', () {
    final hrefs = preloads.map((tag) => RegExp(r'href="([^"]+)"').firstMatch(tag)!.group(1)!).toSet();
    final expected = {
      for (final asset in [...doguEssentialFontAssets, ...doguTitleEssentialFontAssets, ...doguSerifFontAssets]) 'assets/$asset',
    };
    expect(hrefs, expected);
    for (final asset in [...doguEssentialFontAssets, ...doguTitleEssentialFontAssets, ...doguSerifFontAssets]) {
      expect(File(assetFile(asset)).existsSync(), isTrue, reason: '$asset 가 없다');
    }
  });

  test('font preloads use as="fetch" with crossorigin so Flutter reuses them', () {
    // Flutter는 폰트 바이트를 fetch()로 읽는다 — as="font"면 미리 받은 것을 못 쓰고 한 번 더 받는다.
    for (final tag in preloads) {
      expect(tag, contains('as="fetch"'), reason: tag);
      expect(tag, contains('crossorigin'), reason: tag);
    }
  });

  test('list images ask the Naver image server for a thumbnail; detail keeps the original', () {
    const source = 'https://shopping-phinf.pstatic.net/main_1/1.jpg';
    String proxied(String url) => Uri.parse(url).queryParameters['url']!;

    expect(proxied(ApiConfig.imageUrl(source, thumbnailWidth: 640)), '$source?type=f640');
    expect(proxied(ApiConfig.imageUrl(source, thumbnailWidth: 300)), '$source?type=f300');
    expect(proxied(ApiConfig.imageUrl(source)), source, reason: '상세는 원본');
    // 이미지 서버가 모르는 너비(f960 이상은 404)는 붙이지 않는다.
    expect(proxied(ApiConfig.imageUrl(source, thumbnailWidth: 960)), source);
    // 네이버 밖 이미지는 손대지 않는다.
    expect(ApiConfig.imageUrl('https://example.com/a.jpg', thumbnailWidth: 640), 'https://example.com/a.jpg');
  });
}
