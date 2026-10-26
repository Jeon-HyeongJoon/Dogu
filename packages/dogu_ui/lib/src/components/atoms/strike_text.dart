import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class StrikeText extends StatelessWidget {
  const StrikeText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: monoStyle.copyWith(
        fontSize: 10.5,
        color: AppColors.ink4,
        decoration: TextDecoration.lineThrough,
        decorationColor: AppColors.ink4,
      ),
    );
  }
}
