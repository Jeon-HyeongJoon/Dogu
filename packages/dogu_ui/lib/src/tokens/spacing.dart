/// 여백 토큰.
class AppSpace {
  /// 화면 좌우 기본 여백.
  static const pad = 20.0;

  /// 카드 격자 칸 사이.
  static const gutter = 10.0;
}

/// 선 굵기 토큰 — Gilded는 머리카락 선으로 나눈다. 3배 화면에선 1.5px, 1배 화면에선 반투명 1px로 그려진다.
class AppStroke {
  /// 구획·카드·입력칸의 기본 선.
  static const hair = 0.5;

  /// 눌러야 하는 테두리(보조 버튼·선택 칸) — 머리카락 선보다 한 단 또렷하게.
  static const control = 0.8;
}
