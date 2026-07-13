import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dogu_mobile_shop/main.dart';

// v1 ↔ v2 인앱 스위칭 검증.
// (v1 햄버거 메뉴의 'V2 새 디자인' → /v2, v2 헤더의 'V1' 칩 → /)
void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    await tester.pumpWidget(DoguApp(store: store, initializeStore: false));
    await tester.pump();
  }

  Future<void> goToV2(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('V2 새 디자인'));
    await tester.pumpAndSettle();
  }

  testWidgets("v1 menu 'V2 새 디자인' switches to the v2 shell", (tester) async {
    await pumpApp(tester);
    expect(find.byType(V2Shell), findsNothing);

    await goToV2(tester);

    expect(find.byType(V2Shell), findsOneWidget);
  });

  testWidgets("v2 header 'V1' chip returns to the v1 shell", (tester) async {
    await pumpApp(tester);
    await goToV2(tester);
    expect(find.byType(V2Shell), findsOneWidget);

    await tester.tap(find.text('V1'));
    await tester.pumpAndSettle();

    expect(find.byType(V2Shell), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });
}
