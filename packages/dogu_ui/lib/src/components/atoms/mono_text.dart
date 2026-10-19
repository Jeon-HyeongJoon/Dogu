import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class MonoText extends StatelessWidget {
  const MonoText(this.text, {this.size = 12, this.color = AppColors.ink, this.weight = FontWeight.w400, this.align, super.key});
  final String text;
  final double size;
  final Color color;
  final FontWeight weight;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: monoStyle.copyWith(fontSize: size, color: color, fontWeight: weight),
    );
  }
}
