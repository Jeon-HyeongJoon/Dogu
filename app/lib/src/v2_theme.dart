part of '../main.dart';

// ─────────────────────────────────────────────────────────────────────────
// v2 "욕망의 항아리" 디자인 시스템 — 유희왕 마법(Spell) 카드 프레임에서 DNA를 잡는다.
//   · 주색 = 마법 카드 청록(teal) 프레임
//   · 테두리 = 금색/브론즈 트림(아트워크 프레임)
//   · 패널 = 크림/베이지 효과 텍스트 박스
//   · 잉크 = 짙은 갈색-블랙 + 마룬 포인트(아트 배경 적색)
//   · 요소 = 카드 프레임형 타일, 속성 원형 배지, [브래킷] 타입라인, 모서리 세트코드
// v2 위젯은 전용 const 토큰만 쓰므로 v1(AppColors) 트리와 완전히 분리된다.
// ─────────────────────────────────────────────────────────────────────────

class V2Colors {
  static const parchment = Color(0xfff3ebd7); // 페이지 배경(종이 질감)
  static const parchmentSoft = Color(0xffece1c6);

  static const teal = Color(0xff147d6b); // 마법 카드 프레임
  static const tealDark = Color(0xff0c4e43);
  static const tealLight = Color(0xff2ba189);
  static const tealInk = Color(0xffeafaf4); // 청록 위 밝은 글씨

  static const gold = Color(0xffc7a24c); // 아트워크 금색 트림
  static const goldDark = Color(0xff8c6e22);
  static const goldLight = Color(0xffe3c877);

  static const cream = Color(0xfff6efdc); // 효과 텍스트 박스
  static const creamBorder = Color(0xffd9c89a);

  static const ink = Color(0xff1b140c);
  static const inkSoft = Color(0xff5a4e3c);
  static const inkFaint = Color(0xff8a7c64);

  static const maroon = Color(0xff7e2426); // 아트 배경 적색 포인트
}

class V2Space {
  static const pad = 20.0;
  static const gap = 12.0;
  static const radius = 10.0; // 카드 모서리
  static const artRadius = 4.0; // 아트워크 프레임 모서리
  static const frameBorder = 2.0; // 청록 프레임 두께
  static const goldBorder = 2.5; // 금색 트림 두께
  static const headerHeight = 56.0;
  static const tabHeight = 72.0;

  // 반응형: 모바일 좁은 캔버스 → 태블릿은 넓은 캔버스 + 더 많은 열.
  static const phoneMax = 440.0;
  static const tabletMax = 760.0;

  static double contentMaxWidth(double screenWidth) =>
      screenWidth >= 720 ? tabletMax : phoneMax;

  static int productColumns(double screenWidth) {
    if (screenWidth >= 1000) return 4;
    if (screenWidth >= 640) return 3;
    return 2;
  }
}

class V2Text {
  // 카드 이름판 느낌의 굵은 디스플레이(둥근 고딕)
  static const TextStyle display = TextStyle(
    fontFamily: doguHeroFontFamily,
    fontWeight: FontWeight.w800,
    color: V2Colors.ink,
    letterSpacing: -0.4,
    height: 1.1,
  );
  static const TextStyle title = TextStyle(
    fontFamily: doguHeroFontFamily,
    fontWeight: FontWeight.w800,
    color: V2Colors.ink,
    letterSpacing: -0.2,
    height: 1.15,
  );
  static const TextStyle body = TextStyle(
    fontFamily: doguFontFamily,
    color: V2Colors.inkSoft,
    height: 1.5,
  );
  // 세트코드/일련번호 — 모서리 코드 느낌(넓은 자간). 웹/골든 모두 확실히 렌더되도록
  // 시스템 monospace 대신 번들 Pretendard를 쓴다(한글·기호 글리프 보장).
  static const TextStyle mono = TextStyle(
    fontFamily: doguFontFamily,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: V2Colors.inkFaint,
  );
}

