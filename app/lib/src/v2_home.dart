part of '../main.dart';

/// v2 홈 바디 — v1과 동일한 섹션 구성(히어로·카테고리·특가·신상·브랜드·푸터)을
/// 유희왕 마법 카드 디자인으로 미러링한다. 상단 헤더/하단 탭바는 V2Shell이 제공한다.
class V2HomeBody extends StatelessWidget {
  const V2HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return V2ScrollBody(
      builder: (context, cols) => [
        V2HeroCard(store: store),
        V2CategoryStrip(categories: store.categories),
        const V2SectionHeader(index: '01', title: '오늘의 특가', typeLine: '속공 마법'),
        V2ProductGrid(products: store.dealProducts, columns: cols),
        const V2SectionHeader(index: '02', title: '신상 드로우', typeLine: '일반 마법'),
        V2ProductGrid(products: store.newProducts, columns: cols),
        const V2SectionHeader(index: '03', title: 'THIS WEEK', typeLine: '금지 · 제한'),
        V2BrandPanel(
          brands: {
            for (final p in [...store.dealProducts, ...store.newProducts]) p.brand,
          }.toList(),
        ),
        const V2Footer(),
      ],
    );
  }
}

/// 상단 청록 바 — 카드 이름 영역처럼 앱 타이틀 + 속성 배지.
class V2Header extends StatelessWidget {
  const V2Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: V2Space.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: V2Space.pad),
      decoration: const BoxDecoration(
        color: V2Colors.teal,
        border: Border(bottom: BorderSide(color: V2Colors.goldDark, width: V2Space.goldBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '욕망의 항아리',
              style: V2Text.display.copyWith(color: V2Colors.tealInk, fontSize: 20),
            ),
          ),
          const V2TypeLine('마법 카드', color: V2Colors.goldLight),
          const SizedBox(width: 10),
          const V2AttributeBadge(categoryKey: 'greed', size: 30),
        ],
      ),
    );
  }
}

/// 히어로 — 한 장의 큰 마법 카드로 표현.
class V2HeroCard extends StatelessWidget {
  const V2HeroCard({required this.store, super.key});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(V2Space.pad, V2Space.pad, V2Space.pad, 4),
      child: V2CardFrame(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: V2TypeLine(store.heroEyebrow, color: V2Colors.goldLight)),
                V2SetCode('SY-KR040', color: V2Colors.tealInk),
              ],
            ),
            const SizedBox(height: 10),
            Text(store.heroTitle, style: V2Text.display.copyWith(color: V2Colors.tealInk, fontSize: 26)),
            const SizedBox(height: 12),
            V2Panel(
              child: Text(
                store.heroSubtitle,
                style: V2Text.body.copyWith(color: V2Colors.ink, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final stat in store.heroStats)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // U+2212(−) 등 번들 폰트에 없는 기호는 ASCII로 정규화해 두부를 막는다.
                      Text(stat.$1.replaceAll('−', '-'), style: V2Text.title.copyWith(color: V2Colors.goldLight, fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(stat.$2, style: V2Text.body.copyWith(color: V2Colors.tealInk, fontSize: 11)),
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
            Container(
              padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
              decoration: BoxDecoration(
                color: V2Colors.cream,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: V2Colors.creamBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  V2AttributeBadge(categoryKey: _categoryKeyOf(c), size: 22),
                  const SizedBox(width: 7),
                  Text(c.name, style: V2Text.body.copyWith(color: V2Colors.ink, fontSize: 12.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _categoryKeyOf(CategoryItem c) => _normalizeCategoryKey(c.id.isEmpty ? c.name : c.id);
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
                  border: Border.all(color: V2Colors.goldDark),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(b, style: V2Text.body.copyWith(color: V2Colors.ink, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }
}

/// 푸터 — 카드 하단 저작권 라인 패러디.
class V2Footer extends StatelessWidget {
  const V2Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(V2Space.pad, 24, V2Space.pad, 0),
      child: Row(
        children: [
          V2SetCode('55144522'),
          Spacer(),
          V2SetCode('© 욕망의 항아리 · TCG EDITION'),
        ],
      ),
    );
  }
}
