part of '../main.dart';

// 상품 상세로 이동. 라우터가 있으면 딥링크 가능한 /product/:id 로 push하고,
// (단독 위젯 테스트처럼) 라우터가 없으면 로컬 Navigator로 폴백한다.
void openProductDetail(BuildContext context, ProductItem product) {
  if (GoRouter.maybeOf(context) != null) {
    context.push('/product/${product.id}', extra: product);
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({required this.bottomPadding, super.key});
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('home-tab'),
      slivers: [
        const SliverToBoxAdapter(child: Header()),
        const SliverToBoxAdapter(child: SearchBarBlock()),
        const SliverToBoxAdapter(child: CategoryNav()),
        const SliverToBoxAdapter(child: HeroBlock()),
        const SliverToBoxAdapter(child: TickerStrip()),
        const SliverToBoxAdapter(child: CategorySection()),
        const SliverToBoxAdapter(child: DealSection()),
        const SliverToBoxAdapter(child: ProductSection()),
        const SliverToBoxAdapter(child: BrandSection()),
        const SliverToBoxAdapter(child: NewsletterSection()),
        const SliverToBoxAdapter(child: FooterSection()),
        SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
      ],
    );
  }
}
class Header extends StatelessWidget {
  const Header({super.key});

  void _openMenu(BuildContext context) {
    final navigation = AppNavigationScope.maybeOf(context);
    final currentTab = navigation?.currentTab ?? 0;
    void selectTab(int index) => navigation?.selectTab(index);

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '메뉴 닫기',
      // 기본 배리어는 투명 — 어둡게 하는 처리는 헤더 아래 영역만 커스텀 dim으로 직접
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, __) {
        void choose(int index) {
          Navigator.of(dialogContext).pop();
          selectTab(index);
        }

        final reveal = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

        const items = [
          (Icons.home_outlined, '홈', 0),
          (Icons.grid_view_outlined, '카테고리', 1),
          (Icons.search, '검색', 2),
          (Icons.favorite_border, '찜', 3),
          (Icons.shopping_cart_outlined, '장바구니', 4),
        ];

        return Stack(
          children: [
            // 상단 타이틀(헤더) 영역은 어둡게 하지 않고, 그 아래 공간만 어둡게 — 탭은 배리어로 통과시켜 닫기 유지
            Positioned.fill(
              child: IgnorePointer(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppLayout.headerHeight),
                    child: Container(color: Colors.black54),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Material(
                type: MaterialType.transparency,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    // 상단 타이틀 구간(헤더) 아래로 내려오도록 헤더 높이만큼 띄워 일체감 확보
                    padding: const EdgeInsets.only(top: AppLayout.headerHeight),
                // 헤더 하단 라인을 전경에 항상 고정 — 이 라인에서 메뉴가 빠져나오는 것처럼
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.line, width: AppStroke.hair)),
                  ),
                  // 헤더 하단 라인에서부터 말려 내려오는 효과: 패널을 잘라낸 뒤 위에서 아래로 슬라이드
                  child: ClipRect(
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(reveal),
                      child: Container(
                      key: const ValueKey('menuDropdown'),
                      width: double.infinity,
                      // 상단 바와 일체화: 좌우/상단 여백 없이 풀폭, 하단 경계선만(바가 아래로 확장된 느낌)
                      decoration: const BoxDecoration(
                        color: AppColors.bg,
                        border: Border(bottom: BorderSide(color: AppColors.line, width: AppStroke.hair)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(AppSpace.pad, 16, AppSpace.pad, 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: MonoText('MENU', size: 12, color: AppColors.ink3, weight: FontWeight.w700),
                            ),
                          ),
                          for (final item in items)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => choose(item.$3),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad, vertical: 16),
                                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.lineSoft, width: AppStroke.hair))),
                                child: Row(
                                  children: [
                                    Icon(item.$1, size: 23, color: item.$3 == currentTab ? AppColors.accent : AppColors.ink3),
                                    const SizedBox(width: 14),
                                    Text(item.$2, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: item.$3 == currentTab ? AppColors.accent : AppColors.ink)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
            ),
            ),
          ],
        );
      },
      transitionBuilder: (_, animation, __, child) {
        // 슬라이드는 헤더 라인 아래 ClipRect 안에서 처리하므로, 여기선 가벼운 페이드만
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 그리기는 디자인 시스템(DoguHeaderBar), 장바구니 수·탭 이동·메뉴는 앱이 연결한다.
    final cartCount = AppStateScope.watch(context).cartCount;
    return DoguHeaderBar(
      cartBadge: cartCount > 0 ? cartCount.toString() : null,
      onMenu: () => _openMenu(context),
      onSearch: () => AppNavigationScope.select(context, 2),
      onCart: () => AppNavigationScope.select(context, 4),
    );
  }
}


