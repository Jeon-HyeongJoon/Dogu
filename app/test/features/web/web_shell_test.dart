import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/assets.dart';

// web/ 껍데기(index.html·manifest) 가드. Flutter가 첫 화면을 그리기 전에 사용자가 보는 것은 이것뿐이다 —
// 탭 제목·아이콘이 Flutter 기본값(dogu_mobile_shop, 파란 F 로고)으로 돌아가거나 로딩 화면이 빠지면 여기서 잡는다.
void main() {
  final html = File('web/index.html').readAsStringSync();
  final manifest = jsonDecode(File('web/manifest.json').readAsStringSync()) as Map<String, dynamic>;

  test('index.html shows a splash right away and removes it on the first Flutter frame', () {
    expect(html, contains('id="splash"'));
    expect(html, contains("addEventListener('flutter-first-frame'"));
    expect(html, contains('splash.remove()'));
    // 로딩 화면의 로고는 앱이 번들하는 그 파일이다.
    final logo = RegExp(r'<img src="assets/([^"]+)"').firstMatch(html)!.group(1)!;
    final file = assetFile(logo);
    expect(File(file).existsSync(), isTrue, reason: '$file 가 없다');
    // 로딩 화면이 flutter_bootstrap.js보다 먼저 있어야 바로 그려진다.
    expect(html.indexOf('id="splash"'), lessThan(html.indexOf('flutter_bootstrap.js')));
  });

  test('app code works in the WebAssembly build — no dart:html', () {
    // 배포는 --wasm(dart2wasm + dart2js)이다. dart2wasm엔 dart:html이 없어서, 웹 판별을
    // dart.library.html로 하면 WebAssembly 빌드에선 웹이 아닌 쪽 코드가 들어간다(실제로 경로 주소가
    // 무시되고 늘 홈이 열렸다). 웹 판별은 dart.library.js_interop, DOM 접근은 package:web을 쓴다.
    final sources = [for (final dir in ['lib', '../packages/dogu_ui/lib']) ...Directory(dir).listSync(recursive: true)];
    for (final file in sources.whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final code = file.readAsLinesSync().where((line) => !line.trimLeft().startsWith('//')).join('\n');
      expect(code, isNot(contains('dart.library.html')), reason: file.path);
      expect(code, isNot(contains("'dart:html'")), reason: file.path);
    }
  });

  test('tab title, description and manifest use the brand, not Flutter defaults', () {
    expect(html, contains('<title>욕망의 장바구니</title>'));
    expect(html, isNot(contains('dogu_mobile_shop')));
    expect(html, isNot(contains('A new Flutter project.')));
    expect(manifest['name'], '욕망의 장바구니');
    expect(manifest['description'], isNot('A new Flutter project.'));
    // 바탕색은 앱 테마와 같아야 한다 — 다르면 설치 앱 실행·로딩 화면에서 다른 색이 번쩍인다.
    // (예전엔 Flutter 기본 파랑 #0175C2였다.)
    final bg = '#${(AppColors.bg.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';
    expect(manifest['background_color'], bg);
    expect(manifest['theme_color'], bg);
    expect(html, contains('<meta name="theme-color" content="$bg">'));
    expect(html, contains('html, body { margin: 0; background: $bg; }'));
    for (final icon in (manifest['icons'] as List).cast<Map<String, dynamic>>()) {
      expect(File('web/${icon['src']}').existsSync(), isTrue, reason: '${icon['src']} 가 없다');
    }
  });
}
