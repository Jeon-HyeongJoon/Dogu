import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

// 농담 한 줄에 쓰는 Gaegu Bold는 원본(한글 2350자, 2.9MB) 대신 charset.txt의 글자만
// 남긴 서브셋(약 80KB)이다. 문구를 바꾸면서 charset과 폰트를 다시 만들지 않으면
// 그 글자가 두부(⊠)로 찍히거나 폴백 서체로 새는데, 그걸 여기서 잡는다.
// 실패하면: app/assets/fonts/gaegu/charset.txt에 글자를 더하고
//           scripts/build_joke_font.sh 를 다시 돌릴 것.
void main() {
  test('농담 한 줄의 모든 글자가 서브셋 폰트 charset에 들어 있다', () {
    final charsetFile = File('assets/fonts/gaegu/charset.txt');
    expect(charsetFile.existsSync(), isTrue, reason: '${charsetFile.path} 가 없다');

    final charset = charsetFile
        .readAsLinesSync()
        .where((line) => !line.startsWith('#'))
        .join()
        .runes
        .toSet();
    expect(charset, isNotEmpty);

    final missing = OrderRevealPage.jokeLine.runes
        .where((rune) => !charset.contains(rune))
        .map(String.fromCharCode)
        .toSet();

    expect(
      missing,
      isEmpty,
      reason: '서브셋 폰트에 없는 글자: ${missing.join()} — charset.txt에 더하고 '
          'scripts/build_joke_font.sh 로 폰트를 다시 만들 것',
    );
  });

  test('서브셋 폰트 에셋이 커밋돼 있고 원본 통짜가 아니다', () {
    final font = File(doguJokeFontAssets.single);
    expect(font.existsSync(), isTrue, reason: '${font.path} 가 없다');
    // 원본 Gaegu-Bold는 약 2.9MB — 실수로 통짜를 커밋하면 여기서 걸린다.
    expect(
      font.lengthSync(),
      lessThan(400 * 1024),
      reason: '서브셋이 아니라 원본을 커밋한 것으로 보인다 (scripts/build_joke_font.sh)',
    );
  });
}
