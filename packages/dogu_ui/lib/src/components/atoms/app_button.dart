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
    // 주 버튼은 금 면에 초록 글씨, 보조 버튼은 금 테두리에 밝은 금 글씨 — 페이지·광고 바탕 어디서나 같다.
    // (onDark는 광고 위 주 버튼의 글씨를 키우는 데만 쓴다.)
    bgColor = primary ? AppColors.accent : Colors.transparent;
    borderColor = AppColors.accent;
    textColor = primary ? AppColors.invert : AppColors.accentBright;
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
            border: Border.all(color: borderColor, width: AppStroke.control),
          ),
          child: Text(text, style: TextStyle(fontSize: (large ? 13.5 : 13) + (onDark && primary ? 2 : 0), fontWeight: FontWeight.w700, letterSpacing: 0.6, color: textColor)),
        ),
      ),
    );
  }
}
