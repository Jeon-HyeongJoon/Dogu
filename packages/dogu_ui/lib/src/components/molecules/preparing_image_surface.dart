import 'package:flutter/material.dart';

import '../atoms/mono_text.dart';
import '../../tokens/tokens.dart';

// 통일된 "준비 이미지" placeholder — 모든 상품 이미지 로딩 전/실패 시 동일하게 표시
class PreparingImageSurface extends StatelessWidget {
  const PreparingImageSurface({this.child, this.dark = false, super.key});

  final Widget? child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    // 삽입 이미지(로고 워터마크) 없이 회색 스켈레톤 + 은은한 sheen으로 '로딩 중' 느낌만 준다.
    // 깊은 초록 우물에 가운데가 금빛으로 살짝 밝다(시안의 진열 액자).
    final base = dark ? AppColors.deep : AppColors.bgAlt;
    final sheen = dark ? AppColors.potDeep : const Color(0xff1d4430);
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 0.75,
          colors: [sheen, base],
        ),
        border: Border.all(color: dark ? AppColors.deepLine : AppColors.line, width: AppStroke.hair),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: MonoText('이미지 준비 중', size: 9.5, color: AppColors.ink4),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
