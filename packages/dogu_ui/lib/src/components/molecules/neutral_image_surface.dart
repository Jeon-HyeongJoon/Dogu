import 'package:flutter/material.dart';

import '../brand/dogu_brand_mark.dart';
import '../../tokens/tokens.dart';

class NeutralImageSurface extends StatelessWidget {
  const NeutralImageSurface({this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.line),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Center(
            child: Opacity(
              opacity: 0.14,
              // 워터마크는 단색 — 액센트 도트도 잉크로 눌러 은은하게.
              child: DoguBrandMark(size: 52, bag: AppColors.ink3, dot: AppColors.ink3),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
