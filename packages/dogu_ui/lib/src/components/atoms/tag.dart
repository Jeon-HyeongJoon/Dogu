import 'package:flutter/material.dart';

import '../atoms/mono_text.dart';
import '../../tokens/tokens.dart';

/// 작은 라벨 상자 — 브랜드·결제수단·광고 eyebrow.
/// 글이 '● '로 시작하면(예: '● 2026 SPRING DROP') 점을 빨간 '지금' 표시로 그린다.
class Tag extends StatelessWidget {
  const Tag({required this.text, this.compact = false, this.dark = false, super.key});
  final String text;
  final bool compact;
  /// 광고(히어로) 위 — 금 테두리에 밝은 금 글씨.
  final bool dark;

  static const _liveMark = '● ';

  @override
  Widget build(BuildContext context) {
    final live = text.startsWith(_liveMark);
    final color = dark ? AppColors.accentBright : (compact ? AppColors.ink3 : AppColors.ink);
    final label = MonoText(live ? text.substring(_liveMark.length) : text, size: compact ? 9.5 : 10, weight: FontWeight.w600, color: color);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 7, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(border: Border.all(color: dark ? AppColors.heroChip : AppColors.line, width: AppStroke.hair)),
      child: live
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.alert, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                label,
              ],
            )
          : label,
    );
  }
}
