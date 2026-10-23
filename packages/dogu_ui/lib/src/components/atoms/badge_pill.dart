import 'package:flutter/material.dart';

import '../atoms/mono_text.dart';
import '../../tokens/tokens.dart';

class BadgePill extends StatelessWidget {
  const BadgePill({required this.text, required this.color, this.ink, this.bordered = false, this.compact = false, super.key});
  final String text;
  final Color color;
  /// 글씨 색 — 없으면 바탕 밝기로 고른다(금·크림 면엔 초록, 빨강·초록 면엔 크림).
  final Color? ink;
  final bool bordered;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(color: color, border: bordered ? Border.all(color: AppColors.accent, width: AppStroke.hair) : null),
      child: MonoText(text, size: compact ? 9 : 9.5, color: ink ?? (color.computeLuminance() > 0.3 ? AppColors.invert : AppColors.ink), weight: FontWeight.w700),
    );
  }
}
