part of '../main.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({required this.product, this.onGoToCart, super.key});

  final ProductItem product;
  final VoidCallback? onGoToCart;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late ProductItem _product;
  bool _loading = false;
  bool _addedToCart = false;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() => _loading = true);
    try {
      final product = await AppStateScope.read(context).fetchProductDetail(widget.product.id);
      if (!mounted) return;
      setState(() => _product = product);
    } catch (_) {
      // Keep initial product as fallback.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeQuantity(int delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(1, 99);
    });
  }

  String _tagLabel(String tag) {
    switch (tag) {
      case 'today_deal': return '오늘의 딜';
      case 'new_arrival': return '신상품';
      default: return tag;
    }
  }

  Future<void> _addToCart() async {
    AppStateScope.read(context).cacheProduct(_product);
    await AppStateScope.read(context).changeCartQuantity(_product.id, _quantity);
    if (!mounted) return;
    setState(() => _addedToCart = true);
    AppStateScope.read(context).showCartToast('${_product.name} $_quantity개를 장바구니에 담았습니다.');
  }

  void _goToCart() {
    // 상세는 루트 네비게이터에 push된 라우트이므로 /cart로 이동하면 상세가 닫히고
    // 장바구니 탭이 열린다. 라우터가 없는 단독 테스트 환경에선 콜백으로 폴백한다.
    if (GoRouter.maybeOf(context) != null) {
      context.go('/cart');
      return;
    }
    widget.onGoToCart?.call();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final wished = store.wishlistIds.contains(_product.id);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('상품 정보', style: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppColors.ink),
        // 상품 주소로 바로 들어오면 돌아갈 화면이 없어 뒤로 버튼이 사라졌다 — 그때는 홈으로 보내는 뒤로 버튼을 둔다.
        leading: Navigator.of(context).canPop() || GoRouter.maybeOf(context) == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.go(kTabPaths.first),
              ),
      ),
      // 상품 주소로 바로 들어와 아직 정보가 없으면 로딩 → 실패 시 안내(엉뚱한 상품 대신).
      body: _product.isPending
          ? Center(
              child: _loading
                  ? const LoadingDots()
                  : const Text('상품 정보를 불러오지 못했어요', style: TextStyle(fontSize: 14, color: AppColors.ink3)),
            )
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              AspectRatio(
                aspectRatio: 1,
            child: ProductImageSurface(
              pattern: _product.pattern,
              imageUrl: _product.imageUrl,
              artwork: _product.artwork,
              child: Stack(
                    children: [
                      if (_loading)
                        const Positioned(
                          top: 16,
                          right: 16,
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.pad, 24, AppSpace.pad, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoText(_product.brand, size: 10.5, color: AppColors.ink4),
                    const SizedBox(height: 10),
                    Text(_product.name, style: const TextStyle(fontSize: 28, height: 1.08, letterSpacing: -0.8, fontWeight: FontWeight.w700)),
                    if (_product.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_product.subtitle, style: const TextStyle(fontSize: 13.5, color: AppColors.ink3, height: 1.5)),
                    ],
                    const SizedBox(height: 10),
                    Text('${_product.rating.toStringAsFixed(1)} · ${_product.reviews} reviews', style: const TextStyle(fontSize: 12.5, color: AppColors.ink3, height: 1.6)),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (_product.hasDiscount)
                          MonoText(_product.discount, size: 16, color: AppColors.accent, weight: FontWeight.w700),
                        MonoText(_product.price, size: 20, weight: FontWeight.w800),
                        if (_product.hasDiscount) StrikeText(_product.oldPrice),
                      ],
                    ),
                    if (_product.blurb.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.bgSoft, border: Border.all(color: AppColors.line)),
                        child: Text(_product.blurb, style: const TextStyle(fontSize: 13.5, color: AppColors.ink2, height: 1.65)),
                      ),
                    ],
                    if (_product.tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in _product.tags)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
                              child: MonoText(_tagLabel(tag), size: 10, color: AppColors.ink3),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    const MonoText('QUANTITY', size: 10, color: AppColors.ink4, weight: FontWeight.w700),
                    const SizedBox(height: 10),
                    QtyBox(value: _quantity.toString(), onMinus: () => _changeQuantity(-1), onPlus: () => _changeQuantity(1), buttonExtent: 56, valueExtent: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(AppSpace.pad, 12, AppSpace.pad, 16),
              decoration: const BoxDecoration(color: AppColors.bg, border: Border(top: BorderSide(color: AppColors.line))),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => AppStateScope.read(context).toggleWishlist(_product),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.bg, border: Border.all(color: AppColors.line)),
                      child: Text(wished ? '♥' : '♡', style: TextStyle(color: wished ? AppColors.accent : AppColors.ink3, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      text: _addedToCart ? '장바구니로 이동' : '장바구니 담기',
                      primary: !_addedToCart,
                      large: true,
                      onTap: _addedToCart ? _goToCart : _addToCart,
                    ),
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

class EditorialSection extends StatefulWidget {
  const EditorialSection({super.key});

  @override
  State<EditorialSection> createState() => _EditorialSectionState();
}

class _EditorialSectionState extends State<EditorialSection> {
  bool _showNote = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      decoration: const BoxDecoration(
        color: AppColors.bgSoft,
        border: Border(top: BorderSide(color: AppColors.line), bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: const NeutralImageSurface(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.pad, 30, AppSpace.pad, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MonoText('FIELD NOTE — 005', size: 10, color: AppColors.ink3),
                const SizedBox(height: 14),
                const Text('"필요한 것"과 "갖고 싶은 것"의 그 사이.', style: TextStyle(fontSize: 30, height: 1.05, letterSpacing: -1, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                const Text('매주 14개의 브랜드와 218개의 상품을 다시 골라냅니다. 오래 두고 싶은 것들을 모읍니다.', style: TextStyle(fontSize: 13.5, height: 1.65, color: AppColors.ink2)),
                if (_showNote) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.bg, border: Border.all(color: AppColors.line)),
                    child: const Text('이번 노트는 외부 페이지로 이동하지 않고, 로컬 큐레이션 메모만 펼쳐 보여줍니다. 상품보다 오래 남는 감각을 기준으로 고른 기록입니다.', style: TextStyle(fontSize: 12.5, height: 1.65, color: AppColors.ink2)),
                  ),
                ],
                const SizedBox(height: 20),
                AppButton(text: _showNote ? '큐레이션 노트 닫기' : '큐레이션 노트 보기', primary: true, onTap: () => setState(() => _showNote = !_showNote)),
                const SizedBox(height: 24),
                const Divider(color: AppColors.line),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Text('EST. 2024 · SEOUL', style: monoStyle)),
                    Expanded(child: Text('ED. Vol.23 — 2026.05', style: monoStyle)),
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

class BrandSection extends StatelessWidget {
  const BrandSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 실제 브랜드(백엔드가 메인 카테고리별 대표 브랜드로 고른 것) — 예전엔 가짜 브랜드 14개가 고정돼 있었다.
    final store = AppStateScope.watch(context);
    final brands = store.suggestions;
    final half = (brands.length / 2).ceil();
    final rows = [
      BrandRow(items: store.catalogLoading ? const ['·'] : brands.take(half).toList()),
      BrandRow(items: store.catalogLoading ? const ['·'] : brands.skip(half).toList(), noTop: true),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.symmetric(horizontal: AppSpace.pad), child: Eyebrow(index: '04', text: "THIS WEEK'S BRANDS")),
          const Padding(padding: EdgeInsets.fromLTRB(AppSpace.pad, 8, AppSpace.pad, 20), child: Text('참여 브랜드', style: TextStyle(fontSize: 34, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1.2))),
          // 응답 전엔 두 줄의 자리를 그대로 두고(보이지 않게) 로딩 점 — 브랜드가 나타날 때 밀리지 않게.
          if (store.catalogLoading)
            Stack(
              alignment: Alignment.center,
              children: [
                Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true, child: Column(children: rows)),
                const LoadingDots(),
              ],
            )
          else
            ...rows,
        ],
      ),
    );
  }
}

