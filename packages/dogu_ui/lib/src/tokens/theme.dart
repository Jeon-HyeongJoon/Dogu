import 'package:flutter/gestures.dart';
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

/// 가로 목록의 스크롤 동작 — 마우스로도 끌어 넘긴다. 웹 기본값은 마우스 끌기를 막아, 세로 휠만 있는 마우스로는
/// 화면 밖 칸(넓은 화면의 10번째 딜 카드, 좁은 창의 SALE 등)에 닿을 수 없었다.
/// 세로 목록엔 쓰지 않는다 — 마우스 끌기는 1px만 움직여도 시작돼, 페이지 전체에 켜면 클릭이 끌기로 바뀌기 쉽다.
class DoguDragScrollBehavior extends MaterialScrollBehavior {
  const DoguDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {...super.dragDevices, PointerDeviceKind.mouse};
}
