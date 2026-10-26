import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class SkeletonProductCard extends StatelessWidget {
  const SkeletonProductCard({this.dark = false, super.key});
  /// 어두운 섹션(오늘의 딜) 위에 놓일 때.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fill = dark ? AppColors.ink2 : AppColors.bgAlt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(aspectRatio: 1, child: ColoredBox(color: fill)),
        Container(height: 1, color: dark ? AppColors.heroLine : AppColors.line),
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
