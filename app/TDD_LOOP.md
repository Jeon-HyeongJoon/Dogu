# 욕망의장바구니 — TDD 루프 엔지니어링 프롬프트

> 이 파일은 자율 개선 루프를 구동하기 위한 **마스터 프롬프트**다.
> `/loop`에 붙여서 돌리거나, 에이전트에게 통째로 먹여 1 iteration씩 반복시킨다.
> 매 반복은 **하나의 개선 항목**만 다룬다(small batch). 절대 한 번에 여러 개를 건드리지 않는다.

---

## 0. 프로젝트 불변 조건 (INVARIANTS — 절대 위반 금지)

이 조건을 깨는 변경은 그 자체로 실패다. 코드를 쓰기 전에 매번 다시 확인한다.

1. **백엔드 유지 + 빠른 초기 로딩(최우선).** 백엔드는 데이터 소스(검색·페이지네이션·콘텐츠 갱신)로 **유지**한다.
   대신 **첫 페인트(first paint)를 어떤 네트워크/대용량 자산 로드에도 의존시키지 않는다.**
   - 패턴 = **instant-paint 하이브리드**: 번들된 경량 seed로 첫 화면을 즉시 그리고(0ms), 백엔드 최신/전체 데이터는 페인트 *후* 백그라운드로 받아 갱신한다.
   - 첫 페인트를 막는 것 금지: 대용량 폰트 동기 로드(현재 ~6MB OTF를 runApp 전에 await), 데이터 페치 대기, 동기 blocking I/O.
   - **번들을 비대하게 만들지 않는다.** 전체 카탈로그를 번들에 굽지 않는다(앱이 무거워질수록 초기 로딩↑). 번들 seed는 "즉시-페인트 shell"로만.
   - `LocalSeedSource`는 제거 대상이 아니라 instant-paint 계층. 단, 백엔드 갱신 경로(`_refreshFromBackend`)를 페인트 후 단계로 둔다.
2. **결제는 UI만.** 결제/체크아웃 화면은 보이되 실제 결제 로직은 작동하지 않는다.
   - "결제하기"는 가짜 주문 요약(local mock) 표시 + 화면 전환까지만. 외부 PG/결제 API 연동 금지.
   - 단, 결제 화면의 UI/상태(선택 항목, 합계, 빈 장바구니 처리 등)는 정확해야 한다.
3. **프론트 기능 + UI + 초기 로딩 성능이 작업 범위.** (백엔드 서버 코드 자체는 건드리지 않되, 앱이 백엔드를 *어떻게/언제* 호출하는지는 최적화 대상.)
4. **품질 게이트 (매 반복 통과 필수):**
   - `flutter test` 전체 green
   - `flutter analyze` 0 issues
   - UI에 영향 있는 변경이면 실제 렌더 1회 확인(아래 §5 스크린샷 하니스)
5. **변경 단위는 작게.** 한 반복 = 테스트 1~소수 + 그에 대응하는 최소 구현 + 리팩터. diff가 비대해지면 쪼갠다.

---

## 1. 루프 개요

```
        ┌─────────────────────────────────────────────────────────┐
        │  매 반복(iteration) = 한 개선 항목                       │
        └─────────────────────────────────────────────────────────┘

  SELECT → RED → GREEN → REFACTOR → VERIFY → REVIEW(codex) → LEDGER → (반복)
   택1     실패   통과     정리      렌더    테스트결과기반    기록
          테스트  최소구현            확인     점검 후 백로그 갱신
```

- **SELECT**: `LOOP_LEDGER.md`의 백로그에서 우선순위 최상위 항목 1개를 고른다.
- **RED**: 그 항목의 기대 동작을 검증하는 **실패하는 테스트**를 먼저 쓴다. 돌려서 "올바른 이유로" 실패하는지 확인.
- **GREEN**: 테스트를 통과시키는 **최소 구현**만 한다. 과한 구현 금지.
- **REFACTOR**: 중복 제거/네이밍/구조 정리. 테스트는 계속 green 유지.
- **VERIFY**: 전체 `flutter test` + `flutter analyze`. UI 변경이면 스크린샷 확인.
- **REVIEW**: codex로 **테스트 결과 + diff 기반** 점검 → 발견 사항을 백로그로 환류.
- **LEDGER**: 완료 항목 기록, 새 백로그 항목 추가, 다음 우선순위 정렬.

---

## 2. 루프 시작 시 1회만 (부트스트랩)

