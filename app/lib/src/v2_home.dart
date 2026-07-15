part of '../main.dart';

/// v2 홈 바디 = 5F 쇼윈도 — 세로 그리드 대신 백화점 진열대 은유의 실험 레이아웃:
/// 스토어프런트(검색+히어로) 아래 크레이브 티커 테이프가 지나가고,
/// 상품 섹션은 가로 스크롤 진열대(aisle)로 쌓인다. 헤더/층 레일은 V2Shell이 제공.
class V2HomeBody extends StatelessWidget {
  const V2HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return V2ScrollBody(
      builder: (context, cols) => [
        // 스토어프런트 밴드 — 헤더의 딥 그린이 검색바·히어로 포스터까지 한 필드로
        // 흘러내리고, 골드 트림으로 종이 지면과 나뉜다(로고의 라벨이 걸린 매장 전면).
        Container(
          decoration: const BoxDecoration(
            color: V2Colors.pot,
            border: Border(bottom: BorderSide(color: V2Colors.gold, width: 2)),
          ),
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const V2HomeSearchEntry(),
              V2HeroCard(store: store),
            ],
          ),
        ),
        const V2TickerTape(),
        V2CategoryStrip(categories: store.categories),
        const V2SectionHeader(index: 'A-1', title: '오늘의 특가', typeLine: 'Today Only'),
        V2ShelfAisle(code: 'AISLE A-1', products: store.dealProducts),
        const V2SectionHeader(index: 'A-2', title: '신상품', typeLine: 'Just In'),
        V2ShelfAisle(code: 'AISLE A-2', products: store.newProducts),
        const V2SectionHeader(index: 'A-3', title: 'THIS WEEK', typeLine: 'Hot Brands'),
        V2BrandPanel(
          brands: {
            for (final p in [...store.dealProducts, ...store.newProducts]) p.brand,
          }.toList(),
        ),
        const V2SectionHeader(index: 'A-4', title: '뉴스레터', typeLine: '구독'),
        const V2NewsletterBlock(),
        const V2Footer(),
      ],
    );
  }
}

