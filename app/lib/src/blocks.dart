part of '../main.dart';

class CategoryListBlock extends StatelessWidget {
  const CategoryListBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    // 메인 카테고리 칸과 같은 이유로, 백엔드 응답 전에는 seed 카테고리 대신 로딩 표시.
    if (store.catalogLoading) {
      return const Padding(
        key: ValueKey('category-list-loading'),
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: LoadingDots()),
      );
    }
    final rows = store.categories;
    final selectedCategoryKey = store.selectedCategoryKey;
    final visibleRows = selectedCategoryKey == null
        ? rows
        : rows.where((row) => _normalizeCategoryKey(row.id.isEmpty ? row.name : row.id) == selectedCategoryKey).toList();
    return Column(
      children: [
        for (var i = 0; i < visibleRows.length; i++)
          // 그리기는 디자인 시스템(CategoryListRow). 상품 수는 그리지 않는다(메인 카드와 같은 이유).
          CategoryListRow(
            index: i + 1,
            name: visibleRows[i].name,
            description: visibleRows[i].description.isEmpty ? '큐레이션 · 베스트 · 신상품 · 한정판' : visibleRows[i].description,
            onTap: () {
              AppStateScope.read(context).setCategoryQuickFilter('all');
              AppStateScope.read(context).selectCategoryBrowse(_normalizeCategoryKey(visibleRows[i].id.isEmpty ? visibleRows[i].name : visibleRows[i].id));
            },
          ),
      ],
    );
  }
}

class CategoryProductsBlock extends StatelessWidget {
  const CategoryProductsBlock({required this.products, this.loading = false, super.key});

  final List<ProductItem> products;
  /// 서버 결과를 기다리는 중 — 먼저 보인 결과가 크게 바뀌거나 '상품 없음'이 깜빡이지 않게 스켈레톤.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.all(AppSpace.pad),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.58,
            mainAxisSpacing: 24,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (_, __) => const SkeletonProductCard(),
        ),
      );
    }
    if (products.isEmpty) {
      return const EmptyStateBlock(
        title: '조건에 맞는 상품이 없습니다.',
        body: '다른 카테고리나 필터를 선택해 다시 확인해보세요.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpace.pad),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58,
          mainAxisSpacing: 24,
          crossAxisSpacing: 12,
        ),
        itemBuilder: (context, index) => ProductCard(product: products[index]),
      ),
    );
  }
}


/// 실제 브랜드(검색 탭 '추천 브랜드'와 같은 목록) — 누르면 그 브랜드로 검색한다.
/// 예전엔 가짜 브랜드 8개('soft·studio  42' 등)가 고정돼 있었고 '전체 보기'는 눌러도 아무 일도 없었다.
class BrandTagBlock extends StatelessWidget {
  const BrandTagBlock({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return TagSection(
      title: title,
      tags: store.suggestions,
      loading: store.catalogLoading,
      onTagTap: (brand) {
        AppStateScope.read(context).performSearch(brand);
        AppNavigationScope.select(context, 2);
      },
    );
  }
}

class BigSearchBox extends StatefulWidget {
  const BigSearchBox({super.key});

  @override
  State<BigSearchBox> createState() => _BigSearchBoxState();
}

class _BigSearchBoxState extends State<BigSearchBox> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      AppStateScope.read(context).resetSearch();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _performSearch(value);
    });
  }

  void _performSearch(String value) {
    _debounce?.cancel();
    AppStateScope.read(context).performSearch(value);
  }

  void _cancelSearch() {
    _debounce?.cancel();
    _controller.clear();
    FocusScope.of(context).unfocus();
    AppStateScope.read(context).resetSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.all(AppSpace.pad - 4),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.accent), color: AppColors.bgAlt),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _performSearch(_controller.text),
            child: const Icon(Icons.search, size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              autofocus: false,
              decoration: const InputDecoration.collapsed(hintText: '찾고 싶은 욕망을 입력하세요', hintStyle: TextStyle(fontSize: 15, color: AppColors.ink4)),
              style: const TextStyle(fontSize: 15, color: AppColors.ink),
              onChanged: _onChanged,
              onSubmitted: _performSearch,
            ),
          ),
          GestureDetector(
            onTap: _cancelSearch,
            child: const Text('취소', style: TextStyle(fontSize: 13, color: AppColors.ink3)),
          ),
        ],
      ),
    );
  }
}

