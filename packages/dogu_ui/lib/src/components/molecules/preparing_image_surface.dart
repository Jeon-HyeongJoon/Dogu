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
    final base = dark ? const Color(0xff161616) : AppColors.bgAlt;
    final sheen = dark ? const Color(0xff202020) : const Color(0xfff1f1f0);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, sheen, base],
        ),
        border: Border.all(color: dark ? const Color(0xff2a2a2a) : AppColors.line),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: MonoText('이미지 준비 중', size: 9.5, color: dark ? const Color(0xff6a6a6a) : AppColors.ink4),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
