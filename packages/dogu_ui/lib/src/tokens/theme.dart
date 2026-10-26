import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// 앱 테마 — 흰 바탕, 초록 강조, 본문체(Dogu Sans). 앱과 카탈로그가 같은 테마로 그린다.
ThemeData buildDoguTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      surface: AppColors.bg,
    ),
    fontFamily: doguFontFamily,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.ink, height: 1.5),
    ),
  );
}
