part of '../main.dart';

/// v2 홈 바디 — v1과 동일한 섹션 구성(히어로·카테고리·특가·신상·브랜드·푸터)을
/// aggressive-clean 디자인으로 미러링한다. 상단 헤더/하단 탭바는 V2Shell이 제공한다.
class V2HomeBody extends StatelessWidget {
  const V2HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return V2ScrollBody(
      builder: (context, cols) => [
        const V2HomeSearchEntry(),
        V2HeroCard(store: store),
        V2CategoryStrip(categories: store.categories),
        const V2SectionHeader(index: '01', title: '오늘의 특가', typeLine: 'Today Only'),
        V2ProductGrid(products: store.dealProducts, columns: cols),
        const V2SectionHeader(index: '02', title: '신상품', typeLine: 'Just In'),
        V2ProductGrid(products: store.newProducts, columns: cols),
        const V2SectionHeader(index: '03', title: 'THIS WEEK', typeLine: 'Hot Brands'),
        V2BrandPanel(
          brands: {
            for (final p in [...store.dealProducts, ...store.newProducts]) p.brand,
          }.toList(),
        ),
        const V2SectionHeader(index: '04', title: '뉴스레터', typeLine: '구독'),
        const V2NewsletterBlock(),
        const V2Footer(),
      ],
    );
  }
}

/// 상단 제트 블랙 바 — 앱 타이틀 + 액센트 도트.
class V2Header extends StatelessWidget {
  const V2Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: V2Space.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: V2Space.pad),
      color: V2Colors.jet,
      child: Row(
        children: [
          Text(
            '욕망의장바구니',
            style: V2Text.display.copyWith(color: V2Colors.jetInk, fontSize: 20),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: V2Colors.accent, shape: BoxShape.circle),
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
      padding: const EdgeInsets.fromLTRB(V2Space.pad, V2Space.pad, V2Space.pad, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => V2NavScope.go(context, 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: V2Colors.surface,
            borderRadius: BorderRadius.circular(V2Space.radius),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 20, color: V2Colors.ink),
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
                cursorColor: V2Colors.accent,
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
                  color: V2Colors.jet,
                  borderRadius: BorderRadius.circular(V2Space.radius),
                ),
                child: Text('구독', style: V2Text.title.copyWith(color: V2Colors.jetInk, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 히어로 — 제트 블랙 블록: 액센트 eyebrow + 대형 디스플레이 + 스탯 스트립.
class V2HeroCard extends StatelessWidget {
  const V2HeroCard({required this.store, super.key});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(V2Space.pad, V2Space.pad, V2Space.pad, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        decoration: BoxDecoration(
          color: V2Colors.jet,
          borderRadius: BorderRadius.circular(V2Space.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            V2TypeLine(store.heroEyebrow, color: V2Colors.accent),
            const SizedBox(height: 12),
            Text(store.heroTitle, style: V2Text.display.copyWith(color: V2Colors.jetInk, fontSize: 30)),
            const SizedBox(height: 10),
            Text(store.heroSubtitle, style: V2Text.body.copyWith(color: V2Colors.jetSoft, fontSize: 13)),
            const SizedBox(height: 18),
            Container(height: 1, color: V2Colors.jetLine),
            const SizedBox(height: 14),
            Wrap(
              spacing: 22,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final stat in store.heroStats)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      // U+2212(−) 등 번들 폰트에 없는 기호는 ASCII로 정규화해 두부를 막는다.
                      Text(stat.$1.replaceAll('−', '-'), style: V2Text.title.copyWith(color: V2Colors.accent, fontSize: 20)),
                      const SizedBox(width: 5),
                      Text(stat.$2, style: V2Text.body.copyWith(color: V2Colors.jetSoft, fontSize: 11)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 카테고리 스트립 — 속성 배지 + 라벨.
class V2CategoryStrip extends StatelessWidget {
  const V2CategoryStrip({required this.categories, super.key});
  final List<CategoryItem> categories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(V2Space.pad, 16, V2Space.pad, 4),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final c in categories)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                V2NavScope.go(context, 1);
                AppStateScope.read(context).selectCategoryBrowse(_normalizeCategoryKey(c.id.isEmpty ? c.name : c.id));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: V2Colors.surface,
                  borderRadius: BorderRadius.circular(V2Space.radiusSm),
                ),
                child: Text(c.name, style: V2Text.body.copyWith(color: V2Colors.ink, fontSize: 12.5, fontWeight: FontWeight.w700)),
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
            runSpacing: gap,
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

/// 푸터 — 저작권 라인.
class V2Footer extends StatelessWidget {
  const V2Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(V2Space.pad, 24, V2Space.pad, 0),
      child: Row(
        children: [
          V2SetCode('DOGU'),
          Spacer(),
          V2SetCode('© 2026 욕망의장바구니'),
        ],
      ),
    );
  }
}
