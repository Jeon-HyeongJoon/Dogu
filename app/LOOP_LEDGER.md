# LOOP LEDGER

> TDD_LOOP.md가 구동하는 자율 루프의 진행 원장. 루프는 매 반복 이 파일을 읽고 쓴다.
> 베이스라인: flutter test 71 passed / flutter analyze 0 issues (2026-06-23).

## 진행중
- (없음)

## 방향 전환 (2026-06-23)
- 목표가 "서버리스(백엔드 제거)"에서 **"백엔드 유지 + 초기 로딩 최적화"** 로 변경(사용자 결정).
- 이유: 콘텐츠는 갱신형이라 동적 데이터가 필요하고, 전체 번들은 앱을 무겁게 해 초기 로딩을 늦춤.
- 패턴: instant-paint 하이브리드(번들 경량 seed로 즉시 페인트 → 백엔드로 백그라운드 갱신). s1a/s1b의 번들 로더는 즉시-페인트 계층으로 재활용.

## 진행중
- (없음) — perf2 codex 리뷰는 비동기 pending(완료 시 재알림). 자체 점검상 결함 없음.

## 백로그   ← 우선순위 내림차순 (초기 로딩 성능 > UI > 기능 > 정리)
- [perf] (perf3) 폰트 경량화: OTF→WOFF2/서브셋/사용 weight만 → 다운로드 대폭 감소
- [perf] (perf4) 번들 seed를 전체 카탈로그가 아닌 "shell"로 축소(앱 비대화 방지). 카탈로그 본문은 백엔드
- [payment] (p1) 결제 화면 UI-only 명세 확정 + 선택 0개/빈 장바구니 엣지 테스트
- [ui]   (u1) 빈 상태 화면 일관성: 검색결과 없음 / 찜 없음 / 장바구니 없음
- [ui]   (u2) 로딩 스켈레톤 ↔ 실데이터 전환 깜빡임/레이아웃 점프 점검
- [a11y] (a1) Semantics 라벨 누락 보강(메뉴/탭/상품카드)
- [refactor] (r1) 순수 parser 유틸 분리 검토 — 저우선  ※codex 발견
- [obsolete] (s2/s-img) 서버리스 전제 항목 — 백엔드 유지로 무효화/재평가