/// 상단 안내데스크 밴드 — 관 표기 eyebrow + 앱 타이틀 + v1 복귀 칩.
/// (항아리 엠블럼은 좌측 층 레일의 옥상 간판으로 이동했다.)
class V2Header extends StatelessWidget {
  const V2Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: V2Space.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: V2Space.pad),
      decoration: const BoxDecoration(
        color: V2Colors.pot,
        border: Border(bottom: BorderSide(color: V2Colors.gold, width: 2)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THE DESIRE DEPT.', style: V2Text.mono.copyWith(color: V2Colors.gold, fontSize: 8)),
              const SizedBox(height: 1),
              Text(
                '욕망의장바구니',
                style: V2Text.display.copyWith(color: V2Colors.potInk, fontSize: 18),
              ),
            ],
          ),
          const Spacer(),
          // v2 → v1 복귀 — GoRouter 밖(단독 위젯 테스트 등)에서는 탭이 조용히 무시된다.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => GoRouter.maybeOf(context)?.go('/'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: V2Colors.potLine),
                borderRadius: BorderRadius.circular(V2Space.radius),
              ),
              child: Text('V1', style: V2Text.mono.copyWith(color: V2Colors.potSoft, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 홈 검색 진입바 — 탭하면 검색 탭으로 이동.
class V2HomeSearchEntry extends StatelessWidget {
  const V2HomeSearchEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(V2Space.pad, 14, V2Space.pad, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => V2NavScope.go(context, 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: V2Colors.paper,
            borderRadius: BorderRadius.circular(V2Space.radius),
            border: Border.all(color: V2Colors.gold, width: 0.8),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 20, color: V2Colors.goldDeep),
              const SizedBox(width: 10),
              Text('어떤 상품을 찾으시나요?', style: V2Text.body.copyWith(fontSize: 13.5, color: V2Colors.inkFaint)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 뉴스레터 구독 — 이메일 입력 + 구독(store.subscribeNewsletter). 결과는 토스트.
class V2NewsletterBlock extends StatefulWidget {
  const V2NewsletterBlock({super.key});

  @override
  State<V2NewsletterBlock> createState() => _V2NewsletterBlockState();
}

class _V2NewsletterBlockState extends State<V2NewsletterBlock> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final email = _controller.text.trim();
    final store = AppStateScope.read(context);
    if (!email.contains('@')) {
      store.showCartToast('이메일 주소를 확인해 주세요.');
      return;
    }
    _controller.clear();
    store.showCartToast('$email 구독 신청이 접수되었습니다.');
    try {
      await DoguRepository().subscribeNewsletter(email);
    } catch (_) {
      // 백엔드 미가용이어도 UI 피드백은 유지(v1 NewsletterSection과 동일 동작).
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: V2Space.pad),
      child: V2Panel(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: V2Text.body.copyWith(color: V2Colors.ink, fontSize: 13),
                cursorColor: V2Colors.crave,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: '이메일로 신상품 소식 받기',
                  hintStyle: V2Text.body.copyWith(color: V2Colors.inkFaint, fontSize: 13),
                ),
                onSubmitted: (_) => _subscribe(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _subscribe,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: V2Colors.pot,
                  borderRadius: BorderRadius.circular(V2Space.radius),
                  border: Border.all(color: V2Colors.gold, width: 1.2),
                ),
                child: Text('구독', style: V2Text.title.copyWith(color: V2Colors.potInk, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 히어로 — 브랜드 포스터: 골드 이중 괘선 라벨 안에 엠블럼·타이틀·레드 리본·스탯을
/// 센터 정렬로 쌓아 로고(빈티지 엠블럼)의 인상을 그대로 옮긴다.
class V2HeroCard extends StatelessWidget {
  const V2HeroCard({required this.store, super.key});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(V2Space.pad, V2Space.pad, V2Space.pad, 4),
      child: V2LabelFrame(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          children: [
            // 브랜드 인장 — 엠블럼을 골드 링으로 감싼다.
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: V2Colors.gold),
              child: ClipOval(
                child: Image.asset('assets/logo-square.png', width: 68, height: 68, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            V2TypeLine(store.heroEyebrow, color: V2Colors.gold),
            const SizedBox(height: 10),
            Text(
              store.heroTitle,
              textAlign: TextAlign.center,
              style: V2Text.display.copyWith(color: V2Colors.potInk, fontSize: 28),
            ),
            const SizedBox(height: 10),
            Text(
              store.heroSubtitle,
              textAlign: TextAlign.center,
              style: V2Text.body.copyWith(color: V2Colors.potSoft, fontSize: 13),
            ),
            const SizedBox(height: 16),
            // 태그라인 스탬프 — 레드 배너 대신 골드 헤어라인 스탬프로 절제.
            // (레드는 가격·할인 등 욕망이 닿는 곳에만 남긴다.)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: V2Colors.gold, width: 0.8),
                  bottom: BorderSide(color: V2Colors.gold, width: 0.8),
                ),
              ),
              child: Text(
                'SATISFYING EVERY CRAVING',
                style: V2Text.mono.copyWith(color: V2Colors.gold, fontSize: 10),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (var i = 0; i < store.heroStats.length; i++) ...[
                  if (i > 0) Container(width: 1, height: 26, color: V2Colors.potLine),
                  Expanded(
                    child: Column(
                      children: [
                        // U+2212(−) 등 번들 폰트에 없는 기호는 ASCII로 정규화해 두부를 막는다.
                        Text(
                          store.heroStats[i].$1.replaceAll('−', '-'),
                          style: V2Text.title.copyWith(color: V2Colors.gold, fontSize: 20),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          store.heroStats[i].$2,
                          style: V2Text.body.copyWith(color: V2Colors.potSoft, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 카테고리 스트립 — 엠블럼을 닮은 원형 코인 배지의 가로 롤.
class V2CategoryStrip extends StatelessWidget {
  const V2CategoryStrip({required this.categories, super.key});
  final List<CategoryItem> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(V2Space.pad, 18, V2Space.pad, 4),
        children: [
          for (final c in categories)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  V2NavScope.go(context, 1);
                  AppStateScope.read(context).selectCategoryBrowse(_normalizeCategoryKey(c.id.isEmpty ? c.name : c.id));
                },
                child: SizedBox(
                  width: 62,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: V2Colors.surface,
                          border: Border.all(color: V2Colors.line),
                        ),
                        child: Text(
                          c.name.substring(0, 1),
                          style: V2Text.title.copyWith(color: V2Colors.inkSoft, fontSize: 21),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: V2Text.body.copyWith(color: V2Colors.inkSoft, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 반응형 상품 그리드 — Wrap 기반이라 셀 높이가 콘텐츠에 맞춰져 오버플로 없음.
class V2ProductGrid extends StatelessWidget {
  const V2ProductGrid({required this.products, required this.columns, super.key});
  final List<ProductItem> products;
  final int columns;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    const gap = V2Space.gap;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: V2Space.pad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: 26, // 에디토리얼 여백 — 행 사이는 넉넉하게 띄운다.
            children: [
              for (final p in products)
                SizedBox(width: cardWidth, child: V2ProductCard(product: p)),
            ],
          );
        },
      ),
    );
  }
}

/// 티커 테이프 — 스토어프런트 아래를 지나가는 매장 안내 띠.
/// 프리미엄 커머스 문법대로 종이 바탕 + 헤어라인 + 잉크 타이포로 절제하고,
/// 무한 애니메이션(타이머) 없이 가로 무한 ListView로 만들어 손으로 밀 수 있다.
class V2TickerTape extends StatelessWidget {
  const V2TickerTape({super.key});

  static const _lines = <String>[
    'SATISFYING EVERY CRAVING',
    '5F SHOWCASE NOW OPEN',
    'POT OF DESIRE CO.',
    'TODAY ONLY DEALS',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: const BoxDecoration(
        color: V2Colors.paper,
        border: Border(bottom: BorderSide(color: V2Colors.line, width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) => Row(
          children: [
            const SizedBox(width: 22),
            const V2Diamond(size: 3.5, color: V2Colors.gold),
            const SizedBox(width: 22),
            Center(
              child: Text(
                _lines[i % _lines.length],
                style: V2Text.mono.copyWith(color: V2Colors.inkSoft, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 가로 진열대(aisle) — 상품을 세로 그리드 대신 선반 위에 일렬로 눕힌다.
/// 선반 아래 골드 레일과 통로 코드로 백화점 진열대의 인상을 만든다.
class V2ShelfAisle extends StatelessWidget {
  const V2ShelfAisle({required this.code, required this.products, super.key});
  final String code;
  final List<ProductItem> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: V2Space.pad),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: V2Space.gap),
            itemBuilder: (context, i) => SizedBox(
              width: 168,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [V2ProductCard(product: products[i])],
              ),
            ),
          ),
        ),
        // 선반 레일 — 카드가 얹힌 골드 바 + 통로 코드.
        Padding(
          padding: const EdgeInsets.fromLTRB(V2Space.pad, 6, V2Space.pad, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 2, color: V2Colors.goldSoft),
              const SizedBox(height: 5),
              Row(
                children: [
                  V2SetCode(code, color: V2Colors.inkFaint),
                  const Spacer(),
                  V2SetCode('${products.length} ITEMS'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 브랜드 패널 — 효과 텍스트 박스 안에 브랜드 나열.
class V2BrandPanel extends StatelessWidget {
  const V2BrandPanel({required this.brands, super.key});
  final List<String> brands;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: V2Space.pad),
      child: V2Panel(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final b in brands)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: V2Colors.line),
                  borderRadius: BorderRadius.circular(V2Space.radiusSm),
                ),
                child: Text(b, style: V2Text.body.copyWith(color: V2Colors.ink, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }
}

/// 푸터 — 브랜드 서명 + 태그라인 + 저작권 라인.
class V2Footer extends StatelessWidget {
  const V2Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(V2Space.pad, 24, V2Space.pad, 0),
      child: Column(
        children: [
          Center(child: V2SetCode('SATISFYING EVERY CRAVING', color: V2Colors.goldDeep)),
          SizedBox(height: 8),
          Row(
            children: [
              V2SetCode('POT OF DESIRE CO.'),
              Spacer(),
              V2SetCode('© 2026 욕망의장바구니'),
            ],
          ),
        ],
      ),
    );
  }
}
