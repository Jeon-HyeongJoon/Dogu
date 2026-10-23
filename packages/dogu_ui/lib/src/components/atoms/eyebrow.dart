import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class Eyebrow extends StatelessWidget {
  const Eyebrow({required this.index, required this.text, this.inverted = false, super.key});
  final String index;
  final String text;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: monoStyle.copyWith(fontSize: 10, color: inverted ? AppColors.ink4 : AppColors.ink3, letterSpacing: 1.8, fontWeight: FontWeight.w600),
          children: [
            TextSpan(text: '[ $index ] ', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}