class SearchBarBlock extends StatelessWidget {
  const SearchBarBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 12, AppSpace.pad, 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => AppNavigationScope.select(context, 2),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.bgAlt,
            border: Border.all(color: AppColors.line, width: AppStroke.hair),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, size: 16, color: AppColors.accent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '찾고 싶은 욕망을 입력하세요',
                  style: TextStyle(fontSize: 13, color: AppColors.ink4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryNav extends StatelessWidget {
  const CategoryNav({super.key});

  /// 가운데 카테고리 칸 수 — 메인 '카테고리' 칸과 같은 기준(수요 순위)의 상위 몇 개.
  /// 따로 관리하는 목록이 없어 데이터가 바뀌면 같이 바뀐다(예전엔 백엔드에 없는 옛 키였다).
  static const categorySlots = 4;

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final currentFilter = store.categoryQuickFilter;
    final currentCategory = store.selectedCategoryKey;
    // (라벨, 퀵필터, 카테고리 키)
    final entries = <(String, String, String?)>[
      ('신상품', 'new', null),
      ('베스트', 'best', null),
      if (!store.catalogLoading)
        for (final item in homeCategories(store.categories).take(categorySlots))
          (item.name, 'all', _normalizeCategoryKey(item.id.isEmpty ? item.name : item.id)),
      ('SALE', 'sale', null),
    ];
    // 그리기(구분선·활성 표시·로딩 자리)는 디자인 시스템(DoguNavBar). 백엔드 응답 전엔 카테고리 칸 자리에 로딩 점.
    return DoguNavBar(
      items: [
        for (final entry in entries)
          DoguNavItem(label: entry.$1, sale: entry.$2 == 'sale', active: entry.$2 == currentFilter && entry.$3 == currentCategory),
      ],
      loadingIndex: store.catalogLoading ? 2 : null,
      onTap: (i) {
        final entry = entries[i];
        AppStateScope.read(context).setCategoryQuickFilter(entry.$2);
        AppStateScope.read(context).selectCategoryBrowse(entry.$3);
        AppNavigationScope.select(context, 1);
      },
    );
  }
}


class HeroBlock extends StatelessWidget {
  const HeroBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    // 시안(03 gilded-beast)의 광고 무대 — 가운데 맞춤으로 'DESIRE' 워드마크, 그 아래를 덮는 항아리 메달,
    // 태그라인, 그리고 백엔드 문구는 크림색 한글로 작게. 금 글씨는 라틴 세리프에만 쓴다.
    return SectionBorder(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.heroBg,
          gradient: RadialGradient(
            center: Alignment(0, -0.75),
            radius: 1.1,
            colors: [Color(0x1fefd493), Color(0x00efd493)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(AppSpace.pad, 24, AppSpace.pad, 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final wordSize = DesireWordmark.sizeFor(width);
            final medalWidth = (width * 0.66).clamp(210.0, 400.0);
            final medalHeight = medalWidth / DoguMedal.aspect + 12; // 금테 두 겹
            final overlap = wordSize * 0.2; // 메달이 워드마크 아랫단을 덮는다
            return Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    Tag(text: store.heroEyebrow, dark: true),
                    if (store.heroDate.isNotEmpty) MonoText(store.heroDate, size: 10.5, color: AppColors.heroInk3),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: wordSize * 0.95 + medalHeight - overlap,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      DesireWordmark(size: wordSize),
                      Positioned(top: wordSize * 0.95 - overlap, child: DoguMedal(width: medalWidth)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const _HeroTagline(),
                const SizedBox(height: 16),
                Text(
                  store.heroTitle.replaceFirst(', ', ',\n'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: doguFontFamily, color: AppColors.ink, fontSize: 18, height: 1.45, fontWeight: FontWeight.w500, letterSpacing: -0.3),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Text(store.heroSubtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.heroInk3, height: 1.6)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 200),
                      child: AppButton(text: store.heroPrimaryAction, primary: true, large: true, onDark: true, onTap: () => AppNavigationScope.select(context, 1)),
                    ),
                    const SizedBox(width: 8),
                    AppButton(text: store.heroSecondaryAction, large: true, onDark: true, onTap: () => AppNavigationScope.select(context, 2)),
                  ],
                ),
                // 숫자는 백엔드가 DB에서 계산한다 — 응답 전엔 같은 틀의 로딩 자리, 없으면(오프라인) 숨김.
                // 넓은 화면에서도 숫자 띠·추천 카드는 가운데 640폭 — 광고의 가운데 축을 지킨다.
                if (store.catalogLoading || store.heroStats.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: StatGrid(stats: store.heroStats, dark: true, loading: store.catalogLoading),
                  ),
                ],
                if (store.featuredProduct != null) ...[
                  const SizedBox(height: 18),
                  ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: const FeaturedCard()),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 'Satisfying ✦ Every ✦ Craving' — 엠블럼에 새겨진 문구를 이탤릭 세리프로.
class _HeroTagline extends StatelessWidget {
  const _HeroTagline();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: doguSerifFontFamily,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w700,
      fontSize: 19,
      color: AppColors.ink,
      letterSpacing: 0.4,
    );
    const words = ['Satisfying', 'Every', 'Craving'];
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      children: [
        for (var i = 0; i < words.length; i++) ...[
          if (i > 0) const GoldSparkle(size: 11),
          Text(words[i], style: style),
        ],
      ],
    );
  }
}