처음 한 번 실행한다. `LOOP_LEDGER.md`가 이미 있으면 건너뛴다.

1. 베이스라인 확보:
   ```bash
   cd /Users/hj/Work/Dogu/app
   flutter test --reporter compact 2>&1 | tail -5
   flutter analyze 2>&1 | tail -5
   ```
2. `LOOP_LEDGER.md`를 생성하고 초기 백로그를 채운다(§4 형식).
   초기 백로그 시드 후보(현재 코드 기준):
   - [serverless] `DoguRepository` 원격 호출 제거 → `assets/seed.json` 번들 로딩으로 전환
   - [serverless] 백엔드 타임아웃 테스트(`checkHealth`/`fetchHome`/`fetchProducts`)를 로컬 로딩 테스트로 대체
   - [payment] 결제 화면 UI-only 동작 명세화 + 빈/선택0 장바구니 엣지 케이스 테스트
   - [ui] 빈 상태(검색 결과 없음/찜 없음/장바구니 없음) 화면 일관성
   - [ui] 로딩 스켈레톤 ↔ 실제 데이터 전환 깜빡임 점검
   - [a11y] Semantics 라벨 누락 위젯 보강(메뉴/탭/카드)

---

## 3. 매 반복 상세 절차

### STEP 1 — SELECT (1개만)
`LOOP_LEDGER.md`의 `## 백로그`에서 최상위 항목 1개를 `## 진행중`으로 옮긴다.
선정 기준 우선순위: **불변 조건 정렬(serverless/payment) > 사용자 영향 큰 UI 버그 > 기능 갭 > 정리.**

### STEP 2 — RED (테스트 먼저)
- `test/widget_test.dart`(또는 기능별 신규 테스트 파일)에 기대 동작을 검증하는 테스트를 추가한다.
- 기존 컨벤션 따른다: `SharedPreferences.setMockInitialValues({})`, fake `http.Client` 주입, `AppStore`/`DoguApp(store:)` 사용.
- 실행해서 **실패**를 확인한다(메시지가 의도한 이유인지 본다):
  ```bash
  flutter test --plain-name "<새 테스트 이름>" 2>&1 | tail -20
  ```

### STEP 3 — GREEN (최소 구현)
- `lib/main.dart` 등에서 테스트를 통과시키는 **최소 변경**만.
- 불변 조건 재확인: 네트워크 호출 추가했나? 결제 로직 실제로 붙였나? → 그렇다면 되돌린다.
- 통과 확인:
  ```bash
  flutter test --plain-name "<새 테스트 이름>" 2>&1 | tail -10
  ```

### STEP 4 — REFACTOR
- 중복/매직넘버/위젯 비대화 정리. 공개 동작은 바꾸지 않는다.

### STEP 5 — VERIFY (게이트)
```bash
flutter test --reporter compact 2>&1 | tail -8     # 전체 green 필수
flutter analyze 2>&1 | tail -8                      # 0 issues 필수
```
UI에 영향 있는 변경이면 추가로 §5 스크린샷 하니스로 렌더 1회 확인하고, 이미지의 변경 의도가 맞는지 본다.

### STEP 6 — REVIEW (codex, 테스트 결과 기반)
아래 §6 스펙대로 codex에 diff + 테스트/analyze 결과를 넘겨 점검을 받는다.
- codex가 낸 지적 중 **유효한 것**만 골라 처리한다(거짓 양성은 LEDGER에 기각 사유와 함께 남긴다).
- 즉시 고칠 작은 것은 이번 반복에서 처리(다시 STEP 5 게이트), 큰 것은 백로그로.

### STEP 7 — LEDGER
- `## 진행중` 항목을 `## 완료`로 옮기고 한 줄 요약 + 추가/변경한 테스트 이름을 적는다.
- codex가 발견한 신규 항목을 `## 백로그`에 추가하고 우선순위 재정렬한다.
- (선택) 커밋: `git add -A && git commit`은 **사용자가 요청했을 때만**.

### 그리고 STEP 1로 돌아간다.

---

## 4. LOOP_LEDGER.md 형식 (원장 — 루프의 기억)

루프는 상태가 없으므로 모든 진행은 이 파일에 적어 **재개 가능**하게 만든다.

```markdown
# LOOP LEDGER

## 진행중
- (id) 제목 — 현재 단계

## 백로그   ← 우선순위 내림차순
- [serverless] (s1) seed.json 번들 로딩 전환
- [ui]         (u3) 검색 빈 상태 화면
...

## 완료
- (id) 제목 — 결과 1줄 / 테스트: <test 이름들> / 반복#N

## 기각(codex 거짓양성 등)
- 지적 내용 — 기각 사유
```

