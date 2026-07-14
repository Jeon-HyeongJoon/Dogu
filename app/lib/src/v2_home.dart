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

/// 상단 제트 블랙 바 — 앱 타이틀 + 액센트 도트 + v1 복귀 칩.
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
          // 항아리 엠블럼 — 그린 바 위의 크림 코인처럼 얹힌다.
          ClipOval(
            child: Image.asset('assets/logo-square.png', width: 30, height: 30, fit: BoxFit.cover),
          ),
          const SizedBox(width: 9),
          Text(
            '욕망의장바구니',
            style: V2Text.display.copyWith(color: V2Colors.potInk, fontSize: 20),
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
      padding: const EdgeInsets.fromLTRB(V2Space.pad, V2Space.pad, V2Space.pad, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => V2NavScope.go(context, 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: V2Colors.surface,
            borderRadius: BorderRadius.circular(V2Space.radius),
            border: Border.all(color: V2Colors.goldSoft, width: 0.8),
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
            // 레드 리본 — 로고 태그라인을 크레이빙 배너로.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: V2Colors.crave,
              child: Text(
                'SATISFYING EVERY CRAVING',
                style: V2Text.mono.copyWith(color: V2Colors.craveInk, fontSize: 10),
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
