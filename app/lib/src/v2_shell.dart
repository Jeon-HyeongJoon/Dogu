part of '../main.dart';

/// v2 앱 셸 — 제트 블랙 헤더 + 5탭 바디(IndexedStack) + 화이트 하단 탭바.
/// v1 AppShell과 동일한 5탭 구성(홈·카테고리·검색·찜·장바구니)을 미러링한다.
class V2Shell extends StatefulWidget {
  const V2Shell({this.initialTab = 0, super.key});
  final int initialTab;

  @override
  State<V2Shell> createState() => _V2ShellState();
}

class _V2ShellState extends State<V2Shell> {
  late int _tab = widget.initialTab;

  static const _bodies = [
    V2HomeBody(),
    V2CategoryBody(),
    V2SearchBody(),
    V2WishBody(),
    V2CartBody(),
  ];

  @override
  Widget build(BuildContext context) {
    return V2NavScope(
      goToTab: (index) => setState(() => _tab = index),
      child: Scaffold(
        backgroundColor: V2Colors.paper,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const V2Header(),
                  Expanded(child: IndexedStack(index: _tab, children: _bodies)),
                ],
              ),
            ),
            const Positioned(left: 0, right: 0, bottom: 16, child: V2CartToast()),
          ],
        ),
        bottomNavigationBar: V2BottomBar(
          current: _tab,
          onTap: (index) => setState(() => _tab = index),
        ),
      ),
    );
  }
}

/// v2 탭 전환 스코프 — 바디(홈 검색바·카테고리 칩 등)가 다른 탭으로 이동을 요청한다.
class V2NavScope extends InheritedWidget {
  const V2NavScope({required this.goToTab, required super.child, super.key});
  final void Function(int index) goToTab;

  static void go(BuildContext context, int index) =>
      context.getInheritedWidgetOfExactType<V2NavScope>()?.goToTab(index);

  @override
  bool updateShouldNotify(V2NavScope oldWidget) => false;
}

/// v2 장바구니 토스트 — store.cartToastMessage를 제트 블랙 배너로 표시(3초 후 자동 소멸).
class V2CartToast extends StatelessWidget {
  const V2CartToast({super.key});

  @override
  Widget build(BuildContext context) {
    final message = AppStateScope.watch(context).cartToastMessage;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: message == null
          ? const SizedBox.shrink()
          : Padding(
              key: ValueKey(message),
              padding: const EdgeInsets.symmetric(horizontal: V2Space.pad),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: V2Colors.pot,
                  borderRadius: BorderRadius.circular(V2Space.radius),
                  border: Border.all(color: V2Colors.gold, width: 1.2),
                ),
                child: Text(
                  message,
                  style: V2Text.body.copyWith(color: V2Colors.potInk, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
    );
  }
}

/// 하단 탭바 — 딥 그린 바 + 골드 상단 트림, 활성 탭은 골드.
class V2BottomBar extends StatelessWidget {
  const V2BottomBar({required this.current, required this.onTap, super.key});
  final int current;
  final ValueChanged<int> onTap;