class BrandRow extends StatelessWidget {
  const BrandRow({required this.items, this.noTop = false, super.key});
  final List<String> items;
  final bool noTop;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: noTop ? BorderSide.none : const BorderSide(color: AppColors.line),
          bottom: const BorderSide(color: AppColors.line),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ScrollConfiguration(
        behavior: const DoguDragScrollBehavior(),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: AppSpace.pad),
              for (final item in [...items, ...items])
                Padding(
                  padding: const EdgeInsets.only(right: 28),
                  child: Text(item, style: const TextStyle(fontSize: 20, color: AppColors.ink3, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsletterSection extends StatefulWidget {
  const NewsletterSection({super.key});

  @override
  State<NewsletterSection> createState() => _NewsletterSectionState();
}

class _NewsletterSectionState extends State<NewsletterSection> {
  final _controller = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final email = _controller.text.trim();
    if (email.isEmpty) return;
    String message;
    try {
      await AppStateScope.read(context).subscribeNewsletter(email);
      message = '구독 요청을 보냈습니다.';
    } on ApiStatusError catch (e) {
      message = e.statusCode == 422 ? '이메일 주소를 다시 확인해주세요.' : '지금은 구독을 받을 수 없어요. 잠시 뒤 다시 시도해주세요.';
    } catch (_) {
      message = '오프라인 상태라 구독은 나중에 다시 시도해주세요.';
    }
    if (mounted) setState(() => _message = message);
  }

  @override
  Widget build(BuildContext context) {
    final data = AppStateScope.watch(context).newsletter;
    return Container(
      color: AppColors.ink,
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 44, AppSpace.pad, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoText(data['eyebrow'] ?? '— 매주 수요일 발송', size: 10.5, color: AppColors.ink4),
          const SizedBox(height: 14),
          Text(data['title'] ?? '조용한 신상품을\n가장 먼저.', style: const TextStyle(fontSize: 36, height: 1, color: AppColors.invert, fontWeight: FontWeight.w700, letterSpacing: -1.4)),
          const SizedBox(height: 28),
          Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.ink2))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _subscribe(),
                    decoration: const InputDecoration.collapsed(hintText: 'you@email.com', hintStyle: TextStyle(fontSize: 13, color: Color(0xff555555), fontFamily: 'monospace')),
                    style: const TextStyle(fontSize: 13, color: AppColors.invert, fontFamily: 'monospace'),
                  ),
                ),
                GestureDetector(onTap: _subscribe, child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('구독', style: TextStyle(color: AppColors.invert, fontWeight: FontWeight.w600)))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MonoText(_message ?? data['note'] ?? '// 언제든 한 번의 클릭으로 구독 취소', size: 10.5, color: AppColors.ink4),
        ],
      ),
    );
  }
}

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    const groups = {
      'SHOP': ['신상품', '베스트', '오늘의 딜', 'SALE'],
      'CATEGORY': ['의류', '홈·리빙', '전자제품', '뷰티'],
      'HELP': ['고객센터', '배송 안내', '반품 / 교환', 'FAQ'],
      'ABOUT': ['브랜드 스토리', '큐레이션 노트', '입점 문의'],
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 32, AppSpace.pad, 28),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 헤더와 같은 브랜드 락업(로고 이미지 + 손글씨 타이틀).
          const DoguBrandLockup(),
          const SizedBox(height: 10),
          const Text('매주 한 번, 조용한 큐레이션.\nSeoul, KR — since 2024.', style: TextStyle(fontSize: 12.5, color: AppColors.ink3, height: 1.6)),
          const SizedBox(height: 24),
          for (final entry in groups.entries) FooterGroup(title: entry.key, items: entry.value),
          const SizedBox(height: 22),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: const ['VISA', 'MC', 'AMEX', 'KAKAO', 'NAVER', 'TOSS'].map((pay) => Tag(text: pay, compact: true)).toList(),
          ),
          const SizedBox(height: 16),
          const MonoText('© 2026 욕망의장바구니\nBIZ 000-00-00000 · 서울 ○○구', size: 10.5, color: AppColors.ink4),
        ],
      ),
    );
  }
}

