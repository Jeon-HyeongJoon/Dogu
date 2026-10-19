import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_ui/dogu_ui.dart';

import '../support.dart';

void main() {
  testWidgets('DoguBrandLockup shows the logo and the brand name in the title face', (tester) async {
    await tester.pumpWidget(host(const DoguBrandLockup()));
    await tester.pump();
    expect(find.byType(DoguLogoMark), findsOneWidget);
    final title = tester.widget<Text>(find.text(DoguBrandLockup.brandName));
    expect(title.style?.fontFamily, doguTitleFontFamily);
  });

  testWidgets('DoguLogoMark loads the logo the design system ships', (tester) async {
    await tester.pumpWidget(host(const DoguLogoMark(size: 48)));
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, DoguLogoMark.assetKey);
    // 앱 번들에서의 키 그대로 패키지 에셋을 찾는다(없으면 로드가 실패한다).
    final bytes = await tester.runAsync(() => PackageAssetBundle().load(DoguLogoMark.assetKey));
    expect(bytes!.lengthInBytes, greaterThan(0));
  });

  testWidgets('DoguBrandMark paints at the requested size', (tester) async {
    await tester.pumpWidget(host(const DoguBrandMark(size: 40)));
    expect(tester.getSize(find.byType(DoguBrandMark)), const Size(40, 40));
  });
}
