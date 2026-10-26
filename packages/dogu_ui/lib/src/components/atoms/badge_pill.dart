import 'package:flutter/material.dart';

import '../atoms/mono_text.dart';
import '../../tokens/tokens.dart';

class BadgePill extends StatelessWidget {
  const BadgePill({required this.text, required this.color, this.ink = Colors.white, this.bordered = false, this.compact = false, super.key});
  final String text;
  final Color color;
  final Color ink;
  final bool bordered;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(color: color, border: bordered ? Border.all(color: AppColors.line) : null),
      child: MonoText(text, size: compact ? 9 : 9.5, color: ink, weight: FontWeight.w700),
    );
  }
}