class FooterGroup extends StatefulWidget {
  const FooterGroup({required this.title, required this.items, super.key});
  final String title;
  final List<String> items;

  @override
  State<FooterGroup> createState() => _FooterGroupState();
}

class _FooterGroupState extends State<FooterGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MonoText(widget.title, size: 11, weight: FontWeight.w700),
                Text(_expanded ? '−' : '+', style: const TextStyle(color: AppColors.ink3)),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              for (final item in widget.items)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(item, style: const TextStyle(fontSize: 13, color: AppColors.ink2)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class BottomTabs extends StatelessWidget {
  const BottomTabs({
    required this.currentIndex,
    required this.onTap,
    required this.bottomInset,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    // 그리기는 디자인 시스템(DoguTabBar), 찜·장바구니 배지 숫자는 앱이 넘긴다.
    final store = AppStateScope.watch(context);
    final cartCount = store.cartCount;
    final wishCount = store.wishlistIds.length;
    return DoguTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      bottomInset: bottomInset,
      tabs: [
        const DoguTab(icon: Icons.home_outlined, label: '홈'),
        const DoguTab(icon: Icons.grid_view_outlined, label: '카테고리'),
        const DoguTab(icon: Icons.search, label: '검색'),
        DoguTab(icon: Icons.favorite_border, label: '찜', badge: wishCount > 0 ? wishCount.toString() : null),
        DoguTab(icon: Icons.shopping_cart_outlined, label: '장바구니', badge: cartCount > 0 ? cartCount.toString() : null, badgeColor: AppColors.alert),
      ],
    );
  }
}

class CategoryTabPage extends StatelessWidget {
  const CategoryTabPage({required this.bottomPadding, super.key});
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return ListView(
      key: const PageStorageKey('category-tab'),
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        const Header(),
        if (store.selectedCategoryKey != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AppStateScope.read(context).selectCategoryBrowse(null);
              AppStateScope.read(context).setCategoryQuickFilter('all');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(AppSpace.pad, 16, AppSpace.pad, 8),
              child: const MonoText('← 전체 카테고리', size: 11, color: AppColors.ink3, weight: FontWeight.w700),
            ),
          ),
        QuickFilterRow(
          items: const ['전체', '신상', '베스트', '세일', '딜'],
          activeIndex: _categoryFilterIndexFor(store.categoryQuickFilter),
          onSelectedIndex: (index) {
            const filterKeys = ['all', 'new', 'best', 'sale', 'deal'];
            AppStateScope.read(context).setCategoryQuickFilter(filterKeys[index]);
          },
        ),
        const CategoryListBlock(),
        if (store.selectedCategoryKey != null || store.categoryQuickFilter != 'all')
          CategoryProductsBlock(
            products: store.categoryBrowseProducts,
            // 카테고리 미선택(퀵필터만)이면 전체 상품 = 백엔드 카탈로그를, 선택했으면 그 카테고리 결과를 기다린다.
            loading: store.selectedCategoryKey == null ? store.catalogLoading : store.categoryProductsLoading,
          ),
        const SoftDividerBlock(child: BrandTagBlock(title: '[ + ] SHOP BY BRAND')),
      ],
    );
  }
}