/// 유희왕 카드의 속성 원형 배지 — 카테고리를 상징 글리프로 표현.
class V2AttributeBadge extends StatelessWidget {
  const V2AttributeBadge({required this.categoryKey, this.size = 26, super.key});
  final String categoryKey;
  final double size;

  // 한자는 한글 번들 폰트에 없어 두부가 되므로 한글 이니셜을 속성 마크로 쓴다.
  static const Map<String, String> _glyphs = {
    'clothing': '의',
    'tech': '기',
    'home': '홈',
    'beauty': '뷰',
    'sports': '스',
    'kids': '키',
  };

  @override
  Widget build(BuildContext context) {
    final glyph = _glyphs[categoryKey] ?? '욕';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [V2Colors.goldLight, V2Colors.gold, V2Colors.goldDark],
          stops: [0.0, 0.6, 1.0],
        ),
        border: Border.fromBorderSide(BorderSide(color: V2Colors.goldDark, width: 1.2)),
      ),
      child: Text(
        glyph,
        style: TextStyle(
          fontFamily: doguHeroFontFamily,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.5,
          color: V2Colors.ink,
          height: 1.0,
        ),
      ),
    );
  }
}

/// `[마법 카드]`식 브래킷 타입라인 — 섹션/카테고리 라벨에 사용.
class V2TypeLine extends StatelessWidget {
  const V2TypeLine(this.label, {this.color = V2Colors.inkSoft, super.key});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '[ $label ]',
      style: V2Text.body.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 11.5,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// 모서리 세트코드/일련번호.
class V2SetCode extends StatelessWidget {
  const V2SetCode(this.code, {this.color = V2Colors.inkFaint, super.key});
  final String code;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(code.toUpperCase(), style: V2Text.mono.copyWith(color: color, fontSize: 9));
  }
}

/// 마법 카드 프레임 — 청록 테두리 + 안쪽 금색 트림, 자식을 감싼다.
class V2CardFrame extends StatelessWidget {
  const V2CardFrame({required this.child, this.padding, this.onTap, super.key});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final frame = Container(
      decoration: BoxDecoration(
        color: V2Colors.teal,
        borderRadius: BorderRadius.circular(V2Space.radius),
        border: Border.all(color: V2Colors.tealDark, width: V2Space.frameBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: EdgeInsets.all(padding == null ? 7 : 0),
      child: padding == null
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(V2Space.artRadius),
                border: Border.all(color: V2Colors.goldDark, width: 1),
              ),
              child: child,
            )
          : Padding(padding: padding!, child: child),
    );
    if (onTap == null) return frame;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: frame);
  }
}

/// 크림색 효과 텍스트 박스.
class V2Panel extends StatelessWidget {
  const V2Panel({required this.child, this.padding = const EdgeInsets.all(12), super.key});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: V2Colors.cream,
        borderRadius: BorderRadius.circular(V2Space.artRadius),
        border: Border.all(color: V2Colors.creamBorder),
      ),
      child: child,
    );
  }
}