  static const _items = <(IconData, String)>[
    (Icons.home_rounded, '홈'),
    (Icons.grid_view_rounded, '카테고리'),
    (Icons.search_rounded, '검색'),
    (Icons.favorite_rounded, '찜'),
    (Icons.shopping_bag_rounded, '장바구니'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: V2Colors.pot,
        border: Border(top: BorderSide(color: V2Colors.gold, width: 2)),
      ),
      child: SizedBox(
        height: V2Space.tabHeight,
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _items[i].$1,
                        size: 23,
                        color: i == current ? V2Colors.gold : V2Colors.potSoft,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _items[i].$2,
                        style: V2Text.body.copyWith(
                          fontSize: 10.5,
                          fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
                          color: i == current ? V2Colors.gold : V2Colors.potSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 카테고리 탭 — 빠른 필터 + 카테고리 선택(→ 필터된 상품) + 브랜드 패널(v1 CategoryTabPage 미러).
class V2CategoryBody extends StatelessWidget {
  const V2CategoryBody({super.key});

  static const _filters = <(String, String)>[
    ('all', '전체'),
    ('new', '신상'),
    ('best', '베스트'),
    ('sale', '세일'),
    ('deal', '딜'),
  ];

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final categories = store.categories;
    final browsing = store.selectedCategoryKey != null || store.categoryQuickFilter != 'all';
    return V2ScrollBody(
      builder: (context, cols) => [
        const V2SectionHeader(index: '01', title: '카테고리', typeLine: '전체 상품'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: V2Space.pad),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in _filters)
                _V2FilterChip(
                  label: f.$2,
                  active: store.categoryQuickFilter == f.$1,
                  onTap: () => store.setCategoryQuickFilter(f.$1),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < categories.length; i++)
          V2CategoryRow(
            index: i + 1,
            item: categories[i],
            selected: store.selectedCategoryKey ==
                _normalizeCategoryKey(categories[i].id.isEmpty ? categories[i].name : categories[i].id),
            onTap: () {
              store.setCategoryQuickFilter('all');
              store.selectCategoryBrowse(
                _normalizeCategoryKey(categories[i].id.isEmpty ? categories[i].name : categories[i].id),
              );
            },
          ),
        if (browsing) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(V2Space.pad, 18, V2Space.pad, 8),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                store.selectCategoryBrowse(null);
                store.setCategoryQuickFilter('all');
              },
              child: Row(
                children: [
                  const Icon(Icons.chevron_left_rounded, size: 18, color: V2Colors.ink),
                  Text('전체 카테고리', style: V2Text.body.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: V2Colors.ink)),
                ],
              ),
            ),
          ),
          if (store.categoryBrowseProducts.isEmpty)
            const V2EmptyState(title: '해당 상품이 없어요', message: '다른 카테고리나 필터를 골라 보세요.')
          else
            V2ProductGrid(products: store.categoryBrowseProducts, columns: cols),
        ],
        const V2SectionHeader(index: '02', title: 'SHOP BY BRAND', typeLine: 'A-Z'),
        V2BrandPanel(brands: {for (final p in store.catalogProducts) p.brand}.toList()),
      ],
    );
  }
}

/// 선택 가능한 빠른 필터 칩.
class _V2FilterChip extends StatelessWidget {
  const _V2FilterChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? V2Colors.pot : V2Colors.surface,
          borderRadius: BorderRadius.circular(V2Space.radiusSm),
          border: Border.all(color: active ? V2Colors.gold : V2Colors.goldSoft, width: active ? 1.2 : 0.8),
        ),
        child: Text(
          label,
          style: V2Text.body.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: active ? V2Colors.potInk : V2Colors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class V2CategoryRow extends StatelessWidget {
  const V2CategoryRow({required this.index, required this.item, this.selected = false, this.onTap, super.key});
  final int index;
  final CategoryItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(V2Space.pad, 0, V2Space.pad, 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: V2Colors.paper,
            borderRadius: BorderRadius.circular(V2Space.radius),
            border: Border.all(color: selected ? V2Colors.goldDeep : V2Colors.line, width: selected ? 1.5 : 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(index.toString().padLeft(2, '0'), style: V2Text.mono.copyWith(fontSize: 12, color: V2Colors.inkFaint)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: V2Text.title.copyWith(fontSize: 16)),
                  if (item.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: V2Text.body.copyWith(fontSize: 11.5)),
                    ),
                ],
              ),
            ),
            Text(item.count, style: V2Text.mono.copyWith(fontSize: 11, color: V2Colors.inkFaint)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 20, color: V2Colors.inkFaint),
          ],
          ),
        ),
      ),
    );
  }
}

/// 검색 탭 — 검색 상자 + (결과) + 최근 검색 + 추천 브랜드(v1 SearchTabPage 미러).
class V2SearchBody extends StatefulWidget {
  const V2SearchBody({super.key});

  @override
  State<V2SearchBody> createState() => _V2SearchBodyState();
}

