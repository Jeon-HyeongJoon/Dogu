@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dogu_mobile_shop/main.dart';

// v2(유희왕 마법 카드 테마) 화면을 이미지로 스냅샷하는 golden 테스트.
// 크로스플랫폼 렌더 차이가 있어 CI의 flutter test는 `--exclude-tags golden`으로 제외한다.
// 이미지 (재)생성:
//   flutter test --update-goldens --tags golden
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFont('Pretendard', const [
      'assets/fonts/pretendard/Pretendard-Regular.otf',
      'assets/fonts/pretendard/Pretendard-SemiBold.otf',
      'assets/fonts/pretendard/Pretendard-Bold.otf',
      'assets/fonts/pretendard/Pretendard-ExtraBold.otf',
    ]);
    await _loadFont('NanumSquareRound', const [
      'assets/fonts/nanumsquareround/NanumSquareRoundL.ttf',
      'assets/fonts/nanumsquareround/NanumSquareRoundR.ttf',
      'assets/fonts/nanumsquareround/NanumSquareRoundB.ttf',
      'assets/fonts/nanumsquareround/NanumSquareRoundEB.ttf',
    ]);
  });

  testWidgets('v2 home renders on a mobile viewport', (tester) async {
    await _pumpV2Home(tester, const Size(390, 844));
    await expectLater(
      find.byType(V2HomePage),
      matchesGoldenFile('goldens/v2_home_mobile.png'),
    );
  });

  testWidgets('v2 home renders on a tablet viewport', (tester) async {
    await _pumpV2Home(tester, const Size(834, 1112));
    await expectLater(
      find.byType(V2HomePage),
      matchesGoldenFile('goldens/v2_home_tablet.png'),
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

Future<void> _pumpV2Home(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  // initialize()를 부르지 않아 store 필드는 seed 파생 fallback(결정적 데이터)로 유지된다.
  final store = AppStore();
  await tester.pumpWidget(
    AppStateScope(
      store: store,
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: V2HomePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
