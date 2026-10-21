import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class SkeletonProductCard extends StatelessWidget {
  const SkeletonProductCard({this.dark = false, super.key});
  /// 어두운 섹션(오늘의 딜) 위에 놓일 때.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fill = dark ? AppColors.bgSoft : AppColors.bgAlt; // 깊은 띠 위에선 한 단 밝게, 페이지 위에선 한 단 깊게
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(aspectRatio: 1, child: ColoredBox(color: fill)),
        Container(height: AppStroke.hair, color: dark ? AppColors.deepLine : AppColors.line),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 9, width: 56, color: fill, margin: const EdgeInsets.only(bottom: 6)),
              Container(height: 11, color: fill, margin: const EdgeInsets.only(bottom: 4)),
              Container(height: 11, width: 90, color: fill, margin: const EdgeInsets.only(bottom: 12)),
              Container(height: 13, width: 72, color: fill),
            ],
          ),
        ),
      ],
    );
  }
}
