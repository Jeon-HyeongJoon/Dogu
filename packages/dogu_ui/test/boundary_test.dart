import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// 디자인 시스템은 앱 데이터(스토어·모델·라우팅·저장소)를 모른다. 앱 패키지를 import할 수 없는 건 컴파일러가
// 막고, 여기서는 의존성이 flutter 하나뿐인지 — 라우터·HTTP·저장소 같은 앱 쪽 패키지가 들어오지 않는지 — 를 지킨다.
void main() {
  test('dogu_ui depends on flutter only', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final start = pubspec.indexOf('dependencies:');
    final deps = pubspec
        .skip(start + 1)
        .takeWhile((line) => line.isEmpty || line.startsWith(' '))
        .where((line) => RegExp(r'^  [a-z_]+:').hasMatch(line))
        .map((line) => line.trim().split(':').first)
        .toList();
    expect(deps, ['flutter']);
  });

  test('no component reaches into the app', () {
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final code = file.readAsStringSync();
      expect(code, isNot(contains('package:dogu_mobile_shop')), reason: file.path);
      expect(code, isNot(matches(RegExp(r'\b(AppStateScope|AppStore|ProductItem|CategoryItem|GoRouter)\b'))), reason: file.path);
    }
  });
}
