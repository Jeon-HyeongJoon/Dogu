import 'package:flutter/material.dart';

import '../atoms/mono_text.dart';
import '../../tokens/tokens.dart';

class Tag extends StatelessWidget {
  const Tag({required this.text, this.compact = false, this.dark = false, super.key});
  final String text;
  final bool compact;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 7, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: dark ? AppColors.heroChip : null,
        border: Border.all(color: dark ? AppColors.heroChip : AppColors.line),
      ),
      child: MonoText(text, size: compact ? 9.5 : 10, weight: FontWeight.w600, color: dark ? AppColors.ink : (compact ? AppColors.ink3 : AppColors.ink)),
    );
  }
}