int _categoryFilterIndexFor(String filter) {
  const filters = ['all', 'new', 'best', 'sale', 'deal'];
  return filters.indexOf(filter).clamp(0, filters.length - 1);
}

class SearchTabPage extends StatelessWidget {
  const SearchTabPage({required this.bottomPadding, super.key});
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return ListView(
      key: const PageStorageKey('search-tab'),
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        const Header(),
        const BigSearchBox(),
        if (store.lastSearchTerm.isNotEmpty)
          SearchResultsBlock(
            query: store.lastSearchTerm,
            results: store.searchResults,
          ),
        TagSection(
          title: '[ 01 ] 최근 검색',
          action: '전체 삭제',
          tags: store.recentSearches,
          emptyText: '최근 검색어가 없어요',
          onAction: () => AppStateScope.read(context).clearRecentSearches(),
          onTagTap: (term) => AppStateScope.read(context).performSearch(term),
          onRemove: (term) => AppStateScope.read(context).removeRecentSearch(term),
        ),
        SoftDividerBlock(
          child: TagSection(
            title: '[ 02 ] 추천 브랜드',
            tags: store.suggestions,
            loading: store.catalogLoading,
            onTagTap: (term) => AppStateScope.read(context).performSearch(term),
          ),
        ),
      ],
    );
  }
}

class SearchResultsBlock extends StatelessWidget {
  const SearchResultsBlock({required this.query, required this.results, super.key});

  final String query;
  final List<ProductItem> results;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 8, AppSpace.pad, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '검색 결과',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '“$query”',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            results.isEmpty ? '검색 결과가 없습니다.' : '${results.length}개의 상품을 찾았어요.',
            style: const TextStyle(fontSize: 12.5, color: AppColors.ink3),
          ),
          if (results.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final product in results)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProductCard(product: product),
              ),
          ],
        ],
      ),
    );
  }
}

class WishTabPage extends StatefulWidget {
  const WishTabPage({required this.bottomPadding, super.key});
  final double bottomPadding;

  @override
  State<WishTabPage> createState() => _WishTabPageState();
}

class _WishTabPageState extends State<WishTabPage> {
  String _activeFilter = 'all';

  bool _isSaleProduct(ProductItem product) {
    return product.numericOldPrice > product.numericPrice || (product.discount.isNotEmpty && product.discount != '-0%');
  }

  List<ProductItem> _filterWishlist(List<ProductItem> items) {
    if (_activeFilter != 'sale') return items;
    return items.where(_isSaleProduct).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filterWishlist(AppStateScope.watch(context).wishlistProducts);
    return ListView(
      key: const PageStorageKey('wish-tab'),
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      children: [
        const Header(),
        WishSummary(
          activeFilter: _activeFilter,
          onFilterSelected: (filter) => setState(() => _activeFilter = filter),
        ),
        WishGridBlock(items: filteredItems, activeFilter: _activeFilter),
      ],
    );
  }
}

class CartTabPage extends StatelessWidget {
  const CartTabPage({required this.bottomPadding, super.key});
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('cart-tab'),
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: const [
        Header(),
        CartStatusBlock(),
        CartBannerBlock(),
        CartItemsBlock(),
        CartSummaryBlock(),
        SoftDividerBlock(child: RecommendedCartBlock()),
      ],
    );
  }
}


