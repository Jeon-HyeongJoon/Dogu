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
                    border: Border(top: BorderSide(color: AppColors.line)),
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
                        border: Border(bottom: BorderSide(color: AppColors.line)),
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
                                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.lineSoft))),
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
    final cartCount = AppStateScope.watch(context).cartCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 10, AppSpace.pad, 4),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          IconBox(icon: Icons.menu, label: '메뉴', onTap: () => _openMenu(context)),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                // 락업(마크 크기·오프셋)은 DoguBrandLockup에 있다 — 푸터와 공유.
                // 헤더에 위젯을 더 추가하지 말 것: 좁은 뷰포트에서 오버플로한다.
                DoguBrandLockup(),
              ],
            ),
          ),
          Row(
            children: [
              IconBox(icon: Icons.search, label: '검색', onTap: () => AppNavigationScope.select(context, 2)),
              const SizedBox(width: 8),
              IconBox(icon: Icons.shopping_cart_outlined, label: '장바구니', inverted: true, count: cartCount > 0 ? cartCount.toString() : null, onTap: () => AppNavigationScope.select(context, 4)),
            ],
          ),
        ],
      ),
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
            color: AppColors.bgSoft,
            border: Border.all(color: AppColors.line),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, size: 16, color: AppColors.ink3),
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
    final cells = <Widget>[
      for (final entry in entries)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppStateScope.read(context).setCategoryQuickFilter(entry.$2);
            AppStateScope.read(context).selectCategoryBrowse(entry.$3);
            AppNavigationScope.select(context, 1);
          },
          child: NavLabel(
            text: entry.$1,
            sale: entry.$2 == 'sale',
            active: entry.$2 == currentFilter && entry.$3 == currentCategory,
          ),
        ),
    ];
    // 백엔드 응답 전엔 카테고리 칸 자리에 로딩 점(메인 카테고리 칸과 같은 이유).
    if (store.catalogLoading) cells.insert(2, const Padding(padding: EdgeInsets.only(top: 6), child: LoadingDots()));
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 12, AppSpace.pad, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              cells[i],
              if (i != cells.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 11),
                  child: Text('|', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300, color: AppColors.ink4)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}


class HeroBlock extends StatelessWidget {
  const HeroBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return SectionBorder(
      child: Container(
        color: AppColors.heroBg,
        padding: const EdgeInsets.fromLTRB(AppSpace.pad, 28, AppSpace.pad, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Tag(text: store.heroEyebrow, dark: true),
                if (store.heroDate.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  MonoText(store.heroDate, size: 10.5, color: AppColors.heroInk3),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Text(
              store.heroTitle.replaceFirst(', ', ',\n'),
              style: const TextStyle(
                fontFamily: doguFontFamily,
                color: Colors.white,
                fontSize: 44,
                height: 1.08,
                fontWeight: FontWeight.w400,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              store.heroSubtitle,
              style: const TextStyle(fontSize: 13.5, color: AppColors.heroInk2, height: 1.6),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: AppButton(text: store.heroPrimaryAction, primary: true, onDark: true, onTap: () => AppNavigationScope.select(context, 1))),
                const SizedBox(width: 8),
                AppButton(text: store.heroSecondaryAction, onDark: true, onTap: () => AppNavigationScope.select(context, 2)),
              ],
            ),
            // 숫자는 백엔드가 DB에서 계산한다 — 응답 전엔 같은 틀의 로딩 자리, 없으면(오프라인) 숨김.
            if (store.catalogLoading || store.heroStats.isNotEmpty) ...[
              const SizedBox(height: 28),
              StatGrid(stats: store.heroStats, dark: true, loading: store.catalogLoading),
            ],
            if (store.featuredProduct != null) ...[
              const SizedBox(height: 22),
              const FeaturedCard(),
            ],
          ],
        ),
      ),
    );
  }
}


