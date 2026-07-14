part of '../main.dart';

// ─────────────────────────────────────────────────────────────────────────
// v2 "Desire Emporium" 디자인 시스템 — Pot of Desire Co. 로고(assets/logo-pot.jpg)
// 의 철학(탐욕스러운 미소, SATISFYING EVERY CRAVING)에서 DNA를 잡는다.
//   · 배경 = 아이보리 종이 — 빈티지 엠포리엄의 지면
//   · 블록 = 딥 그린(헤더·히어로·주 CTA) — 로고의 바구니/잉크 그린
//   · 골드 = 브라스 레이블·트림 — eyebrow/인덱스/타이프라인 전용
//   · 레드 = 크레이빙(갈망) — 가격·할인·찜, 욕망이 닿는 곳에만
//   · 타이포 = 디스플레이는 둥근 고딕(NanumSquareRound EB) — 능글맞은 무게감
//   · 상품 = 아트워크 풀블리드 — 구조는 aggressive-clean을 유지
// v2 위젯은 전용 const 토큰만 쓰므로 v1(AppColors) 트리와 완전히 분리된다.
// (방향 문서: docs/DESIGN_REVIEW_V2.md)
// ─────────────────────────────────────────────────────────────────────────

class V2Colors {
  static const paper = Color(0xfffaf5ea); // 페이지 배경(아이보리 종이)
  static const surface = Color(0xfff1e9d6); // 서브 서피스(칩·입력창)

  static const ink = Color(0xff1a2b20); // 본문·디스플레이(그린 블랙)
  static const inkSoft = Color(0xff53645a);
  static const inkFaint = Color(0xff92a097);
  static const line = Color(0xffe2d8c2); // 헤어라인

  static const pot = Color(0xff1d4a33); // 브랜드 그린 블록(헤더·히어로·CTA)
  static const potInk = Color(0xfff5eeda); // 그린 블록 위 글씨(크림)
  static const potSoft = Color(0xffa8bcae); // 그린 블록 위 보조 글씨
  static const potLine = Color(0xff2e5c42); // 그린 블록 안 구분선

  static const gold = Color(0xffc9a24e); // 브라스 골드 — 레이블·트림 전용
  static const goldDeep = Color(0xff8f7130); // 종이 위 골드 텍스트(가독 확보)
  static const goldSoft = Color(0xffd9c48f); // 종이 위 골드 괘선(은은한 트림)

  static const crave = Color(0xffb3282d); // 크레이빙 레드 — 가격·할인·찜
  static const craveInk = Color(0xfffdf7ee); // 레드 블록 위 글씨
}

class V2Space {
  static const pad = 20.0;
  static const gap = 14.0;
  static const radius = 4.0; // 카드·버튼 모서리(거의 각지게)
  static const radiusSm = 2.0; // 배지·이미지 모서리
  static const headerHeight = 56.0;
  static const tabHeight = 64.0;

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
  // 대형 디스플레이 — 둥근 고딕 ExtraBold: 항아리의 능글맞은 무게감.
  static const TextStyle display = TextStyle(
    fontFamily: doguHeroFontFamily,
    fontWeight: FontWeight.w800,
    color: V2Colors.ink,
    letterSpacing: -0.6,
    height: 1.08,
  );
  static const TextStyle title = TextStyle(
    fontFamily: doguHeroFontFamily,
    fontWeight: FontWeight.w800,
    color: V2Colors.ink,
    letterSpacing: -0.3,
    height: 1.15,
  );
  static const TextStyle body = TextStyle(
    fontFamily: doguFontFamily,
    color: V2Colors.inkSoft,
    height: 1.5,
  );
  // 대문자 eyebrow/카운트 등 소형 레이블 — 넓은 자간으로 긴장감을 준다.
  static const TextStyle mono = TextStyle(
    fontFamily: doguFontFamily,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
    color: V2Colors.inkFaint,
  );
}

/// 대문자 eyebrow 레이블 — 섹션 우측 액션/보조 표기에 사용.
class V2TypeLine extends StatelessWidget {
  const V2TypeLine(this.label, {this.color = V2Colors.goldDeep, super.key});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: V2Text.mono.copyWith(color: color, fontSize: 11),
    );
  }
}

/// 일련번호/카운트 등 초소형 캡션.
class V2SetCode extends StatelessWidget {
  const V2SetCode(this.code, {this.color = V2Colors.inkFaint, super.key});
  final String code;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(code.toUpperCase(), style: V2Text.mono.copyWith(color: color, fontSize: 9));
  }
}

/// 골드 이중 괘선 프레임 — 로고의 빈티지 라벨 테두리를 그대로 옮긴다.
/// 바깥 1.5px + 안쪽 0.8px 두 겹의 골드 선 사이에 3px 숨을 둔다.
class V2LabelFrame extends StatelessWidget {
  const V2LabelFrame({
    required this.child,
    this.background = V2Colors.pot,
    this.lineColor = V2Colors.gold,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final Color background;
  final Color lineColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(V2Space.radius),
        border: Border.all(color: lineColor, width: 1.5),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(V2Space.radiusSm),
          border: Border.all(color: lineColor, width: 0.8),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// 골드 다이아 오너먼트 — 괘선 사이의 마름모 장식(글리프 대신 도형이라 두부 없음).
class V2Diamond extends StatelessWidget {
  const V2Diamond({this.size = 5, this.color = V2Colors.gold, super.key});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: pi / 4,
      child: Container(width: size, height: size, color: color),
    );
  }
}

/// 플랫 카드 — 순백 + 헤어라인 1px. 그림자·이중 테두리 없음.
class V2CardFrame extends StatelessWidget {
  const V2CardFrame({required this.child, this.padding, this.onTap, super.key});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final frame = Container(
      decoration: BoxDecoration(
        color: V2Colors.paper,
        borderRadius: BorderRadius.circular(V2Space.radius),
        border: Border.all(color: V2Colors.line),
      ),
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );
    if (onTap == null) return frame;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: frame);
  }
}