태그: `[serverless] [payment] [ui] [a11y] [perf] [refactor] [test]`

---

## 5. UI 렌더 확인 하니스 (이미 구성됨)

```bash
# 1) 웹 서버 (백그라운드)
cd /Users/hj/Work/Dogu/app
flutter run -d web-server --web-port=8080 --web-hostname=127.0.0.1 &
#   "is being served at http://127.0.0.1:8080" 뜰 때까지 대기

# 2) 스크린샷 (playwright + 시스템 Chrome, 브라우저 다운로드 불필요)
#    scratchpad의 verify.js 패턴 사용: viewport 412x915, 9s 대기 후 캡처,
#    좌상단 (37,33) 클릭으로 메뉴 토글 등 인터랙션 가능.
node verify.js   # 01-home.png / 03-menu-open.png 등 생성 → Read로 육안 확인
```

UI 변경의 "의도대로 보이는지"는 테스트만으로 부족하므로 이 단계로 보강한다.

---

## 6. codex 리뷰 단계 스펙 (REVIEW)

목적: **테스트 결과를 근거로** 변경의 정확성/누락/불변조건 위반을 제3자(codex) 시각으로 점검.

호출(둘 중 하나):
- 권장: `codex:rescue` 스킬에 아래 컨텍스트를 넘겨 리뷰 위임.
- 또는 비대화식 CLI:
  ```bash
  git --no-pager diff > /tmp/loop_diff.patch
  flutter test --reporter compact > /tmp/loop_test.txt 2>&1
  flutter analyze > /tmp/loop_analyze.txt 2>&1
  codex exec "아래 diff와 테스트/analyze 결과를 검토하라. 출력은 한국어로." # diff/결과 첨부
  ```

codex에 주는 리뷰 프롬프트(고정):
```
역할: 시니어 Flutter 리뷰어. 아래는 TDD 루프 한 반복의 산출물이다.
입력: (1) git diff  (2) flutter test 결과  (3) flutter analyze 결과
프로젝트 불변 조건:
  - 서버리스(새 네트워크 호출 금지, 로컬 데이터만)
  - 결제는 UI만(실제 결제 로직 금지)
  - 프론트/UI 범위
점검 항목(우선순위 순):
  1. 불변 조건 위반 여부 (네트워크 추가? 결제 실로직? )
  2. 테스트가 실제로 의도한 동작을 검증하는가, 아니면 구현을 그대로 베꼈는가(tautology)?
  3. 통과한 테스트가 가리지 못하는 엣지/상태(빈 상태, 에러, 동시성, 선택 0개 등)
  4. UI/UX 회귀 위험, 상태 누수, 불필요한 rebuild
  5. 더 단순/재사용 가능한 구현
출력: 발견 사항을 [심각도 high/med/low] + [근거] + [제안]으로 나열.
      거짓 양성 가능성이 있으면 그렇다고 표시. 확신 없는 건 "확인 필요"로.
```

루프는 codex 출력에서 high/med를 우선 백로그로 환류하고, 명백한 즉시수정만 이번 반복에서 처리한다.

---

## 7. 중단 조건 (언제 루프를 멈추나)

다음 중 하나면 멈추고 사용자에게 보고한다:
- 백로그가 비었고 codex 리뷰도 신규 high/med 항목을 못 냄 (수렴).
- 동일 항목에서 2회 연속 게이트(test/analyze) 통과 실패 → 사용자 판단 요청.
- 불변 조건을 지키려면 사용자 결정이 필요한 설계 분기 발생(예: seed 데이터 출처).
- 사용자가 지정한 반복 횟수/시간 도달.

---

## 8. 명령어 치트시트

```bash
cd /Users/hj/Work/Dogu/app
flutter test --reporter compact            # 전체
flutter test --plain-name "<이름>"          # 단일
flutter analyze                            # 정적 분석
flutter run -d web-server --web-port=8080 --web-hostname=127.0.0.1 &   # 렌더용
node verify.js                             # 스크린샷
```

---

### 한 줄 요약
> **백로그에서 1개 택 → 실패 테스트 작성 → 최소 구현으로 통과 → 정리 → 전체 게이트 → codex로 테스트결과 기반 점검 → 원장 갱신 → 반복.** 서버리스·결제UI-only 불변 조건은 매 단계 사수.
