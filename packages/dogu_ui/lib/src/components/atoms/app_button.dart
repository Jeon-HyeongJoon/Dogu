import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class AppButton extends StatelessWidget {
  const AppButton({required this.text, this.primary = false, this.large = false, this.onDark = false, this.onTap, super.key});
  final String text;
  final bool primary;
  final bool large;
  final bool onDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    if (onDark) {
      // 검은 광고 배경 위에서 테마색(accent)을 또렷하게 보여주는 버튼
      if (primary) {
        bgColor = AppColors.accentDeep;
        borderColor = AppColors.accentDeep;
        textColor = Colors.white;
      } else {
        // 노트 버튼: 밝은 회색 배경 + 검은 글씨 + 검은 테두리
        bgColor = AppColors.heroChip;
        borderColor = AppColors.ink;
        textColor = AppColors.ink;
      }
    } else {
      bgColor = primary ? AppColors.accent : AppColors.bg;
      borderColor = primary ? AppColors.accent : AppColors.line;
      textColor = primary ? AppColors.invert : AppColors.ink;
    }
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: large ? 48 : 42,
          padding: EdgeInsets.symmetric(horizontal: large ? 22 : 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
          ),
          child: Text(text, style: TextStyle(fontSize: (large ? 13.5 : 13) + (onDark && primary ? 2 : 0), fontWeight: FontWeight.w600, color: textColor)),
        ),
      ),
    );
  }
}
