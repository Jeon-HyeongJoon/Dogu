import 'package:flutter/painting.dart';

// 글꼴 — 패밀리 이름과 폰트 파일(서브셋). 파일은 이 패키지의 assets/fonts/에 있고(출처·라이선스는 각
// 디렉터리의 NOTICE.md·LICENSE), 앱이 부트스트랩에서 아래 에셋 키로 런타임 등록(FontLoader)한다.
// 재생성: scripts/build_fonts.sh

// 본문체 — Pretendard 서브셋(assets/fonts/dogusans). 원본은 한글 11,172자를 다 담아
// 굵기당 1.5MB라, 앱이 실제로 그리는 글자만 남겨 굵기당 약 350KB로 줄였다.
// OFL 예약 폰트 이름 때문에 서브셋은 원본 이름을 쓸 수 없어 'Dogu Sans'로 담는다(NOTICE.md).
const doguFontFamily = 'DoguSans';

// 상단 브랜드 타이틀('욕망의 장바구니') 전용 손글씨체 — HSBombaram 3.0 서브셋('Dogu Hand').
const doguTitleFontFamily = 'DoguHand';

// 주문 결과 화면의 농담 한 줄 전용 손글씨체 — Gaegu Bold 서브셋.
const doguJokeFontFamily = 'Gaegu';

// 가격·숫자·영문 디스플레이 세리프 — Playfair Display Bold 서브셋('Dogu Serif', assets/fonts/doguserif).
// 라틴 글자·숫자만 담는다(49KB). 원본에 없는 원화 기호(₩)는 W에 가로줄 두 개를 그어 합성했고,
// 한글이 섞이면 본문체로 폴백한다.
const doguSerifFontFamily = 'DoguSerif';

/// 마이크로 레이블(MonoText) 기본 스타일 — 본문체에 자간을 벌린 금박 라벨.
/// (예전엔 시스템 고정폭이었다. 웹에선 기기마다 다른 고정폭으로, 골든에선 본문체로 그려져 서로 달랐다.)
const monoStyle = TextStyle(
  fontFamily: doguFontFamily,
  letterSpacing: 0.8,
);

/// 가격·큰 숫자(PriceText·StatGrid) — 세리프, 숫자는 높이가 고른 라이닝 숫자.
const serifStyle = TextStyle(
  fontFamily: doguSerifFontFamily,
  fontFamilyFallback: [doguFontFamily],
  fontWeight: FontWeight.w700,
  fontFeatures: [FontFeature.liningFigures()],
);

// 앱 번들에서의 에셋 키(웹 URL: assets/packages/dogu_ui/assets/fonts/…).
const _fonts = 'packages/dogu_ui/assets/fonts';

/// 본문체 굵기 4개(Regular · SemiBold · Bold · ExtraBold).
const doguFontAssets = <String>[
  '$_fonts/dogusans/DoguSans-Regular.otf',
  '$_fonts/dogusans/DoguSans-SemiBold.otf',
  '$_fonts/dogusans/DoguSans-Bold.otf',
  '$_fonts/dogusans/DoguSans-ExtraBold.otf',
];

/// 첫 페인트 전에 등록할 본문체 — 굵기 4개 전부. Regular가 없으면 첫 프레임 한글이 두부(⊠)로 찍히고,
/// 굵은 굵기를 나중에 받으면 굵은 제목이 얇게 그려졌다가 바뀐다(글자 폭이 달라져 줄바꿈도 바뀐다).
/// 앱의 web/index.html이 같은 파일을 처음부터 미리 받는다(preload as=fetch).
const doguEssentialFontAssets = doguFontAssets;

/// 브랜드 타이틀 손글씨체(Thin) — 타이틀은 이 서체가 primary라 미등록 상태로 첫 페인트되면 CanvasKit이
/// 폴백 대신 두부(⊠)를 그린다. 그래서 본문체와 함께 첫 페인트 전에 등록한다.
const doguTitleEssentialFontAssets = <String>['$_fonts/doguhand/DoguHand-Thin.otf'];

/// 가격·숫자 세리프 — 첫 화면 가격이 이 서체라 본문체와 함께 첫 페인트 전에 등록한다(49KB).
const doguSerifFontAssets = <String>['$_fonts/doguserif/DoguSerif-Bold.ttf'];

/// 주문 결과 화면의 농담 한 줄 손글씨체 — 장식용이라 첫 페인트 뒤에 비차단 등록한다.
const doguJokeFontAssets = <String>['$_fonts/gaegu/Gaegu-Bold-subset.ttf'];
