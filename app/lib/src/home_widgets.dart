part of '../main.dart';

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
                    padding: const EdgeInsets.only(top: AppSpace.headerHeight),
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
                    padding: const EdgeInsets.only(top: AppSpace.headerHeight),
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
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/logo-square.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 9),
                const Text(
                  '욕망의 장바구니',
                  style: TextStyle(
                    fontFamily: doguHeroFontFamily,
                    fontFamilyFallback: [doguFontFamily],
                    color: AppColors.accent,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
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

class IconBox extends StatelessWidget {
  const IconBox({
    required this.icon,
    required this.label,
    this.inverted = false,
    this.count,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool inverted;
  final String? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: inverted ? AppColors.accent : AppColors.bg,
                  border: Border.all(color: inverted ? AppColors.accent : AppColors.line),
                ),
                child: Icon(icon, size: 18, color: inverted ? AppColors.invert : AppColors.ink),
              ),
              if (count != null)
                Positioned(
                  top: -5,
                  right: -1,
                  child: BadgePill(text: count!, color: AppColors.alert, compact: true),
                ),
            ],
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    const items = ['신상품', '베스트', '의류', '홈·리빙', '전자제품', '뷰티', 'SALE'];
    const mappings = <String, (String, String?)>{
      '신상품': ('new', null),
      '베스트': ('best', null),
      '의류': ('all', 'clothing'),
      '홈·리빙': ('all', 'home'),
      '전자제품': ('all', 'tech'),
      '뷰티': ('all', 'beauty'),
      'SALE': ('sale', null),
    };
    final store = AppStateScope.watch(context);
    final currentFilter = store.categoryQuickFilter;
    final currentCategory = store.selectedCategoryKey;
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 12, AppSpace.pad, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final mapping = mappings[items[i]]!;
                  AppStateScope.read(context).setCategoryQuickFilter(mapping.$1);
                  AppStateScope.read(context).selectCategoryBrowse(mapping.$2);
                  AppNavigationScope.select(context, 1);
                },
                child: NavLabel(
                  text: items[i],
                  sale: items[i] == 'SALE',
                  active: mappings[items[i]]!.$1 == currentFilter &&
                      mappings[items[i]]!.$2 == currentCategory,
                ),
              ),
              if (i != items.length - 1)
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

class NavLabel extends StatelessWidget {
  const NavLabel({required this.text, this.active = false, this.sale = false, super.key});
  final String text;
  final bool active;
  final bool sale;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: sale ? FontWeight.w700 : FontWeight.w500,
            color: sale ? AppColors.accent : (active ? AppColors.ink : AppColors.ink3),
          ),
        ),
        const SizedBox(height: 14),
        Container(width: active ? 42 : 0, height: 2, color: active ? AppColors.ink : Colors.transparent),
      ],
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
                const SizedBox(width: 10),
                MonoText(store.heroDate, size: 10.5, color: AppColors.heroInk3),
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
            const SizedBox(height: 28),
            StatGrid(stats: store.heroStats, dark: true),
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

class StatGrid extends StatelessWidget {
  const StatGrid({required this.stats, this.dark = false, super.key});

  final List<(String, String)> stats;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final lineColor = dark ? AppColors.heroLine : AppColors.line;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: lineColor), bottom: BorderSide(color: lineColor)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++)
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 12, right: 8),
                decoration: BoxDecoration(
                  border: i == 0 ? null : Border(left: BorderSide(color: lineColor)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoText(stats[i].$1, size: 20, weight: FontWeight.w500, color: dark ? AppColors.heroInk : AppColors.ink),
                    const SizedBox(height: 2),
                    MonoText(stats[i].$2, size: 10.5, color: dark ? AppColors.heroInk3 : AppColors.ink4),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final featured = AppStateScope.watch(context).featuredProduct;
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(
                      product: featured,
                      onGoToCart: () => AppNavigationScope.select(context, 4),
                    ),
                  ),
                );
              },
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

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = AppStateScope.watch(context).categories;
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        children: [
          SectionHead(index: '01', eyebrow: 'SHOP BY CATEGORY', title: '카테고리', link: '전체 →', onLinkTap: () => AppNavigationScope.select(context, 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: items.length > 9 ? 9 : items.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisExtent: 72,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
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
            Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            MonoText(item.count, size: 8.5, color: AppColors.ink3),
          ],
        ),
      ),
    );
  }
}

// 매초 카운트다운 텍스트만 업데이트 — DealSection 전체 rebuild 방지
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({required this.initialSeconds, super.key});
  final int initialSeconds;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late final ValueNotifier<int> _seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _seconds = ValueNotifier(widget.initialSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds.value > 0) _seconds.value -= 1;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _seconds.dispose();
    super.dispose();
  }

  static String _format(int total) {
    final h = (total ~/ 3600).toString().padLeft(2, '0');
    final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _seconds,
      builder: (_, remaining, __) =>
          MonoText(_format(remaining), size: 18, color: AppColors.invert, weight: FontWeight.w600),
    );
  }
}

class DealSection extends StatelessWidget {
  const DealSection({super.key});

  static const int _initialCountdownSeconds = (7 * 60 * 60) + (42 * 60) + 18;

  @override
  Widget build(BuildContext context) {
    final items = AppStateScope.watch(context).dealProducts;
    if (items.isEmpty) return const SizedBox.shrink();
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
  String _activeFilter = 'all';

  List<ProductItem> _filterProducts(List<ProductItem> items) {
    if (_activeFilter == 'all') return items;
    return items.where((item) => item.categoryKey == _activeFilter).toList();
  }

  void _showMore(int total) {
    setState(() {
      _visibleCount = (_visibleCount + ProductSection.loadMoreCount).clamp(0, total).toInt();
    });
  }

  void _selectFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      _visibleCount = ProductSection.initialVisibleCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);