/// 서브 서피스 박스 — 옅은 그레이 플랫 패널(입력창·요약 등).
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
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(V2Space.radius),
      ),
      child: child,
    );
  }
}

/// 상품 아트워크 — 네트워크 이미지 없이 artwork(HSL+글리프)로 결정적 렌더.
/// 테두리 없이 풀블리드로 깔고, 브랜드 이니셜을 크게 얹는다.
class V2Artwork extends StatelessWidget {
  const V2Artwork({required this.product, super.key});
  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    final art = product.artwork;
    final base = art == null
        ? V2Colors.surface
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
            colors: [base, Color.lerp(base, V2Colors.ink, 0.25) ?? base],
          ),
          borderRadius: BorderRadius.circular(V2Space.radiusSm),
        ),
        alignment: Alignment.center,
        // seed의 artwork.mono는 이색 특수문자(두부 위험)라, 확실히 렌더되는 브랜드
        // 이니셜을 아트 상징으로 크게 얹는다.
        child: Text(
          product.brand.isEmpty ? '욕' : product.brand.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontFamily: doguFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 52,
            color: Colors.white.withValues(alpha: 0.9),
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

/// 빈 상태 — 액센트 바 + 대형 타이틀. 장식 없이 타이포로만 말한다.
class V2EmptyState extends StatelessWidget {
  const V2EmptyState({required this.title, required this.message, super.key});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(V2Space.pad, 36, V2Space.pad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 28, height: 4, color: V2Colors.gold),
          const SizedBox(height: 16),
          Text(title, style: V2Text.title.copyWith(fontSize: 20)),
          const SizedBox(height: 6),
          Text(message, style: V2Text.body.copyWith(fontSize: 13, color: V2Colors.inkFaint)),
        ],
      ),
    );
  }
}

/// 태그 칩 — 최근 검색/추천 브랜드 등. 서피스 위 잉크, 각진 모서리.
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: V2Colors.surface,
          borderRadius: BorderRadius.circular(V2Space.radiusSm),
        ),
        child: Text(
          label,
          style: V2Text.body.copyWith(color: V2Colors.ink, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// 섹션 헤더 — 빈티지 라벨 괘선: NO.인덱스 ── ◆ ── 타이프라인, 아래 대형 타이틀.
class V2SectionHeader extends StatelessWidget {
  const V2SectionHeader({required this.index, required this.title, required this.typeLine, this.onTypeLineTap, super.key});
  final String index;
  final String title;
  final String typeLine;
  final VoidCallback? onTypeLineTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(V2Space.pad, 30, V2Space.pad, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('NO.$index', style: V2Text.mono.copyWith(color: V2Colors.goldDeep, fontSize: 10)),
              const SizedBox(width: 10),
              const Expanded(child: Divider(height: 1, thickness: 0.8, color: V2Colors.goldSoft)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: V2Diamond(size: 5, color: V2Colors.goldDeep),
              ),
              const Expanded(child: Divider(height: 1, thickness: 0.8, color: V2Colors.goldSoft)),
              const SizedBox(width: 10),
              if (onTypeLineTap == null)
                V2TypeLine(typeLine)
              else
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTypeLineTap,
                  child: V2TypeLine(typeLine, color: V2Colors.crave),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: V2Text.title.copyWith(fontSize: 23)),
        ],
      ),
    );
  }
}

/// 상품 카드 — 풀블리드 아트 + 브랜드/이름 + 할인율·가격. 프레임·그림자 없음.
class V2ProductCard extends StatelessWidget {
  const V2ProductCard({required this.product, super.key});
  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    final wished = AppStateScope.watch(context).wishlistIds.contains(product.id);
    final hasDiscount = product.discount.isNotEmpty && product.discount != '-0%';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openV2ProductDetail(
        context,
        product,
        onGoToCart: () {
          Navigator.of(context, rootNavigator: true).maybePop();
          V2NavScope.go(context, 4);
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 풀블리드 아트워크 + 하트
          Stack(
            children: [
              V2Artwork(product: product),
              Positioned(
                right: 6,
                top: 6,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => AppStateScope.read(context).toggleWishlist(product),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: V2Colors.ink.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      wished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 16,
                      color: wished ? V2Colors.crave : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          // 브랜드 — 대문자 eyebrow
          Text(
            product.brand.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: V2Text.mono.copyWith(fontSize: 10, color: V2Colors.inkSoft),
          ),
          const SizedBox(height: 3),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: V2Text.body.copyWith(color: V2Colors.ink, fontSize: 13, height: 1.3, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 7),
          // 할인율(액센트) + 가격(볼드) + 정가(취소선)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (hasDiscount) ...[
                Text(
                  product.discount.replaceAll('-', '').replaceAll('−', ''),
                  style: V2Text.title.copyWith(color: V2Colors.crave, fontSize: 16),
                ),
                const SizedBox(width: 5),
              ],
              Text(product.price, style: V2Text.title.copyWith(fontSize: 16)),
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
    );
  }
}