class _V2SearchBodyState extends State<V2SearchBody> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, String term) {
    final query = term.trim();
    if (query.isEmpty) return;
    AppStateScope.read(context).performSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return V2ScrollBody(
      builder: (context, cols) => [
        Padding(
          padding: const EdgeInsets.fromLTRB(V2Space.pad, V2Space.pad, V2Space.pad, 4),
          child: V2CardFrame(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: V2Text.body.copyWith(color: V2Colors.ink, fontSize: 14),
                    cursorColor: V2Colors.crave,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '어떤 상품을 찾으시나요?',
                      hintStyle: V2Text.body.copyWith(color: V2Colors.inkFaint, fontSize: 14),
                    ),
                    onSubmitted: (value) => _submit(context, value),
                  ),
                ),
                GestureDetector(
                  onTap: () => _submit(context, _controller.text),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: V2Colors.pot,
                      borderRadius: BorderRadius.circular(V2Space.radius),
                      border: Border.all(color: V2Colors.gold, width: 1.2),
                    ),
                    child: const Icon(Icons.search_rounded, size: 20, color: V2Colors.potInk),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (store.lastSearchTerm.isNotEmpty) ...[
          V2SectionHeader(index: '00', title: '“${store.lastSearchTerm}”', typeLine: '${store.searchResults.length}개 결과'),
          if (store.searchResults.isEmpty)
            const V2EmptyState(title: '검색 결과가 없어요', message: '다른 키워드로 다시 검색해 보세요.')
          else
            V2ProductGrid(products: store.searchResults, columns: cols),
        ],
        V2SectionHeader(
          index: '01',
          title: '최근 검색',
          typeLine: '전체 삭제',
          onTypeLineTap: store.recentSearches.isEmpty ? null : () => store.clearRecentSearches(),
        ),
        _chips(context, store.recentSearches),
        const V2SectionHeader(index: '02', title: '추천 브랜드', typeLine: '서치'),
        _chips(context, store.suggestions),
      ],
    );
  }

  Widget _chips(BuildContext context, List<String> terms) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: V2Space.pad),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final term in terms) V2TagChip(term, onTap: () => _submit(context, term)),
        ],
      ),
    );
  }
}

/// 찜 탭 — 위시리스트 그리드 + 전체/세일 필터(v1 WishTabPage 미러). 상품 카드 하트로 담기/빼기.
class V2WishBody extends StatefulWidget {
  const V2WishBody({super.key});

  @override
  State<V2WishBody> createState() => _V2WishBodyState();
}