    if (store.usingFallback) {
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
    final filteredItems = _filterProducts(items);
    final visibleItems = filteredItems.take(_visibleCount).toList();
    final hasMore = visibleItems.length < filteredItems.length;
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        children: [
          const SectionHead(index: '03', eyebrow: 'NEW ARRIVALS', title: '이번 주 신상품'),
          ChipRow(activeFilter: _activeFilter, onSelected: _selectFilter),
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
              child: AppButton(text: '더 보기  +8', large: true, onTap: () => _showMore(filteredItems.length)),
            ),
        ],
      ),
    );
  }
}

class ChipRow extends StatelessWidget {
  const ChipRow({required this.activeFilter, required this.onSelected, super.key});

  final String activeFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const chips = [
      ('전체', 'all'),
      ('의류', 'clothing'),
      ('홈', 'home'),
      ('테크', 'tech'),
      ('뷰티', 'beauty'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 0, AppSpace.pad, 16),
      child: Row(
        children: [
          for (final chip in chips)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(chip.$2),
              child: Container(
                height: 30,
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: chip.$2 == activeFilter ? AppColors.accent : AppColors.bg,
                  border: Border.all(color: chip.$2 == activeFilter ? AppColors.accent : AppColors.line),
                ),
                child: Text(chip.$1, style: TextStyle(fontSize: 12, color: chip.$2 == activeFilter ? AppColors.invert : AppColors.ink2)),
              ),
            ),
        ],
      ),
    );
  }
}

class ProductImageSurface extends StatelessWidget {
  const ProductImageSurface({required this.pattern, this.imageUrl, this.artwork, this.child, this.dark = false, super.key});

  final PatternKind pattern;
  final String? imageUrl;
  final ProductArtwork? artwork;
  final Widget? child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl?.trim();
    // 이미지 로딩 전/실패/부재 시 모두 통일된 "준비 이미지"를 보여준다(랜덤 패턴 배경 제거).
    final preparing = PreparingImageSurface(dark: dark, child: child);
    if (trimmedUrl == null || trimmedUrl.isEmpty || !ApiConfig.canLoadImageDirectly(trimmedUrl)) {
      return preparing;
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: dark ? const Color(0xff1f1f1f) : AppColors.line)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            ApiConfig.imageUrl(trimmedUrl),
            fit: BoxFit.cover,
            loadingBuilder: (context, childWidget, loadingProgress) {
              if (loadingProgress == null) return childWidget;
              return preparing;
            },
            errorBuilder: (context, error, stackTrace) => preparing,
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

// 통일된 "준비 이미지" placeholder — 모든 상품 이미지 로딩 전/실패 시 동일하게 표시
class PreparingImageSurface extends StatelessWidget {
  const PreparingImageSurface({this.child, this.dark = false, super.key});

  final Widget? child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xff151515) : AppColors.bgAlt,
        border: Border.all(color: dark ? const Color(0xff2a2a2a) : AppColors.line),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: dark ? 0.4 : 0.5,
                child: Image.asset('assets/logo-square.png', width: 44, height: 44, fit: BoxFit.cover),
              ),
              const SizedBox(height: 10),
              MonoText('이미지 준비 중', size: 9.5, color: dark ? const Color(0xff6a6a6a) : AppColors.ink4),
            ],
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class NeutralImageSurface extends StatelessWidget {
  const NeutralImageSurface({this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.line),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Opacity(
              opacity: 0.14,
              child: Image.asset(
                'assets/logo-square.png',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
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

class ProductCard extends StatefulWidget {
  const ProductCard({required this.product, this.dark = false, super.key});
  final ProductItem product;
  final bool dark;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _pressed = false;

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: widget.product,
          onGoToCart: () => AppNavigationScope.select(context, 4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final wished = store.wishlistIds.contains(widget.product.id);
    final product = widget.product;
    final dark = widget.dark;
    final line = dark ? const Color(0xff1f1f1f) : AppColors.line;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openDetail(context),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ProductImageSurface(
              pattern: product.pattern,
              imageUrl: product.imageUrl,
              artwork: product.artwork,
              dark: dark,
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.hasDiscount)
                          BadgePill(text: product.discount, color: dark ? AppColors.accent : AppColors.ink),
                        if (product.badge != null) ...[
                          const SizedBox(height: 3),
                          BadgePill(text: product.badge!, color: dark ? const Color(0xff1a1a1a) : AppColors.bg, ink: dark ? AppColors.invert : AppColors.ink, bordered: true),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: line),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonoText(product.brand, size: 9.5, color: dark ? const Color(0xff7a7a7a) : AppColors.ink4),
                const SizedBox(height: 3),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, height: 1.35, color: dark ? AppColors.invert : AppColors.ink, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 7),
                if (product.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(product.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: dark ? const Color(0xff9a9a9a) : AppColors.ink3)),
                  ),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (product.hasDiscount)
                      MonoText(product.discount, size: 12, color: AppColors.accent, weight: FontWeight.w700),
                    MonoText(product.price, size: 13, color: dark ? AppColors.invert : AppColors.ink, weight: FontWeight.w700),
                    if (product.hasDiscount) StrikeText(product.oldPrice),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: MonoText(product.meta, size: 9.5, color: dark ? const Color(0xff6a6a6a) : AppColors.ink4),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => AppStateScope.read(context).toggleWishlist(product),
                      child: MonoText(wished ? 'WISH ♥' : 'WISH +', size: 9.5, color: wished ? AppColors.accent : (dark ? const Color(0xff6a6a6a) : AppColors.ink4)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),    // Column
    ),    // GestureDetector
  );    // AnimatedScale
  }
}

