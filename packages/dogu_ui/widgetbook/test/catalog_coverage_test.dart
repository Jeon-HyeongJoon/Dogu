import 'dart:io';

import 'package:dogu_ui_catalog/use_cases.dart';
import 'package:flutter_test/flutter_test.dart';

// 디자인 시스템의 모든 컴포넌트가 카탈로그(=컴포넌트 골든)에 사례를 하나 이상 갖는다.
// 새 컴포넌트를 만들고 use_cases.dart에 사례를 더하지 않으면 여기서 실패한다.
void main() {
  test('every dogu_ui component has at least one catalog use case', () {
    final components = <String, String>{}; // 이름 → 분류(디렉터리)
    final root = Directory('../lib/src/components');
    for (final file in root.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final group = file.parent.uri.pathSegments.where((s) => s.isNotEmpty).last;
      for (final match in RegExp(r'^class ([A-Z]\w*) extends (StatelessWidget|StatefulWidget)', multiLine: true).allMatches(file.readAsStringSync())) {
        components[match.group(1)!] = group;
      }
    }
    expect(components, isNotEmpty);

    final cataloged = {for (final entry in doguComponentCases) entry.component: entry.group};
    final missing = components.keys.where((name) => !cataloged.containsKey(name)).toList()..sort();
    expect(missing, isEmpty, reason: 'use_cases.dart에 사례가 없는 컴포넌트: ${missing.join(', ')}');

    for (final entry in cataloged.entries) {
      expect(components[entry.key], entry.value, reason: '${entry.key}의 분류가 실제 디렉터리와 다르다');
    }
    for (final entry in doguComponentCases) {
      expect(entry.cases, isNotEmpty, reason: entry.component);
    }
  });
}
