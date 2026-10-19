import 'package:flutter/material.dart';

import '../brand/dogu_logo_mark.dart';
import '../../tokens/tokens.dart';

/// 브랜드 락업 — 로고 마크 + 손글씨 타이틀. 상단 헤더와 푸터가 이 하나를 공유한다.
/// 마크는 36px 박스 중앙에 앉혀 2px 위로, 타이틀은 4px 아래로 — 헤더에서 정밀 튜닝된
/// 정렬을 그대로 옮긴 값이라 임의로 바꾸지 말 것(좁은 뷰포트 오버플로 회귀).
class DoguBrandLockup extends StatelessWidget {
  const DoguBrandLockup({super.key});

  /// 손글씨체로 찍는 브랜드 타이틀. 이 문자열의 글자는 서브셋 폰트
  /// (app/assets/fonts/doguhand/charset.txt)에 모두 들어 있어야 한다 — font_charset_test가 검증.
  static const brandName = '욕망의 장바구니';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: const Offset(0, -2),
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Center(child: DoguLogoMark(size: 30)),
          ),
        ),
        const SizedBox(width: 6),
        Transform.translate(
          offset: const Offset(0, 4),
          child: const Text(
            brandName,
            style: TextStyle(
              fontFamily: doguTitleFontFamily,
              fontFamilyFallback: [doguFontFamily],
              color: AppColors.accent,
              fontSize: 24,
              fontWeight: FontWeight.w100,
              height: 1.0,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
