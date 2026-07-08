part of '../main.dart';

class CategoryListBlock extends StatelessWidget {
  const CategoryListBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = AppStateScope.watch(context).categories;
    final selectedCategoryKey = AppStateScope.watch(context).selectedCategoryKey;
    final visibleRows = selectedCategoryKey == null
        ? rows
        : rows.where((row) => _normalizeCategoryKey(row.id.isEmpty ? row.name : row.id) == selectedCategoryKey).toList();
    return Column(
      children: [
        for (var i = 0; i < visibleRows.length; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AppStateScope.read(context).setCategoryQuickFilter('all');
              AppStateScope.read(context).selectCategoryBrowse(_normalizeCategoryKey(visibleRows[i].id.isEmpty ? visibleRows[i].name : visibleRows[i].id));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad, vertical: 14),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: MonoText((i + 1).toString().padLeft(2, '0'), size: 11, color: AppColors.ink4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(visibleRows[i].name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                        const SizedBox(height: 4),
                        Text(visibleRows[i].description.isEmpty ? '큐레이션 · 베스트 · 신상품 · 한정판' : visibleRows[i].description, style: const TextStyle(fontSize: 11.5, color: AppColors.ink3, height: 1.5)),
                      ],
                    ),
                  ),
                  Row(children: [MonoText(visibleRows[i].count, size: 11, color: AppColors.ink3), const SizedBox(width: 6), const Text('→')]),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class CategoryProductsBlock extends StatelessWidget {
  const CategoryProductsBlock({required this.products, super.key});

  final List<ProductItem> products;

  @override
  Widget build(BuildContext context) {
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

class SoftDividerBlock extends StatelessWidget {
  const SoftDividerBlock({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.bgSoft, width: 8))),
      child: child,
    );
  }
}

class EmptyStateBlock extends StatelessWidget {
  const EmptyStateBlock({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSpace.pad),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(color: AppColors.bgSoft, border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 12.5, height: 1.6, color: AppColors.ink3)),
        ],
      ),
    );
  }
}

class BrandTagBlock extends StatelessWidget {
  const BrandTagBlock({required this.title, this.action, super.key});
  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    const brands = ['soft·studio  42', 'good machine  18', 'objet·han  36', 'NORM /  24', 'QUIET CO.  19', 'paperhouse  12', 'flat·flat  28', 'ATELIER 04  31'];
    return SearchBlock(title: title, action: action, tags: brands);
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
      decoration: BoxDecoration(border: Border.all(color: AppColors.ink), color: AppColors.bg),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _performSearch(_controller.text),
            child: const Icon(Icons.search, size: 18),
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

class SearchBlock extends StatelessWidget {
  const SearchBlock({required this.title, required this.tags, this.action, this.onAction, this.onTagTap, super.key});
  final String title;
  final String? action;
  final List<String> tags;
  final VoidCallback? onAction;
  final ValueChanged<String>? onTagTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 22, AppSpace.pad, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MonoText(title, size: 10, weight: FontWeight.w700),
              if (action != null) GestureDetector(onTap: onAction, child: Text(action!, style: const TextStyle(fontSize: 11, color: AppColors.ink4))),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in tags)
                title == '[ 01 ] 최근 검색' && tag.endsWith('  ×')
                    ? RecentSearchTag(
                        label: tag.replaceAll('  ×', ''),
                        onTap: onTagTap == null ? null : () => onTagTap!(tag.replaceAll('  ×', '')),
                        onRemove: () => AppStateScope.read(context).removeRecentSearch(tag.replaceAll('  ×', '')),
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onTagTap == null ? null : () => onTagTap!(tag),
                        child: Tag(text: tag, compact: true),
                      ),
            ],
          ),
        ],
      ),
    );
  }
}

class RecentSearchTag extends StatelessWidget {
  const RecentSearchTag({required this.label, this.onTap, this.onRemove, super.key});

  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), color: AppColors.bg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            key: Key('recent-remove-$label'),
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: const Text('×', style: TextStyle(fontSize: 12, color: AppColors.ink4)),
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

class SmallChip extends StatelessWidget {
  const SmallChip({required this.text, this.active = false, super.key});
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: active ? AppColors.accent : AppColors.bg, border: Border.all(color: active ? AppColors.accent : AppColors.line)),
      child: Text(text, style: TextStyle(fontSize: 12, color: active ? AppColors.invert : AppColors.ink2)),
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
            Positioned(top: 8, right: 8, child: GestureDetector(onTap: () => AppStateScope.read(context).toggleWishlist(items[index]), child: Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.bg, border: Border.all(color: AppColors.line)), child: const Text('♥', style: TextStyle(color: AppColors.accent))))),
          ],
        ),
      ),
    );
  }
}

class PriceDropBlock extends StatelessWidget {
  const PriceDropBlock({super.key});

