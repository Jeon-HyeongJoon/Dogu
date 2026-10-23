import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// 할인 전 가격 — 가격과 같은 세리프에 취소선.
class StrikeText extends StatelessWidget {
  const StrikeText(this.text, {this.size = 11, super.key});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: serifStyle.copyWith(
        fontSize: size,
        color: AppColors.ink4,
        decoration: TextDecoration.lineThrough,
        decorationColor: AppColors.ink4,
      ),
    );
  }
}
