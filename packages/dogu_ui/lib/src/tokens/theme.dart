import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// 앱 테마 — Gilded: 항아리 초록 바탕, 금 강조, 크림 글씨, 본문체(Dogu Sans). 앱과 카탈로그가 같은 테마로 그린다.
/// 머티리얼 기본 위젯(진행 표시·글자 선택·앱바)이 시드에서 색을 뽑지 않도록 색 구성을 직접 정한다.
ThemeData buildDoguTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.invert,
      secondary: AppColors.accentBright,
      onSecondary: AppColors.invert,
      error: AppColors.alert,
      onError: AppColors.ink,
      surface: AppColors.bg,
      onSurface: AppColors.ink,
    ),
    fontFamily: doguFontFamily,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.ink, height: 1.5),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: Color(0x55c9a24e),
      selectionHandleColor: AppColors.accent,
    ),
  );
}
