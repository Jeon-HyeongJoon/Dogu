import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/assets.dart';

// 본문체(Dogu Sans)는 Pretendard 서브셋이라 charset.txt에 없는 글자는 두부(⊠)로 찍힌다.
// 카피를 고치거나 카탈로그가 바뀌었을 때 그 사고를 여기서 잡는다.
// 실패하면: scripts/build_fonts.sh 를 다시 돌릴 것(charset을 seed·소스에서 다시 만든다).
void main() {
  late Set<int> charset;

  setUpAll(() {
    final file = File('$designFontsDir/dogusans/charset.txt');
    expect(file.existsSync(), isTrue, reason: '${file.path} 가 없다');
    charset = file
        .readAsLinesSync()
        .where((line) => !line.startsWith('#'))
        .join()
        .runes
        .toSet();
    expect(charset.length, greaterThan(2000), reason: 'charset이 비정상적으로 작다');
  });

  Set<String> missingFrom(String text) => text.runes
      .where((rune) => rune != 0x0A && rune != 0x0D && rune != 0x09)
      .where((rune) => !charset.contains(rune))
      .map(String.fromCharCode)
      .toSet();

  test('번들 카탈로그(seed.json)의 모든 글자를 본문체가 그릴 수 있다', () {
    // 앱이 오프라인에서 그리는 상품명·브랜드·카피가 전부 여기 들어 있다.
    final seed = File('assets/seed.json').readAsStringSync();
    final missing = missingFrom(seed);
    expect(
      missing,
      isEmpty,
      reason: 'seed에 서브셋 밖 글자가 있다: ${missing.join()} — scripts/build_fonts.sh 재실행',
    );
  });

  test('앱 소스의 하드코딩 문자열을 본문체가 그릴 수 있다', () {
    // 앱과 디자인 시스템(packages/dogu_ui) 소스 모두 — 컴포넌트 문구('이미지 준비 중' 등)는 패키지에 있다.
    final missing = <String>{};
    for (final dir in ['lib', '../packages/dogu_ui/lib']) {
      for (final entity in Directory(dir).listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          missing.addAll(missingFrom(entity.readAsStringSync()));
        }
      }
    }
    expect(
      missing,
      isEmpty,
      reason: '소스에 서브셋 밖 글자가 있다: ${missing.join()} — scripts/build_fonts.sh 재실행',
    );
  });

  test('상용 한글(KS X 1001) 2350자를 모두 담고 있다', () {
    // 실서버 카탈로그는 seed보다 상품이 많다. 크롤링된 상품명이 두부로 찍히지 않도록
    // 서브셋은 상용 한글 전체를 포함해야 한다.
    final hangul = charset.where((rune) => rune >= 0xAC00 && rune <= 0xD7A3);
    expect(hangul.length, greaterThanOrEqualTo(2350));
  });

  test('본문체 에셋이 서브셋이다 (통짜 원본을 커밋하지 않았다)', () {
    for (final asset in doguFontAssets) {
      final file = File(assetFile(asset));
      expect(file.existsSync(), isTrue, reason: '$asset 가 없다');
      // 원본 Pretendard는 굵기당 약 1.5MB — 실수로 통짜를 커밋하면 여기서 걸린다.
      expect(
        file.lengthSync(),
        lessThan(700 * 1024),
        reason: '$asset 가 서브셋이 아닌 것으로 보인다 (scripts/build_fonts.sh)',
      );
    }
  });

  // ── 장식용 서체 두 벌 — 정해진 문구만 담는 아주 작은 서브셋이라,
  //    문구를 고치면서 폰트를 다시 만들지 않으면 그 글자가 두부(⊠)로 찍힌다.

  void expectCovers(String label, String fontAsset, String charsetPath, String text, int maxBytes) {
    final charsetFile = File(charsetPath);
    expect(charsetFile.existsSync(), isTrue, reason: '$charsetPath 가 없다');
    final covered = charsetFile
        .readAsLinesSync()
        .where((line) => !line.startsWith('#'))
        .join()
        .runes
        .toSet();

    final missing = text.runes
        .where((rune) => !covered.contains(rune))
        .map(String.fromCharCode)
        .toSet();
    expect(
      missing,
      isEmpty,
      reason: '$label 서브셋에 없는 글자: ${missing.join()} — scripts/build_fonts.sh 재실행',
    );

    final font = File(assetFile(fontAsset));
    expect(font.existsSync(), isTrue, reason: '$fontAsset 가 없다');
    expect(
      font.lengthSync(),
      lessThan(maxBytes),
      reason: '$fontAsset 가 서브셋이 아닌 것으로 보인다 (scripts/build_fonts.sh)',
    );
  }

  test('브랜드 타이틀의 모든 글자를 타이틀 서체가 그릴 수 있다', () {
    // 첫 페인트를 막고 로드되는 서체 — 통짜(416KB)를 되돌리면 첫 화면이 그만큼 늦어진다.
    expectCovers(
      '타이틀',
      doguTitleEssentialFontAssets.single,
      '$designFontsDir/doguhand/charset.txt',
      DoguBrandLockup.brandName,
      64 * 1024,
    );
  });

  test('농담 한 줄의 모든 글자를 농담 서체가 그릴 수 있다', () {
    expectCovers(
      '농담',
      doguJokeFontAssets.single,
      '$designFontsDir/gaegu/charset.txt',
      OrderRevealPage.jokeLine,
      400 * 1024,
    );
  });

  test('타이틀 서체는 농담 줄의 폴백이므로 그 글자도 담는다', () {
    expectCovers(
      '타이틀(폴백)',
      doguTitleEssentialFontAssets.single,
      '$designFontsDir/doguhand/charset.txt',
      OrderRevealPage.jokeLine,
      64 * 1024,
    );
  });
}