class TrendingBlock extends StatelessWidget {
  const TrendingBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = AppStateScope.watch(context).trendingItems;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 24, AppSpace.pad, 12),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [MonoText('[ 02 ] 실시간 인기 검색', size: 10, weight: FontWeight.w700), MonoText('14:02 기준', size: 11, color: AppColors.ink4)],
          ),
          const SizedBox(height: 12),
            for (var i = 0; i < rows.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => AppStateScope.read(context).performSearch(rows[i].term),
                child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.lineSoft))),
                child: Row(
                  children: [
                    SizedBox(width: 28, child: MonoText((i + 1).toString().padLeft(2, '0'), size: 14, color: i < 3 ? AppColors.accent : AppColors.ink, weight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(rows[i].term, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                    MonoText(rows[i].movement, size: 10.5, color: rows[i].movement.startsWith('▲') ? AppColors.accent : AppColors.ink3),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WishSummary extends StatelessWidget {
  const WishSummary({required this.activeFilter, required this.onFilterSelected, super.key});

  final String activeFilter;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final total = store.wishlistProducts.fold<int>(0, (sum, product) => sum + product.numericPrice);
    return Container(
      padding: const EdgeInsets.all(AppSpace.pad - 4),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Expanded(child: Text('${store.wishlistProducts.length} items · 총 ${formatWon(total)} 상당', style: const TextStyle(fontSize: 12.5, color: AppColors.ink3))),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onFilterSelected('all'),
            child: SmallChip(text: '전체', active: activeFilter == 'all'),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onFilterSelected('sale'),
            child: SmallChip(text: '세일 중', active: activeFilter == 'sale'),
          ),
        ],
      ),
    );
  }
}


class WishGridBlock extends StatelessWidget {
  const WishGridBlock({required this.items, required this.activeFilter, super.key});

  final List<ProductItem> items;
  final String activeFilter;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyStateBlock(
        title: activeFilter == 'sale' ? '세일 중인 찜 상품이 없습니다.' : '찜한 상품이 없습니다.',
        body: activeFilter == 'sale' ? '전체 탭에서 관심 상품을 다시 확인해보세요.' : '상품 카드의 WISH 버튼으로 로컬 찜 목록을 채워보세요.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpace.pad),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.58, mainAxisSpacing: 24, crossAxisSpacing: 12),
        itemBuilder: (context, index) => Stack(
          children: [
            ProductCard(product: items[index]),
            Positioned(top: 8, right: 8, child: GestureDetector(onTap: () => AppStateScope.read(context).toggleWishlist(items[index]), child: Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.bgAlt, border: Border.all(color: AppColors.alertBright)), child: const Text('♥', style: TextStyle(color: AppColors.alertBright))))),
          ],
        ),
      ),
    );
  }
}

class CartStatusBlock extends StatelessWidget {
  const CartStatusBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MonoText('${store.selectedCartCount}개 상품 선택됨', size: 11, color: AppColors.ink3),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => AppStateScope.read(context).toggleAllCartSelection(),
            child: const Text('모두 선택', style: TextStyle(fontSize: 11, color: AppColors.ink3)),
          ),
        ],
      ),
    );
  }
}

class CartBannerBlock extends StatelessWidget {
  const CartBannerBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final remaining = (28000 - store.selectedCartTotal).clamp(0, 28000);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad, vertical: 12),
      decoration: const BoxDecoration(color: AppColors.bgSoft, border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)), const SizedBox(width: 10), Expanded(child: Text(remaining == 0 ? '무료 배송 조건이 충족됐어요' : '${formatWon(remaining)} 더 담으면 무료 배송 조건이 충족돼요', style: const TextStyle(fontSize: 12, color: AppColors.ink2)))]),
    );
  }
}

class CartItemsBlock extends StatelessWidget {
  const CartItemsBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final items = store.cartLines;
    if (items.isEmpty) {
      return const EmptyStateBlock(
        title: '장바구니가 비어 있습니다.',
        body: '홈과 카테고리에서 담은 상품이 이 기기에 로컬로 저장됩니다.',
      );
    }
    return Column(children: [for (var i = 0; i < items.length; i++) CartItemRow(index: i + 1, item: items[i])]);
  }
}

class CartItemRow extends StatelessWidget {
  const CartItemRow({required this.index, required this.item, super.key});
  final int index;
  final ({ProductItem product, int quantity}) item;

