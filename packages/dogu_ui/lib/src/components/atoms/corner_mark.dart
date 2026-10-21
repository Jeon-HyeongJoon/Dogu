import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class CornerMark extends StatelessWidget {
  const CornerMark({required this.alignment, super.key});
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    return Align(
      alignment: alignment,
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppColors.accent) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppColors.accent) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppColors.accent) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppColors.accent) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