class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final featured = store.featuredProduct;
    if (store.catalogLoading) {
      // 백엔드 응답 전엔 seed 상품(이미지 없음) 대신 같은 틀의 로딩 자리 — 응답 뒤 크기가 거의 같다.
      return Container(
        decoration: BoxDecoration(color: AppColors.bgAlt, border: Border.all(color: AppColors.line)),
        child: Column(
          children: [
            const AspectRatio(aspectRatio: 4 / 5, child: NeutralImageSurface(child: Center(child: LoadingDots()))),
            Container(height: 1, color: AppColors.line),
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                height: 37,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 13, width: 160, color: AppColors.line),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 72, color: AppColors.line),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (featured == null) {
      return Container(
        decoration: BoxDecoration(color: AppColors.bgAlt, border: Border.all(color: AppColors.line)),
        child: const AspectRatio(
          aspectRatio: 4 / 5,
          child: NeutralImageSurface(),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(color: AppColors.bgAlt, border: Border.all(color: AppColors.line)),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: ProductImageSurface(
              pattern: featured.pattern,
              imageUrl: featured.imageUrl,
              artwork: featured.artwork,
              thumbnailWidth: 640,
              child: Stack(
                children: [
                  const Positioned(top: 12, left: 12, child: MonoText('001 / FEATURED', size: 9.5, color: AppColors.ink3)),
                  if (featured.badge != null) Positioned(top: 12, right: 12, child: BadgePill(text: featured.badge!, color: AppColors.accent)),
                ],
              ),
            ),
          ),
          Container(height: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.all(14),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => openProductDetail(context, featured),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(featured.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        MonoText(featured.brand, size: 11, color: AppColors.ink3),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (featured.hasDiscount) StrikeText(featured.oldPrice),
                      MonoText(featured.price, size: 14.5, color: AppColors.accent, weight: FontWeight.w700),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
        color: AppColors.bgSoft,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: SingleChildScrollView(
        controller: _sc,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            const SizedBox(width: AppSpace.pad),
            for (final item in [...items, ...items]) ...[
              MonoText(item, size: 10.5, color: AppColors.ink2),
              Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 22), color: AppColors.ink3),
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
  mainAxisExtent: 72,
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppStateScope.read(context).setCategoryQuickFilter('all');
        AppStateScope.read(context).selectCategoryBrowse(item.id.isEmpty ? _categoryKey() : _normalizeCategoryKey(item.id));
        AppNavigationScope.select(context, 1);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MonoText(index.toString().padLeft(2, '0'), size: 8.5, color: AppColors.ink4),
            const SizedBox(height: 5),
            // 상품 수는 그리지 않는다 — 크롤링 한도 때문에 전부 ~100이라 의미가 없다.
            Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}


class DealSection extends StatelessWidget {
  const DealSection({super.key});

  static const int _initialCountdownSeconds = (7 * 60 * 60) + (42 * 60) + 18;

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final items = store.dealProducts;
    if (items.isEmpty && !store.catalogLoading) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 36),
      padding: const EdgeInsets.symmetric(vertical: 32),
      color: AppColors.ink,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(index: '02', text: 'TODAY ONLY', inverted: true),
                    Text('오늘의 딜', style: TextStyle(fontSize: 34, height: 1, color: AppColors.invert, fontWeight: FontWeight.w800, letterSpacing: -1.2)),
                  ],
                ),
                const CountdownTimer(initialSeconds: _initialCountdownSeconds),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad),
            child: Row(
              children: [
                // 백엔드 응답 전엔 seed 상품 대신 스켈레톤 — 빠르게 넘기다 곧 바뀔 카드를 누르지 않게.
                if (store.catalogLoading)
                  for (var i = 0; i < 3; i++) ...[
                    const SizedBox(width: 200, child: SkeletonProductCard(dark: true)),
                    const SizedBox(width: 12),
                  ]
                else
                  for (final product in items) ...[
                    SizedBox(width: 200, child: ProductCard(product: product, dark: true)),
                    const SizedBox(width: 12),
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

  static const initialVisibleCount = 8;
  static const loadMoreCount = 8;

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

    // 번들 seed를 읽기 전, 그리고 백엔드 응답 전 — seed 상품 대신 스켈레톤.
    if (store.usingFallback || store.catalogLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 36),
        child: Column(
          children: [
            const SectionHead(index: '03', eyebrow: 'NEW ARRIVALS', title: '이번 주 신상품'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.58,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 12,
                ),
                itemCount: ProductSection.initialVisibleCount,
                itemBuilder: (_, __) => const SkeletonProductCard(),
              ),
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
          const SectionHead(index: '03', eyebrow: 'NEW ARRIVALS', title: '이번 주 신상품'),
          Padding(
            // 좌우 AppSpace.pad만큼 들여쓰기 → 상품 이미지와 동일한 인셋
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad),
            child: Column(
              children: [
                for (var row = 0; row * 2 < visibleItems.length; row++) ...[
                  if (row > 0)
                    // 줄 구분 가로선: 상품 이미지가 양 끝에서 떨어진 만큼(좌우 패딩)만 차지
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, thickness: 1, color: AppColors.line),
                    ),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: ProductCard(product: visibleItems[row * 2])),
                        const SizedBox(width: 12),
                        Expanded(
                          child: row * 2 + 1 < visibleItems.length
                              ? ProductCard(product: visibleItems[row * 2 + 1])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.pad, 28, AppSpace.pad, 0),
              child: AppButton(text: '더 보기  +8', large: true, onTap: () => _showMore(items.length)),
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
        border: Border.all(color: AppColors.line),
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