/// 상품 아트워크 박스 — 네트워크 이미지 없이 artwork(HSL+글리프)로 결정적 렌더.
class V2Artwork extends StatelessWidget {
  const V2Artwork({required this.product, super.key});
  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    final art = product.artwork;
    final base = art == null
        ? V2Colors.tealLight
        : HSLColor.fromAHSL(
            1,
            (art.hue % 360).toDouble(),
            (art.saturation.clamp(0, 100)) / 100,
            (art.lightness.clamp(0, 100)) / 100,
          ).toColor();
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, Color.lerp(base, V2Colors.maroon, 0.35) ?? base],
          ),
          border: const Border.fromBorderSide(BorderSide(color: V2Colors.goldDark, width: 1.5)),
        ),
        alignment: Alignment.center,
        // seed의 artwork.mono는 이색 특수문자(두부 위험)라, 확실히 렌더되는 브랜드
        // 이니셜을 카드 아트 상징으로 크게 얹는다.
        child: Text(
          product.brand.isEmpty ? '욕' : product.brand.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontFamily: doguHeroFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 52,
            color: Colors.white.withValues(alpha: 0.92),
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/// 반응형 스크롤 바디 — 콘텐츠 최대폭 중앙 정렬 + 하단 여백. 모든 v2 탭이 공유한다.
/// builder는 현재 폭에 맞는 상품 그리드 열 수(columns)를 받아 섹션 리스트를 반환.
class V2ScrollBody extends StatelessWidget {
  const V2ScrollBody({required this.builder, super.key});
  final List<Widget> Function(BuildContext context, int columns) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = V2Space.contentMaxWidth(constraints.maxWidth);
        final cols = V2Space.productColumns(constraints.maxWidth);
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...builder(context, cols),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 빈 상태 — 크림 패널 안에 안내 문구(찜/장바구니/검색 결과 없음).
class V2EmptyState extends StatelessWidget {
  const V2EmptyState({required this.title, required this.message, super.key});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(V2Space.pad, 28, V2Space.pad, 0),
      child: V2Panel(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        child: Column(
          children: [
            const V2AttributeBadge(categoryKey: 'greed', size: 40),
            const SizedBox(height: 14),
            Text(title, style: V2Text.title.copyWith(fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: V2Text.body.copyWith(fontSize: 12.5), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// 태그 칩 — 최근 검색/추천 브랜드 등.
class V2TagChip extends StatelessWidget {
  const V2TagChip(this.label, {this.onTap, super.key});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: V2Colors.cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: V2Colors.creamBorder),
        ),
        child: Text(label, style: V2Text.body.copyWith(color: V2Colors.ink, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// 섹션 헤더 — 인덱스 + 제목 + 브래킷 타입라인(TCG 카드 상단 느낌).
class V2SectionHeader extends StatelessWidget {
  const V2SectionHeader({required this.index, required this.title, required this.typeLine, super.key});
  final String index;
  final String title;
  final String typeLine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(V2Space.pad, 22, V2Space.pad, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: V2Colors.teal,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: V2Colors.goldDark, width: 1),
            ),
            child: Text(index, style: V2Text.mono.copyWith(color: V2Colors.goldLight, fontSize: 10)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: V2Text.title.copyWith(fontSize: 21))),
          V2TypeLine(typeLine),
        ],
      ),
    );
  }
}

/// 상품 미니 카드 — 마법 카드 프레임: 이름판 · 금테 아트 · 크림 효과 박스.
class V2ProductCard extends StatelessWidget {
  const V2ProductCard({required this.product, super.key});
  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    return V2CardFrame(
      onTap: () => openProductDetail(context, product),
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 이름판: 브랜드 + 속성 배지
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    product.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: V2Text.title.copyWith(color: V2Colors.tealInk, fontSize: 12.5),
                  ),
                ),
                V2AttributeBadge(categoryKey: product.categoryKey, size: 22),
              ],
            ),
          ),
          // 금테 아트워크 + 코너 배지들
          Stack(
            children: [
              V2Artwork(product: product),
              if (product.discount.isNotEmpty && product.discount != '-0%')
                Positioned(
                  left: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    color: V2Colors.maroon,
                    child: Text(product.discount, style: V2Text.mono.copyWith(color: Colors.white, fontSize: 10)),
                  ),
                ),
              Positioned(right: 4, bottom: 4, child: V2SetCode(product.id, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 6),
          // 크림 효과 박스: 상품명 + 가격
          V2Panel(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: V2Text.body.copyWith(color: V2Colors.ink, fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(product.price, style: V2Text.title.copyWith(color: V2Colors.maroon, fontSize: 15)),
                    if (product.hasDiscount) ...[
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          product.oldPrice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: V2Text.body.copyWith(
                            fontSize: 11,
                            color: V2Colors.inkFaint,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
