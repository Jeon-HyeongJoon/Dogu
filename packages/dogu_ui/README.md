# dogu_ui

Dogu 디자인 시스템 — 디자인 토큰과 범용 컴포넌트. 앱 데이터(스토어·모델·라우팅)를 모른다.

```
lib/
  dogu_ui.dart                 공개 API(전부 여기서 export)
  src/tokens/                  colors · spacing · typography(글꼴 패밀리 이름, monoStyle)
  src/components/
    atoms/                     MonoText, StrikeText, Eyebrow, Tag, BadgePill, AppButton, LoadingDots,
                               SkeletonProductCard, SmallChip, NavLabel, IconBox, CornerMark
    molecules/                 SectionHead, SectionBorder, SoftDividerBlock, EmptyStateBlock, SummaryLine,
                               QtyBox, RecentSearchTag, StatGrid, QuickFilterRow, CountdownTimer,
                               PreparingImageSurface, NeutralImageSurface
    brand/                     DoguBrandMark, DoguLogoMark, DoguBrandLockup
assets/logo-square.png         브랜드 로고(정본 design/assets, 파생은 scripts/sync_logo.sh)
```

- 컴포넌트는 파일 하나에 하나. 데이터는 생성자 인자로만 받는다(앱 스토어를 읽지 않는다)
- 의존성은 `flutter` 하나 — `test/boundary_test.dart`가 지킨다
- 글꼴 파일은 앱이 담고 런타임에 이 패키지의 패밀리 이름으로 등록한다
- 테스트: `flutter test` (컴포넌트별 동작 + 경계)
