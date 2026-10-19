import 'package:flutter/material.dart';

import '../brand/dogu_brand_mark.dart';

/// 브랜드 로고 마크 — design/assets/logo-square.png의 파생본(항아리 엠블럼)을
/// 원형으로 잘라 얹는다. 상단 헤더의 메인 로고가 이 위젯이다.
/// 이미지가 아직 디코딩되지 않은 첫 프레임에는 벡터 마크(DoguBrandMark)로 버틴다.
class DoguLogoMark extends StatelessWidget {
  const DoguLogoMark({this.size = 30, super.key});
  final double size;

  /// 디자인 시스템이 담은 로고 — 앱 번들에서의 키(웹 URL: assets/packages/dogu_ui/assets/logo-square.png).
  static const assetKey = 'packages/dogu_ui/assets/logo-square.png';

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        assetKey,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stack) => DoguBrandMark(size: size),
      ),
    );
  }
}
