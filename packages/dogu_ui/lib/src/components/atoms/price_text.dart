import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// 가격·금액 — 세리프(Dogu Serif) 라이닝 숫자. 한글('무료' 등)이 섞이면 본문체로 폴백한다.
class PriceText extends StatelessWidget {
  const PriceText(this.text, {this.size = 14, this.color = AppColors.ink, this.align, super.key});
  final String text;
  final double size;
  final Color color;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    return Text(text, textAlign: align, style: serifStyle.copyWith(fontSize: size, color: color, height: 1.2));
  }
}