class _V2WishBodyState extends State<V2WishBody> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final all = AppStateScope.watch(context).wishlistProducts;
    final items = _filter == 'sale' ? all.where((p) => p.hasDiscount).toList() : all;
    return V2ScrollBody(
      builder: (context, cols) => [
        const V2SectionHeader(index: '01', title: '찜한 상품', typeLine: 'My Picks'),
        if (all.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: V2Space.pad),
            child: Row(
              children: [
                _V2FilterChip(label: '전체', active: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _V2FilterChip(label: '세일', active: _filter == 'sale', onTap: () => setState(() => _filter = 'sale')),
                const Spacer(),
                Text('${all.length}개', style: V2Text.mono.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (all.isEmpty)
          const V2EmptyState(title: '찜한 상품이 없어요', message: '마음에 드는 상품의 하트를 눌러 찜 목록에 담아보세요.')
        else if (items.isEmpty)
          const V2EmptyState(title: '세일 중인 찜이 없어요', message: '전체 보기로 찜한 상품을 모두 확인하세요.')
        else
          V2ProductGrid(products: items, columns: cols),
      ],
    );
  }
}

/// 장바구니 탭 — v1 기능(선택·수량 변경·삭제·합계·결제)을 v2 테마로 배선.
class V2CartBody extends StatelessWidget {
  const V2CartBody({super.key});

  void _checkout(BuildContext context) {
    final store = AppStateScope.read(context);
    if (store.selectedCartLines.isEmpty) {
      store.showCartToast('선택된 상품이 없습니다.');
      return;
    }
    // 결제는 UI-only(로컬 모의 주문 요약) — 실제 PG 연동 없음.
    store.rememberOrderSummary({
      'item_count': store.selectedCartCount,
      'total_price': store.selectedCartTotal,
    });
    store.showCartToast('${store.selectedCartCount}개 · ${formatWon(store.selectedCartTotal)} 결제가 완료되었습니다 (데모).');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final lines = store.cartLines;
    final selected = store.selectedCartIds;
    final allSelected = lines.isNotEmpty && selected.length == lines.length;
    return V2ScrollBody(
      builder: (context, cols) => [
        const V2SectionHeader(index: '01', title: '장바구니', typeLine: 'Checkout'),
        if (lines.isEmpty)
          const V2EmptyState(title: '장바구니가 비어 있어요', message: '담고 싶은 상품을 골라 장바구니에 추가해 보세요.')
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(V2Space.pad, 0, V2Space.pad, 10),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: store.toggleAllCartSelection,
              child: Row(
                children: [
                  _V2Check(checked: allSelected),
                  const SizedBox(width: 8),
                  Text('전체 선택', style: V2Text.body.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: V2Colors.ink)),
                  const Spacer(),
                  Text('${selected.length}/${lines.length}', style: V2Text.mono.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.fromLTRB(V2Space.pad, 0, V2Space.pad, 10),
              child: V2CartLineRow(
                product: line.product,
                quantity: line.quantity,
                selected: selected.contains(line.product.id),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(V2Space.pad, 6, V2Space.pad, 0),
            child: V2Panel(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _summaryRow('상품 금액', formatWon(store.selectedCartOldTotal)),
                  const SizedBox(height: 6),
                  _summaryRow('할인', '-${formatWon(store.selectedCartDiscount)}', color: V2Colors.crave),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: V2Colors.line),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('결제 금액 (${store.selectedCartCount})', style: V2Text.title.copyWith(fontSize: 15)),
                      Text(formatWon(store.selectedCartTotal), style: V2Text.title.copyWith(fontSize: 20, color: V2Colors.crave)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(V2Space.pad, 12, V2Space.pad, 0),
            child: GestureDetector(
              onTap: () => _checkout(context),
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: V2Colors.pot,
                  borderRadius: BorderRadius.circular(V2Space.radius),
                  border: Border.all(color: V2Colors.gold, width: 1.2),
                ),
                child: Text('결제하기', style: V2Text.title.copyWith(color: V2Colors.potInk, fontSize: 16)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _summaryRow(String label, String value, {Color color = V2Colors.inkSoft}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: V2Text.body.copyWith(fontSize: 13)),
        Text(value, style: V2Text.body.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class V2CartLineRow extends StatelessWidget {
  const V2CartLineRow({required this.product, required this.quantity, required this.selected, super.key});
  final ProductItem product;
  final int quantity;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.read(context);
    return V2Panel(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => store.toggleCartSelection(product.id),
            child: _V2Check(checked: selected),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 52, height: 52, child: V2Artwork(product: product)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.brand, style: V2Text.body.copyWith(fontSize: 11, color: V2Colors.inkFaint, fontWeight: FontWeight.w700)),
                Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: V2Text.title.copyWith(fontSize: 14)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(product.price, style: V2Text.body.copyWith(fontSize: 13, color: V2Colors.ink, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    _QtyButton(icon: Icons.remove_rounded, onTap: () => store.changeCartQuantity(product.id, -1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$quantity', style: V2Text.title.copyWith(fontSize: 15)),
                    ),
                    _QtyButton(icon: Icons.add_rounded, onTap: () => store.changeCartQuantity(product.id, 1)),
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

/// v2 체크박스 — 선택 표시(블랙 사각 + 화이트 체크).
class _V2Check extends StatelessWidget {
  const _V2Check({required this.checked});
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? V2Colors.pot : V2Colors.paper,
        borderRadius: BorderRadius.circular(V2Space.radiusSm),
        border: Border.all(color: checked ? V2Colors.gold : V2Colors.line, width: 1.4),
      ),
      child: checked ? const Icon(Icons.check_rounded, size: 15, color: V2Colors.gold) : null,
    );
  }
}
