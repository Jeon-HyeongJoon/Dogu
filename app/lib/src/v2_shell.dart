part of '../main.dart';

/// v2 앱 셸 — 청록 헤더 + 5탭 바디(IndexedStack) + 유희왕 카드풍 하단 탭바.
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
    return Scaffold(
      backgroundColor: V2Colors.parchment,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const V2Header(),
            Expanded(child: IndexedStack(index: _tab, children: _bodies)),
          ],
        ),
      ),
      bottomNavigationBar: V2BottomBar(
        current: _tab,
        onTap: (index) => setState(() => _tab = index),
      ),
    );
  }
}

/// 하단 탭바 — 청록 바 + 금색 상단 트림, 활성 탭은 금색.
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
        color: V2Colors.teal,
        border: Border(top: BorderSide(color: V2Colors.goldDark, width: V2Space.goldBorder)),
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
                        color: i == current ? V2Colors.goldLight : V2Colors.tealInk.withValues(alpha: 0.55),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _items[i].$2,
                        style: V2Text.body.copyWith(
                          fontSize: 10.5,
                          fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
                          color: i == current ? V2Colors.goldLight : V2Colors.tealInk.withValues(alpha: 0.7),
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

/// 카테고리 탭 — 번호 매긴 카테고리 리스트(v1 CategoryListBlock 미러) + 브랜드 패널.
class V2CategoryBody extends StatelessWidget {
  const V2CategoryBody({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final categories = store.categories;
    return V2ScrollBody(
      builder: (context, cols) => [
        const V2SectionHeader(index: '00', title: '카테고리', typeLine: '전체 카드'),
        for (var i = 0; i < categories.length; i++)
          V2CategoryRow(index: i + 1, item: categories[i]),
        const V2SectionHeader(index: '04', title: 'SHOP BY BRAND', typeLine: '덱 리스트'),
        V2BrandPanel(brands: {for (final p in store.catalogProducts) p.brand}.toList()),
      ],
    );
  }
}

class V2CategoryRow extends StatelessWidget {
  const V2CategoryRow({required this.index, required this.item, super.key});
  final int index;
  final CategoryItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(V2Space.pad, 0, V2Space.pad, 10),
      child: V2Panel(
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
            const Icon(Icons.chevron_right_rounded, size: 20, color: V2Colors.teal),
          ],
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
                    style: V2Text.body.copyWith(color: V2Colors.tealInk, fontSize: 14),
                    cursorColor: V2Colors.goldLight,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '어떤 카드를 찾으시나요?',
                      hintStyle: V2Text.body.copyWith(color: V2Colors.tealInk.withValues(alpha: 0.6), fontSize: 14),
                    ),
                    onSubmitted: (value) => _submit(context, value),
                  ),
                ),
                GestureDetector(
                  onTap: () => _submit(context, _controller.text),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: V2Colors.gold,
                      borderRadius: BorderRadius.circular(V2Space.artRadius),
                      border: Border.all(color: V2Colors.goldDark),
                    ),
                    child: const Icon(Icons.search_rounded, size: 20, color: V2Colors.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (store.lastSearchTerm.isNotEmpty) ...[
          V2SectionHeader(index: '검', title: '“${store.lastSearchTerm}”', typeLine: '${store.searchResults.length} 히트'),
          if (store.searchResults.isEmpty)
            const V2EmptyState(title: '검색 결과가 없어요', message: '다른 키워드로 다시 드로우해 보세요.')
          else
            V2ProductGrid(products: store.searchResults, columns: cols),
        ],
        const V2SectionHeader(index: '01', title: '최근 검색', typeLine: '히스토리'),
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

/// 찜 탭 — 위시리스트 상품 그리드(비어 있으면 빈 상태).
class V2WishBody extends StatelessWidget {
  const V2WishBody({super.key});

  @override
  Widget build(BuildContext context) {
    final wish = AppStateScope.watch(context).wishlistProducts;
    return V2ScrollBody(
      builder: (context, cols) => [
        const V2SectionHeader(index: '찜', title: '찜한 카드', typeLine: '마이 컬렉션'),
        if (wish.isEmpty)
          const V2EmptyState(title: '찜한 카드가 없어요', message: '마음에 드는 상품의 하트를 눌러 컬렉션에 담아보세요.')
        else
          V2ProductGrid(products: wish, columns: cols),
      ],
    );
  }
}

/// 장바구니 탭 — 담긴 상품 라인 + 합계 패널(비어 있으면 빈 상태).
class V2CartBody extends StatelessWidget {
  const V2CartBody({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final lines = store.cartLines;
    return V2ScrollBody(
      builder: (context, cols) => [
        const V2SectionHeader(index: '담', title: '장바구니', typeLine: '드로우 예정'),
        if (lines.isEmpty)
          const V2EmptyState(title: '장바구니가 비어 있어요', message: '담고 싶은 카드를 골라 장바구니에 추가해 보세요.')
        else ...[
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.fromLTRB(V2Space.pad, 0, V2Space.pad, 10),
              child: V2CartLineRow(product: line.product, quantity: line.quantity),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(V2Space.pad, 6, V2Space.pad, 0),
            child: V2Panel(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('합계 (${store.cartCount})', style: V2Text.title.copyWith(fontSize: 15)),
                  Text(formatWon(store.selectedCartTotal), style: V2Text.title.copyWith(fontSize: 18, color: V2Colors.maroon)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class V2CartLineRow extends StatelessWidget {
  const V2CartLineRow({required this.product, required this.quantity, super.key});
  final ProductItem product;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return V2Panel(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          SizedBox(width: 56, height: 56, child: V2Artwork(product: product)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.brand, style: V2Text.body.copyWith(fontSize: 11, color: V2Colors.inkFaint, fontWeight: FontWeight.w700)),
                Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: V2Text.title.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text('${product.price}  ·  $quantity장', style: V2Text.body.copyWith(fontSize: 12, color: V2Colors.maroon, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
