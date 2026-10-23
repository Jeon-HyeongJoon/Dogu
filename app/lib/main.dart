import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dogu_ui/dogu_ui.dart';

// 웹 판별은 dart.library.js_interop — dart.library.html은 WebAssembly 빌드(dart2wasm)에 없어서
// 경로 주소(/category)가 무시되고 늘 홈이 열렸다.
import 'src/url_strategy_stub.dart'
    if (dart.library.js_interop) 'src/url_strategy_web.dart';


// 디자인 시스템(토큰 + 범용 컴포넌트)은 packages/dogu_ui — 앱 데이터를 모른다. 테스트가 main.dart만
// import해도 쓰도록 다시 내보낸다.
export 'package:dogu_ui/dogu_ui.dart';

part 'src/core.dart';
part 'src/data_state.dart';
part 'src/home_widgets.dart';
part 'src/pages.dart';
part 'src/blocks.dart';
part 'src/misc_widgets.dart';
part 'src/order_flow.dart';
part 'src/bundled_seed.g.dart';

// 폰트 파일(서브셋)과 에셋 목록(doguFontAssets 등)은 디자인 시스템(packages/dogu_ui)이 담는다.
// 앱은 부트스트랩에서 그 키로 런타임 등록(FontLoader)만 한다 — 아래 loadDoguEssentialFont/loadDoguFonts.

typedef AppRunner = void Function(Widget app);

void main() => bootstrap();

/// 첫 페인트에서 한글이 ⊠(두부) 박스로 보이지 않도록, 한글 글리프가 있는 필수 본문체
/// (Dogu Sans Regular, 약 350KB)만 첫 페인트 전에 먼저 로드한다.
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
  // 첫 페인트 전에 함께 로드: 본문 한글(Dogu Sans) + 브랜드 타이틀(Dogu Hand Thin) + 가격 세리프(Dogu Serif).
  // 모두 등록된 뒤 첫 프레임을 그리므로 본문·타이틀에 두부(⊠)가, 가격에 서체 바뀜이 없다.
  await Future.wait([
    _loadFontFamily(doguFontFamily, doguEssentialFontAssets),
    _loadFontFamily(doguTitleFontFamily, doguTitleEssentialFontAssets),
    _loadFontFamily(doguSerifFontFamily, doguSerifFontAssets),
  ]);
}

/// 첫 페인트 뒤에 받는 폰트 — 주문 결과 화면에서만 쓰는 농담 서체뿐이다.
/// (본문체는 이미 굵기 4개를 첫 페인트 전에 등록했다 — 예전엔 Regular를 여기서 한 번 더 받았다.)
Future<void> loadDoguFonts() async {
  await _loadFontFamily(doguJokeFontFamily, doguJokeFontAssets);
}

Future<void> _loadFontFamily(String family, List<String> assets) {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  return loader.load();
}