/// 광고 아래 추천 상품 한 줄 — 작은 사진 + 이름·가격(예전엔 화면 폭만 한 4:5 사진이었다).
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key});

  static const _thumb = 84.0;

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final featured = store.featuredProduct;
    Widget frame({required Widget thumb, required Widget body}) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.deep, border: Border.all(color: AppColors.accentDeep, width: AppStroke.hair)),
        child: Row(
          children: [
            SizedBox(width: _thumb, height: _thumb, child: thumb),
            const SizedBox(width: 14),
            Expanded(child: body),
          ],
        ),
      );
    }

    if (store.catalogLoading) {
      // 백엔드 응답 전엔 seed 상품(이미지 없음) 대신 같은 틀의 로딩 자리 — 응답 뒤 크기가 같다.
      return frame(
        thumb: const NeutralImageSurface(child: Center(child: LoadingDots())),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 9, width: 72, color: AppColors.lineSoft),
            const SizedBox(height: 8),
            Container(height: 12, width: 150, color: AppColors.lineSoft),
            const SizedBox(height: 8),
            Container(height: 12, width: 90, color: AppColors.lineSoft),
          ],
        ),
      );
    }
    if (featured == null) {
      return frame(thumb: const NeutralImageSurface(), body: const SizedBox.shrink());
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openProductDetail(context, featured),
      child: frame(
        thumb: ProductImageSurface(
          pattern: featured.pattern,
          imageUrl: featured.imageUrl,
          artwork: featured.artwork,
          thumbnailWidth: 300,
          child: featured.badge == null
              ? null
              : Positioned(top: 4, left: 4, child: BadgePill(text: featured.badge!, color: AppColors.accent, compact: true)),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MonoText('No.001 · FEATURED', size: 9, color: AppColors.accent, weight: FontWeight.w600),
            const SizedBox(height: 5),
            Text(featured.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w500, color: AppColors.ink)),
            const SizedBox(height: 2),
            MonoText(featured.brand, size: 10, color: AppColors.ink4, maxLines: 1),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PriceText(featured.price, size: 16, color: AppColors.accentBright),
                if (featured.hasDiscount) ...[
                  PriceText(featured.discount, size: 11, color: AppColors.alertBright),
                  StrikeText(featured.oldPrice, size: 10),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TickerStrip extends StatefulWidget {
  const TickerStrip({super.key});

  @override
  State<TickerStrip> createState() => _TickerStripState();
}

class _TickerStripState extends State<TickerStrip> {
  final ScrollController _sc = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  void _startScroll() {
    if (!mounted || !_sc.hasClients) return;
    final half = _sc.position.maxScrollExtent;
    if (half <= 0) return;
    // 28초 주기, 50ms 간격으로 위치를 직접 이동
    // animateTo 대신 jumpTo를 사용해 테스트의 pumpAndSettle과 충돌하지 않음
    const intervalMs = 50;
    final step = half * intervalMs / 28000;
    _timer = Timer.periodic(const Duration(milliseconds: intervalMs), (_) {
      if (!mounted || !_sc.hasClients) return;
      var next = _sc.offset + step;
      if (next >= half) next -= half;
      _sc.jumpTo(next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const items = ['FREE SHIPPING', '14-DAY RETURNS', '매일 오후 2시 신상', '12개월 할부', '리퍼브 · 빈티지'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        color: AppColors.deep,
        border: Border(bottom: BorderSide(color: AppColors.accentDeep, width: AppStroke.hair)),
      ),
      child: SingleChildScrollView(
        controller: _sc,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            const SizedBox(width: AppSpace.pad),
            for (final item in [...items, ...items]) ...[
              MonoText(item, size: 10.5, color: AppColors.accent, weight: FontWeight.w600),
              // 금 마름모
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 22),
                child: Transform.rotate(angle: pi / 4, child: Container(width: 4, height: 4, color: AppColors.accentDeep)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 메인화면 '카테고리' 칸에 그릴 카테고리 — 백엔드가 featured로 고른 것만, 노출 순위
/// (수요 순)대로 최대 9개. 순위가 없으면(번들 seed) 받은 순서 그대로, featured가 하나도
/// 없으면(구 백엔드 응답) 앞에서부터 9개. 카테고리 탭은 전부를 가나다순으로 그린다.
List<CategoryItem> homeCategories(List<CategoryItem> all) {
  final featured = all.indexed.where((entry) => entry.$2.featured).toList();
  if (featured.isEmpty) return all.take(homeCategorySlots).toList();
  const unranked = 1 << 30;
  featured.sort((a, b) {
    final byRank = (a.$2.homeRank ?? unranked).compareTo(b.$2.homeRank ?? unranked);
    return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
  });
  return featured.map((entry) => entry.$2).take(homeCategorySlots).toList();
}

const homeCategorySlots = 9;

const _categoryGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 160,
  mainAxisExtent: 58,
  mainAxisSpacing: 8,
  crossAxisSpacing: 8,
);

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final items = homeCategories(store.categories);
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        children: [
          SectionHead(index: '01', eyebrow: 'SHOP BY CATEGORY', title: '카테고리', link: '전체 →', onLinkTap: () => AppNavigationScope.select(context, 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad),
            child: store.catalogLoading
                // 백엔드 응답 전에는 번들 seed 카테고리(옛 6개)를 그리지 않는다 — 빠르게 넘기는
                // 사용자가 곧 바뀔 칸을 누르지 않게. 9칸 격자 자리를 그대로 비워 두어 응답 뒤
                // 카테고리가 나타날 때 아래 내용이 밀리지 않는다.
                ? Stack(
                    key: const ValueKey('category-loading'),
                    alignment: Alignment.center,
                    children: [
                      GridView.builder(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: homeCategorySlots,
                        gridDelegate: _categoryGridDelegate,
                        itemBuilder: (context, index) => const SizedBox.shrink(),
                      ),
                      const LoadingDots(),
                    ],
                  )
                : GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: items.length,
                    gridDelegate: _categoryGridDelegate,
                    itemBuilder: (context, index) => CategoryCard(index: index + 1, item: items[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({required this.index, required this.item, super.key});
  final int index;
  final CategoryItem item;

  String? _categoryKey() {
    switch (item.name) {
      case '의류':
        return 'clothing';
      case '홈·리빙':
        return 'home';
      case '전자제품':
        return 'tech';
      case '뷰티':
        return 'beauty';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 그리기는 디자인 시스템(CategoryTile), 고르면 카테고리 탭으로 가는 건 앱이 연결한다.
    return CategoryTile(
      index: index,
      name: item.name,
      onTap: () {
        AppStateScope.read(context).setCategoryQuickFilter('all');
        AppStateScope.read(context).selectCategoryBrowse(item.id.isEmpty ? _categoryKey() : _normalizeCategoryKey(item.id));
        AppNavigationScope.select(context, 1);
      },
    );
  }
}


class DealSection extends StatelessWidget {
  const DealSection({super.key});

  static const int _initialCountdownSeconds = (7 * 60 * 60) + (42 * 60) + 18;

  /// 딜 카드 폭 — 격자 카드와 같은 크기라 휴대폰에서 2장 반이 보여 옆으로 넘길 수 있음을 알린다.
  static const cardWidth = 132.0;

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final items = store.dealProducts;
    if (items.isEmpty && !store.catalogLoading) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: const BoxDecoration(
        color: AppColors.deep,
        border: Border(top: BorderSide(color: AppColors.accentDeep, width: AppStroke.hair), bottom: BorderSide(color: AppColors.accentDeep, width: AppStroke.hair)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 마감 시계(빨간 면)는 줄지 않고, 좁은 폭에선 제목 쪽이 줄어든다.
          const SectionHead(index: '02', eyebrow: 'TODAY ONLY', title: '오늘의 딜', trailing: CountdownTimer(initialSeconds: _initialCountdownSeconds)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 백엔드 응답 전엔 seed 상품 대신 스켈레톤 — 빠르게 넘기다 곧 바뀔 카드를 누르지 않게.
                if (store.catalogLoading)
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpace.gutter),
                    const SizedBox(width: cardWidth, child: SkeletonProductCard(dark: true)),
                  ]
                else
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpace.gutter),
                    SizedBox(width: cardWidth, child: ProductCard(product: items[i], dark: true)),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductSection extends StatelessWidget {
  const ProductSection({super.key});

  /// 처음 보이는 수 — 3열(휴대폰)·4열(넓은 화면) 어느 쪽에서도 줄이 꽉 차는 12.
  static const initialVisibleCount = 12;
  static const loadMoreCount = 12;

  @override
  Widget build(BuildContext context) {
    return const ProductSectionContent();
  }
}

class ProductSectionContent extends StatefulWidget {
  const ProductSectionContent({super.key});

  @override
  State<ProductSectionContent> createState() => _ProductSectionContentState();
}

class _ProductSectionContentState extends State<ProductSectionContent> {
  int _visibleCount = ProductSection.initialVisibleCount;

  void _showMore(int total) {
    setState(() {
      _visibleCount = (_visibleCount + ProductSection.loadMoreCount).clamp(0, total).toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    const head = SectionHead(index: '03', eyebrow: 'NEW ARRIVALS', title: '이번 주 신상품');

    // 번들 seed를 읽기 전, 그리고 백엔드 응답 전 — seed 상품 대신 스켈레톤.
    if (store.usingFallback || store.catalogLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 36),
        child: Column(
          children: [
            head,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad),
              child: CardGrid(children: [for (var i = 0; i < ProductSection.initialVisibleCount; i++) const SkeletonProductCard()]),
            ),
          ],
        ),
      );
    }

    final newProds = store.newProducts;
    final newIds = newProds.map((p) => p.id).toSet();
    final supplement = store.catalogProducts.where((p) => !newIds.contains(p.id)).toList();
    final items = [...newProds, ...supplement];
    final visibleItems = items.take(_visibleCount).toList();
    final hasMore = visibleItems.length < items.length;
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        children: [
          // 카테고리 필터 칩(의류·홈·테크·뷰티)은 뺐다 — 백엔드에 없는 옛 키라 실제 상품에선 항상 비었고,
          // 신상품 태그가 DB 전체에 6개뿐이라 카테고리별 신상품으로 바꿀 수도 없다.
          head,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad),
            child: CardGrid(children: [for (final product in visibleItems) ProductCard(product: product)]),
          ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.pad, 26, AppSpace.pad, 0),
              child: AppButton(text: '더 보기  +${ProductSection.loadMoreCount}', large: true, onTap: () => _showMore(items.length)),
            ),
        ],
      ),
    );
  }
}

class ProductImageSurface extends StatelessWidget {
  const ProductImageSurface({required this.pattern, this.imageUrl, this.artwork, this.child, this.dark = false, this.thumbnailWidth, super.key});

  final PatternKind pattern;
  final String? imageUrl;
  /// 목록·썸네일이면 축소본 너비(300/640, ApiConfig.thumbnailWidths). null이면 원본(상세).
  final int? thumbnailWidth;
  final ProductArtwork? artwork;
  final Widget? child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    // 그리기는 디자인 시스템(ProductImage)이, 주소 규칙(프록시·축소본)은 앱이 맡는다.
    return ProductImage(url: ApiConfig.displayImageUrl(imageUrl, thumbnailWidth: thumbnailWidth), dark: dark, child: child);
  }
}


class RemoteNeutralImageSurface extends StatelessWidget {
  const RemoteNeutralImageSurface({this.imageUrl, this.child, super.key});

  final String? imageUrl;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl?.trim();
    final fallback = NeutralImageSurface(child: child);
    if (trimmedUrl == null || trimmedUrl.isEmpty || !ApiConfig.canLoadImageDirectly(trimmedUrl)) return fallback;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.line, width: AppStroke.hair),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            ApiConfig.imageUrl(trimmedUrl),
            fit: BoxFit.cover,
            loadingBuilder: (context, childWidget, loadingProgress) {
              if (loadingProgress == null) return childWidget;
              return fallback;
            },
            errorBuilder: (context, error, stackTrace) => fallback,
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// 상품 카드 — 찜 상태·상세 열기·찜 토글을 연결하고, 그리기는 디자인 시스템의 ProductCardView가 맡는다.
class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, this.dark = false, super.key});
  final ProductItem product;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final wished = AppStateScope.watch(context).wishlistIds.contains(product.id);
    return ProductCardView(
      data: ProductCardData(
        brand: product.brand,
        name: product.name,
        price: product.price,
        oldPrice: product.oldPrice,
        discount: product.discount,
        hasDiscount: product.hasDiscount,
        badge: product.badge,
        subtitle: product.subtitle,
        meta: product.meta,
        imageUrl: ApiConfig.displayImageUrl(product.imageUrl, thumbnailWidth: 640),
      ),
      wished: wished,
      dark: dark,
      onTap: () => openProductDetail(context, product),
      onWishTap: () => AppStateScope.read(context).toggleWishlist(product),
    );
  }
}