  @override
  Widget build(BuildContext context) {
    const drops = [
      ('Graphite Linen Overshirt', 'soft·studio', '₩189,000', '₩118,000'),
      ('Aluminum Desk Lamp', 'good machine', '₩198,000', '₩148,000'),
      ('Cedar Wood Diffuser', 'slow craft', '₩62,000', '₩46,000'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 24, AppSpace.pad, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MonoText('[ ↓ ] 가격 인하 알림', size: 10, weight: FontWeight.w700),
          const SizedBox(height: 12),
          const Text('관심상품 중 가격이 내려간 3개 항목이 있어요.', style: TextStyle(fontSize: 12.5, color: AppColors.ink3, height: 1.6)),
          const SizedBox(height: 14),
          for (final item in drops)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
              child: Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.$1, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)), MonoText(item.$2, size: 10.5, color: AppColors.ink4)])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [StrikeText(item.$3), MonoText(item.$4, size: 14, color: AppColors.accent, weight: FontWeight.w700)]),
                ],
              ),
            ),
        ],
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
    final selected = AppStateScope.watch(context).selectedCartIds.contains(item.product.id);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => AppStateScope.read(context).toggleCartSelection(item.product.id),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.pad - 2),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [SizedBox(width: 96, height: 96, child: ProductImageSurface(pattern: item.product.pattern, imageUrl: item.product.imageUrl, artwork: item.product.artwork, child: Padding(padding: const EdgeInsets.all(6), child: MonoText(index.toString().padLeft(3, '0'), size: 9, color: AppColors.ink4)))), Positioned(top: -2, left: -2, child: Container(width: 18, height: 18, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? AppColors.accent : AppColors.bg, border: Border.all(color: selected ? AppColors.accent : AppColors.line)), child: Text(selected ? '✓' : '', style: const TextStyle(color: AppColors.invert, fontSize: 11))))]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonoText(item.product.brand, size: 10, color: AppColors.ink4),
                  const SizedBox(height: 4),
                  Text(item.product.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  const MonoText('local cart · persisted on this device', size: 10.5, color: AppColors.ink3),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, children: [if (item.product.hasDiscount) MonoText(item.product.discount, size: 11, color: AppColors.accent, weight: FontWeight.w700), MonoText(item.product.price, size: 14, weight: FontWeight.w700), if (item.product.hasDiscount) StrikeText(item.product.oldPrice)]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [QtyBox(value: item.quantity.toString(), onMinus: () => AppStateScope.read(context).changeCartQuantity(item.product.id, -1), onPlus: () => AppStateScope.read(context).changeCartQuantity(item.product.id, 1)), GestureDetector(onTap: () => AppStateScope.read(context).changeCartQuantity(item.product.id, -item.quantity), child: const MonoText('삭제 ×', size: 11, color: AppColors.ink4))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QtyBox extends StatelessWidget {
  const QtyBox({required this.value, this.onMinus, this.onPlus, this.buttonExtent = 48, this.valueExtent = 40, super.key});
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final double buttonExtent;
  final double valueExtent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
      child: Row(children: [GestureDetector(behavior: HitTestBehavior.opaque, onTap: onMinus, child: SizedBox(width: buttonExtent, height: buttonExtent, child: const Center(child: MonoText('−', size: 16)))), Container(width: valueExtent, height: buttonExtent, alignment: Alignment.center, decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.line), right: BorderSide(color: AppColors.line))), child: MonoText(value, size: 13, weight: FontWeight.w700)), GestureDetector(behavior: HitTestBehavior.opaque, onTap: onPlus, child: SizedBox(width: buttonExtent, height: buttonExtent, child: const Center(child: MonoText('+', size: 16))))]),
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
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerLeft, child: MonoText('// 장바구니는 이 기기에 로컬 저장됩니다\n// API에는 결제·쿠폰 데이터를 전송하지 않음', size: 10.5, color: AppColors.ink4)),
        ],
      ),
    );
  }
}

class SummaryLine extends StatelessWidget {
  const SummaryLine({required this.label, required this.value, this.accent = false, this.total = false, super.key});
  final String label;
  final String value;
  final bool accent;
  final bool total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: total ? 14 : 13, fontWeight: total ? FontWeight.w700 : FontWeight.w400, color: AppColors.ink2)), MonoText(value, size: total ? 22 : 13, color: accent ? AppColors.accent : AppColors.ink, weight: total ? FontWeight.w800 : FontWeight.w500)]),
    );
  }
}

class RecommendedCartBlock extends StatelessWidget {
  const RecommendedCartBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final recos = AppStateScope.watch(context).recommendedProducts.take(4).toList();
    if (recos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 24, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MonoText('[ → ] 함께 담으면 좋은', size: 10, weight: FontWeight.w700),
          const SizedBox(height: 12),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final item in recos) Padding(padding: const EdgeInsets.only(right: 12), child: SizedBox(width: 160, child: ProductCard(product: item)))])),
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
        final navBarHeight = AppSpace.tabHeight + MediaQuery.viewPaddingOf(dialogContext).bottom;
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
                  onConfirm: () => AppNavigationScope.select(context, 0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return Container(
      height: AppSpace.checkoutHeight,
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 16, AppSpace.pad, 18),
      decoration: const BoxDecoration(color: AppColors.ink, border: Border(top: BorderSide(color: Color(0xff1a1a1a)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [const MonoText('결제 금액', size: 10, color: AppColors.ink4), MonoText(formatWon(store.selectedCartTotal), size: 18, color: AppColors.invert, weight: FontWeight.w800)]),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: store.selectedCartCount == 0 ? null : () => _submitOrder(context),
            child: Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 22), alignment: Alignment.center, color: store.selectedCartCount == 0 ? AppColors.ink2 : AppColors.alert, child: Text('결제하기 (${store.selectedCartCount})  →', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
          ),
        ],
      ),
    );
  }
}