## 완료
- (u4) 메인 광고(히어로) 헤드라인 폰트를 굴림 느낌의 둥근 고딕 **NanumSquareRound ExtraBold**로 변경 — 헤드라인 Text에만 `fontFamily` 적용(본문 Pretendard 유지), 폰트는 기존 비차단 로더(loadDoguFonts, post-frame)에 추가해 초기 로딩 영향 최소화. height/letterSpacing/weight를 둥근 폰트에 맞게 미세조정. 폰트는 OFL NanumSquareRound EB(~1MB, fonts-archive에서 다운로드, assets 등록) / 테스트: "hero headline uses the rounded NanumSquareRound font family" / 반복#7 / test 89 green · analyze 0 · 클린 종료 · release 빌드 렌더 검증(둥근 고딕 적용 확인)
- (perf2) instant-paint 하이브리드 — `initialize()`가 번들 seed로 즉시 페인트(`_loadCatalogData`) 후 백엔드 최신 데이터로 갱신(`_refreshFromBackend`, best-effort: 실패 시 seed 유지). 공통 적용 로직을 `_applyCatalog`로 추출(중복 제거), fallback 시맨틱을 "빈 응답 시 현재값 유지"로 개선(부분 백엔드 응답에 seed 보존). `_FakeRepository`에 backendHome/backendProducts 주입 + 원격 메서드 오버라이드 추가 / 테스트: 백엔드 덮어쓰기 + offline seed 유지 2건 / 반복#6 / test 88 green · analyze 0 · 클린 종료 / codex 리뷰 진행 중
- (perf1b) codex perf1 리뷰 4건 환류 — ①[high] pubspec `fonts:` 선언 제거하고 OTF를 `assets:`로 이동(엔진 FontManifest 프리로드/이중 로드 차단, 런타임 FontLoader로만 'Pretendard' 등록) ②[med] 폰트 로드를 `addPostFrameCallback`으로 첫 프레임 이후 시작(테스트도 "동기 미시작"으로 강화) ③[low] 폰트 로드 실패 시 debug/profile에서 `debugPrint` 진단 ④[low] 주석 보정 / test 86 green · analyze 0 · 클린 종료 / ✅렌더 검증: **release 빌드(flutter build web, 8081)** 에서 Pretendard·전체 화면 정상. ※주의: `flutter run` 디버그 서버(8080, DDC 491스크립트)는 헤드리스/재시작 시 흰 화면 오해 유발 → 렌더 검증은 release 빌드로 할 것. 폰트 OTF preload "unused" 경고는 무해(preload는 비차단, FontLoader가 post-frame에 사용)
- (perf1) 폰트 비차단 startup — `main()`이 runApp 전 ~6MB OTF를 await하던 걸 제거. `bootstrap({runner, loadFonts})`가 `runApp(DoguApp())`을 먼저 호출하고 폰트는 `unawaited(...catchError)`로 백그라운드 로드(완료 시 FontLoader가 리페인트). 첫 페인트가 6MB 다운로드에 의존 안 함 / 테스트: "bootstrap paints the app immediately ..." (never-complete Completer 주입) / 반복#4 / test 86 green · analyze 0 · 클린 종료 / ⚠️codex 리뷰 Bash 권한 거부로 미실행 — 자체 점검 후 폰트 로드 실패 무시(catchError) 하드닝 적용
- (codex s1b+u3 환류) 배치 리뷰 4건 반영: ①카테고리 새로고침이 `_repository.fetchProducts` 호출하던 서버리스 잔재 제거 → `selectCategoryBrowse`가 정규화된 키로 로컬 `allProducts` 필터만 수행(원격 `_fetchCategoryProducts` 삭제) ②`LocalSeedSource._seed()` Future memoize(병렬 호출 중복 load/decode 방지) ③seed 손상 시 usingFallback=true 테스트 추가 ④메뉴 항목 선택→닫힘+탭전환 테스트 추가 / test 85 green · analyze 0 · 클린 종료
- (u3) 상단 바 일체형 드롭다운 메뉴 — `_openMenu` 패널을 풀폭(width:double.infinity)·상단 밀착·여백 제거·하단 경계선만으로 전환(상단 바가 아래로 확장되는 느낌), 위→아래 슬라이드 유지. 메뉴 하이라이트 회귀 통과 / 테스트: "menu dropdown is unified with the top bar ..." (getRect로 풀폭·top 밀착 단언) / 반복#3 / test 83 green · analyze 0 · 클린 종료 · 웹 렌더 육안 확인
- (s1b) AppStore를 `LocalSeedSource` 서버리스-우선으로 연결 — `initialize()`가 네트워크 없이 번들 seed로 카탈로그 전체 적재(`_loadRemoteData`→`_loadCatalogData`, repository는 parse 헬퍼/검색/상세에만 사용). 디버그: 신규 테스트를 testWidgets→test로 교정(fake-time 존에서 실제 asset I/O가 완료 못 해 종료 hang)했고 정상 종료 확인 / 테스트: "AppStore.initialize populates full catalog ..." / 반복#2 / test 82 green · analyze 0 · 클린 종료 / codex 리뷰는 u3와 배치 예정
- (s1a) 번들 seed 로더 `LocalSeedSource` 추가 (additive, AppStore 미연결) — 네트워크 없이 assets/seed.json에서 카탈로그/홈/카테고리/트렌딩/추천/뉴스레터 적재, 백엔드 build_home의 ID→상품 해석 재현. codex 리뷰 반영: ①입력 categoryId 정규화(gadget→tech) ②limit 경계 clamp(음수/0 안전) ③fetchHome editorial/brands passthrough / 테스트: "LocalSeedSource ..." 9개 / 반복#1 / test 80 green · analyze 0

## 기각(codex 거짓양성 등)
- "fetchHome가 백엔드 build_home 키(deals/new_arrivals)와 다름" — 소비자는 백엔드가 아니라 Flutter AppStore이고, AppStore는 deal_products/new_products를 직접 파싱(main.dart L799-800)하므로 현 구현이 호환. 서버리스 목표상 백엔드 계약 일치는 불필요.
- "_cache nested 참조 반환으로 외부 변형 가능" — [low] AppStore가 읽기전용으로 소비하므로 현재 위험 없음. 깊은 복사 비용 대비 이득 적어 보류(필요 시 s1b에서 재평가).
- "빈 seed인데 예외 없으면 usingFallback=false가 됨" — [low] 기존 `_loadRemoteData`와 동일한 "응답 성공=non-fallback" 정책. 손상/예외 경로는 테스트로 커버. 정책 변경 불필요.
```
태그: [serverless] [payment] [ui] [a11y] [perf] [refactor] [test]
```