  @override
  Widget build(BuildContext context) {
    // 그리기는 디자인 시스템(CartLineView), 선택·수량·삭제는 스토어에 연결한다.
    final store = AppStateScope.watch(context);
    final product = item.product;
    return CartLineView(
      index: index,
      brand: product.brand,
      name: product.name,
      price: product.price,
      oldPrice: product.oldPrice,
      discount: product.discount,
      hasDiscount: product.hasDiscount,
      imageUrl: ApiConfig.displayImageUrl(product.imageUrl, thumbnailWidth: 300),
      quantity: item.quantity,
      selected: store.selectedCartIds.contains(product.id),
      onToggle: () => AppStateScope.read(context).toggleCartSelection(product.id),
      onMinus: () => AppStateScope.read(context).changeCartQuantity(product.id, -1),
      onPlus: () => AppStateScope.read(context).changeCartQuantity(product.id, 1),
      onRemove: () => AppStateScope.read(context).changeCartQuantity(product.id, -item.quantity),
    );
  }
}


class CartSummaryBlock extends StatelessWidget {
  const CartSummaryBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(AppSpace.pad + 2),
      color: AppColors.bgSoft,
      child: Column(
        children: [
          SummaryLine(label: '상품 금액', value: formatWon(store.selectedCartOldTotal)),
          SummaryLine(label: '할인', value: '−${formatWon(store.selectedCartDiscount)}', accent: true),
          const SummaryLine(label: '배송비', value: '무료'),
          const Divider(color: AppColors.line),
          SummaryLine(label: '결제 예정 금액', value: formatWon(store.selectedCartTotal), total: true),
        ],
      ),
    );
  }
}


class RecommendedCartBlock extends StatelessWidget {
  const RecommendedCartBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final recos = store.recommendedProducts.take(4).toList();
    if (recos.isEmpty && !store.catalogLoading) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 24, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MonoText('[ → ] 함께 담으면 좋은', size: 10, weight: FontWeight.w700),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              // 백엔드 응답 전엔 seed 상품 대신 스켈레톤.
              if (store.catalogLoading)
                for (var i = 0; i < 2; i++) const Padding(padding: EdgeInsets.only(right: 12), child: SizedBox(width: 160, child: SkeletonProductCard()))
              else
                for (final item in recos) Padding(padding: const EdgeInsets.only(right: 12), child: SizedBox(width: 160, child: ProductCard(product: item))),
            ]),
          ),
        ],
      ),
    );
  }
}

class CheckoutBar extends StatelessWidget {
  const CheckoutBar({super.key});

  Future<void> _submitOrder(BuildContext context) async {
    final store = AppStateScope.read(context);
    final summary = store.buildOrderSummary();
    if (summary == null) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '결제 진행',
      // 기본 배리어는 투명 — 어둡게 처리는 하단 네비게이션 바를 제외하고 커스텀 dim으로 직접
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, __) {
        final navBarHeight = AppLayout.tabHeight + MediaQuery.viewPaddingOf(dialogContext).bottom;
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return Stack(
          children: [
            // 하단 네비게이션 바는 어둡게 하지 않고, 그 위 영역만 어둡게 (탭은 배리어로 통과시켜 닫기 유지)
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: curved,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: navBarHeight),
                    child: const ColoredBox(color: Colors.black26),
                  ),
                ),
              ),
            ),
            // 토스트: 네비게이션 바 바로 위에서 이어져 올라오는 느낌
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
              child: FadeTransition(
                opacity: curved,
                child: PaymentToastOverlay(
                  orderSummary: summary,
                  onConfirm: (response) => _openOrderFlow(context, response),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 결제 완료 → 배송 안내 → 주문 결과. 결제 금액은 '참은 돈'으로 적립하고,
  /// 흐름이 끝나면 v1 기존 동작대로 홈 탭으로 돌아간다.
  Future<void> _openOrderFlow(BuildContext context, Map<String, dynamic> response) async {
    final store = AppStateScope.read(context);
    final placedAt = DateTime.now();
    final total = (response['total_price'] as num?)?.toInt() ?? 0;
    final saved = await store.recordResistedAmount(total, at: placedAt);
    if (!context.mounted) return;
    await openOrderFlow(
      context,
      OrderReceipt.fromResponse(store, response, placedAt: placedAt, savedThisMonth: saved),
      onDone: () => AppNavigationScope.select(context, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 그리기는 디자인 시스템(CheckoutBarView), 금액·결제 진행은 앱이 연결한다.
    final store = AppStateScope.watch(context);
    return CheckoutBarView(
      label: '결제 금액',
      total: formatWon(store.selectedCartTotal),
      buttonLabel: '결제하기 (${store.selectedCartCount})  →',
      enabled: store.selectedCartCount > 0,
      onCheckout: () => _submitOrder(context),
    );
  }
}

