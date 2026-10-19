import 'package:flutter/painting.dart';

// 글꼴 패밀리 이름. 폰트 파일(서브셋)은 앱이 담고 런타임에 이 이름으로 등록한다 — app/lib/main.dart,
// app/assets/fonts/*/NOTICE.md. 디자인 시스템은 이름만 안다.

// 본문체 — Pretendard 서브셋(assets/fonts/dogusans). 원본은 한글 11,172자를 다 담아
// 굵기당 1.5MB라, 앱이 실제로 그리는 글자만 남겨 굵기당 약 350KB로 줄였다.
// OFL 예약 폰트 이름 때문에 서브셋은 원본 이름을 쓸 수 없어 'Dogu Sans'로 담는다(NOTICE.md).
const doguFontFamily = 'DoguSans';

// 상단 브랜드 타이틀('욕망의 장바구니') 전용 손글씨체 — HSBombaram 3.0 서브셋('Dogu Hand').
const doguTitleFontFamily = 'DoguHand';

// 주문 결과 화면의 농담 한 줄 전용 손글씨체 — Gaegu Bold 서브셋.
const doguJokeFontFamily = 'Gaegu';

/// 고정폭 마이크로 레이블(MonoText) 기본 스타일 — 시스템 고정폭, 한글은 본문체로 폴백.
const monoStyle = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: [doguFontFamily],
  letterSpacing: 0.1,
);
