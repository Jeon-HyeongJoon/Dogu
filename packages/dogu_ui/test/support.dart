// 디자인 시스템 컴포넌트 테스트 공용 준비.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dogu_ui/dogu_ui.dart';

/// 컴포넌트를 앱과 같은 테마(본문체·색)로 띄운다.
Widget host(Widget child) {
  return DefaultAssetBundle(
    bundle: PackageAssetBundle(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: AppColors.bg, fontFamily: doguFontFamily),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

/// 앱에 실리면 패키지 에셋 키는 'packages/dogu_ui/…'지만, 패키지 자체 테스트에선 루트 키('assets/…')로
/// 번들된다. 컴포넌트가 앱에서 쓰는 키 그대로 찾을 수 있게 앞부분을 떼어 읽는다.
class PackageAssetBundle extends CachingAssetBundle {
  static const _prefix = 'packages/dogu_ui/';

  @override
  Future<ByteData> load(String key) => rootBundle.load(key.startsWith(_prefix) ? key.substring(_prefix.length) : key);
}
