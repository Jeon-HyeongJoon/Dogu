import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'src/url_strategy_stub.dart'
    if (dart.library.html) 'src/url_strategy_web.dart';


part 'src/core.dart';
part 'src/data_state.dart';
part 'src/home_widgets.dart';
part 'src/pages.dart';
part 'src/blocks.dart';
part 'src/misc_widgets.dart';
part 'src/bundled_seed.g.dart';
part 'src/v2_theme.dart';
part 'src/v2_home.dart';
part 'src/v2_shell.dart';
part 'src/v2_detail.dart';

const doguFontFamily = 'Pretendard';
const doguFontAssets = <String>[
  'assets/fonts/pretendard/Pretendard-Regular.otf',
  'assets/fonts/pretendard/Pretendard-SemiBold.otf',
  'assets/fonts/pretendard/Pretendard-Bold.otf',
  'assets/fonts/pretendard/Pretendard-ExtraBold.otf',
];

// 첫 페인트 전에 먼저 등록할 필수 폰트 — 한글 글리프가 포함된 기본 본문체(Pretendard Regular).
// 이게 없으면 첫 프레임에서 한글이 fallback(한글 없음) 폰트로 그려져 ⊠(두부) 박스가 보인다.
const doguEssentialFontAssets = <String>[
  'assets/fonts/pretendard/Pretendard-Regular.otf',
];

// 메인 광고(히어로) 헤드라인/타이틀 전용 — 굴림 느낌의 둥근 고딕
// Pretendard와 동일하게 assets: + 런타임 FontLoader로 등록한다.
// (FontLoader는 각 파일의 내장 굵기를 인식해 굵기 매칭이 정상 동작 — 웹 CanvasKit에서 FontManifest 다중 굵기 매칭이 어긋나는 문제 회피)
const doguHeroFontFamily = 'NanumSquareRound';
const doguHeroFontAssets = <String>[
  'assets/fonts/nanumsquareround/NanumSquareRoundL.ttf',
  'assets/fonts/nanumsquareround/NanumSquareRoundR.ttf',
  'assets/fonts/nanumsquareround/NanumSquareRoundB.ttf',
  'assets/fonts/nanumsquareround/NanumSquareRoundEB.ttf',
];

// 상단 브랜드 타이틀('욕망의 장바구니') 전용 손글씨체 HSBombaram(봄바람) — 가벼운 Thin 굵기.
const doguTitleFontFamily = 'HSBombaram';
// 타이틀은 이 손글씨체가 primary라, 미등록 상태로 첫 페인트되면 CanvasKit이 폴백 대신
// 두부(⊠)를 그린다. 그래서 타이틀 굵기(Thin)를 필수 폰트와 함께 첫 페인트 전에 로드한다.
const doguTitleEssentialFontAssets = <String>[
  'assets/fonts/hsbombaram/HSBombaram-Thin.otf',
];

typedef AppRunner = void Function(Widget app);

void main() => bootstrap();

/// 첫 페인트에서 한글이 ⊠(두부) 박스로 보이지 않도록, 한글 글리프가 있는 필수 본문체
/// (Pretendard Regular, 약 1.5MB)만 첫 페인트 전에 먼저 로드한다.
/// 나머지 굵기·둥근 헤더체는 첫 프레임 이후 비차단 로드해 첫 페인트 지연을 최소화한다.
/// 로드된 폰트가 등록되면 system fonts change 알림으로 텍스트 레이아웃이 재계산된다.
Future<void> bootstrap({
  AppRunner runner = runApp,
  Future<void> Function()? loadFonts,
  Future<void> Function()? loadEssentialFont,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  // 한글 두부 박스 방지: 필수 폰트는 첫 페인트 전에 등록(실패해도 fallback으로 계속)
  await (loadEssentialFont ?? loadDoguEssentialFont)().catchError(_onFontLoadError);
  runner(const DoguApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited((loadFonts ?? loadDoguFonts)().catchError(_onFontLoadError));
  });
}

void _onFontLoadError(Object error, StackTrace stack) {
  // release에선 fallback 폰트로 조용히 진행, debug/profile에선 진단만 남긴다.
  if (kDebugMode || kProfileMode) {
    debugPrint('폰트 로드 실패(폴백 폰트로 계속): $error');
  }
}

Future<void> loadDoguEssentialFont() async {
  // 첫 페인트 전에 함께 로드: 본문 한글(Pretendard Regular) + 브랜드 타이틀(HSBombaram Regular).
  // 둘 다 등록된 뒤 첫 프레임을 그리므로 본문·타이틀 어디에도 두부(⊠) 깜빡임이 없다.
  await Future.wait([
    _loadFontFamily(doguFontFamily, doguEssentialFontAssets),
    _loadFontFamily(doguTitleFontFamily, doguTitleEssentialFontAssets),
  ]);
}

Future<void> loadDoguFonts() async {
  await Future.wait([
    _loadFontFamily(doguFontFamily, doguFontAssets),
    _loadFontFamily(doguHeroFontFamily, doguHeroFontAssets),
  ]);
}

Future<void> _loadFontFamily(String family, List<String> assets) {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  return loader.load();
}

