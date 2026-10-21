import 'package:flutter/painting.dart';

/// 색 토큰 — 앱 전체가 이 이름으로만 색을 쓴다.
///
/// Gilded 테마(디자인 시안 `design_mockups/03-gilded-beast`): 짙은 항아리 초록 바탕에 금 테두리·금 제목,
/// 크림색 글씨. 빨강(crave)은 '사고 싶게 만드는' 지점 — 할인·장바구니 수·결제·딜 마감·찜 — 에만 쓴다.
/// 빨강과 초록은 밝기가 비슷해 빨간 글씨는 초록 위에서 거의 안 보인다. 그래서 빨강은 면(배지·버튼)으로 쓰고,
/// 글씨로 써야 하면 밝힌 [alertBright]를 쓴다.
class AppColors {
  // ── 팔레트 ──────────────────────────────────────────────────────────────
  static const pot = Color(0xff173d2a); // 항아리 초록 — 페이지 바탕
  static const potDeep = Color(0xff0f2a1c); // 한 단 깊은 초록 — 이미지 우물·입력칸·하단 탭
  static const deep = Color(0xff0a1f14); // 가장 깊은 초록 — 딜·뉴스레터·결제 바처럼 무게를 주는 띠
  static const gold = Color(0xffc9a24e);
  static const goldBright = Color(0xffefd493);
  static const goldDeep = Color(0xff8f7130);
  static const cream = Color(0xfff5eeda);
  static const crave = Color(0xffb3282d); // 갈망의 빨강 — 면으로 쓴다
  static const craveBright = Color(0xfff0584e); // 초록 위 빨간 글씨

  // ── 바탕 ────────────────────────────────────────────────────────────────
  static const bg = pot;
  static const bgSoft = Color(0xff133523); // 한 단 가라앉은 띠(티커·요약·빈 상태)
  static const bgAlt = potDeep;

  // ── 글씨 ────────────────────────────────────────────────────────────────
  static const ink = cream;
  static const ink2 = Color(0xffddd5bf);
  static const ink3 = Color(0xffa8bcae);
  static const ink4 = Color(0xff7d9585);
  /// 금·크림 면 위 글씨.
  static const invert = potDeep;

  // ── 선 — 금빛이 비치는 올리브 ───────────────────────────────────────────
  static const line = Color(0xff505d36); // 금 32%
  static const lineSoft = Color(0xff334d30); // 금 16%
  static const deepLine = Color(0xff3a4022); // [deep] 위의 금 25%

  // ── 포인트 ──────────────────────────────────────────────────────────────
  /// 주 버튼·활성 칩·제목 앞 번호 — 금.
  static const accent = gold;
  /// 제목·가격처럼 가장 밝게 빛나야 하는 글씨.
  static const accentBright = goldBright;
  /// 금의 그림자(제목 엠보스).
  static const accentDeep = goldDeep;
  /// 빨간 면 — 장바구니 수·결제 버튼·할인 배지·딜 마감.
  static const alert = crave;
  /// 빨간 글씨 — 할인율·찜·미발송.
  static const alertBright = craveBright;

  // ── 메인 광고(히어로) — 깊은 초록에 금빛 ───────────────────────────────
  static const heroBg = potDeep;
  static const heroInk = cream;
  static const heroInk2 = ink2;
  static const heroInk3 = ink3;
  static const heroLine = line;
  // eyebrow 태그(2026 SPRING DROP) — 금 테두리
  static const heroChip = gold;
}
