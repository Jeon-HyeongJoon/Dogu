part of '../main.dart';

/// v2 상품 상세를 셸 위(루트 네비게이터)로 띄운다 — v2 카드 탭 → v2 상세로 일관 유지.
void openV2ProductDetail(BuildContext context, ProductItem product, {VoidCallback? onGoToCart}) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(builder: (_) => V2ProductDetailPage(product: product, onGoToCart: onGoToCart)),
  );
}

/// v2 상품 상세 — 풀블리드 아트 + 빅 프라이스 + 블랙 CTA(v1 ProductDetailPage 미러).
class V2ProductDetailPage extends StatefulWidget {
  const V2ProductDetailPage({required this.product, this.onGoToCart, super.key});
  final ProductItem product;
  final VoidCallback? onGoToCart;

  @override
  State<V2ProductDetailPage> createState() => _V2ProductDetailPageState();
}

class _V2ProductDetailPageState extends State<V2ProductDetailPage> {
  int _quantity = 1;
  bool _added = false;

  // 수량을 바꾸면 '장바구니 보기' 잠금을 풀어 새 수량으로 다시 담을 수 있게 한다.
  void _changeQuantity(int delta) => setState(() {
        _quantity = (_quantity + delta).clamp(1, 99);
        _added = false;
      });

  String _formatCount(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  Future<void> _addToCart() async {
    final store = AppStateScope.read(context);
    store.cacheProduct(widget.product);
    await store.changeCartQuantity(widget.product.id, _quantity);
    if (!mounted) return;
    setState(() => _added = true);
    store.showCartToast('${widget.product.name} $_quantity개를 장바구니에 담았습니다.');
  }

  String _tagLabel(String tag) {
    switch (tag) {
      case 'today_deal':
        return '오늘의 딜';
      case 'new_arrival':
        return '신상품';
      case 'best':
        return '베스트';
      default:
        // 미지의 시드 태그는 snake_case 원문 대신 대문자 레이블로 정돈해 노출한다.
        return tag.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final wished = AppStateScope.watch(context).wishlistIds.contains(product.id);
    return Scaffold(
      backgroundColor: V2Colors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _bar(context),
            Expanded(
              child: V2ScrollBody(
                builder: (context, cols) => [
                  // 아트워크 — 46b 에디토리얼 문법: 프레임 없이 풀블리드.
                  // 1:1 아트가 태블릿에서 화면을 독점하지 않게 최대폭(=높이)을 캡한다.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(V2Space.pad, V2Space.pad, V2Space.pad, 0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Stack(
                          children: [
                            V2Artwork(product: product),
                            if (product.discount.isNotEmpty && product.discount != '-0%')
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  color: V2Colors.crave,
                                  // 가격 행과 부호 표기 통일(49%) — '-'는 붙이지 않는다.
                                  child: Text(
                                    product.discount.replaceAll('-', '').replaceAll('−', ''),
                                    style: V2Text.mono.copyWith(color: V2Colors.craveInk, fontSize: 13),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(V2Space.pad, 18, V2Space.pad, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.brand.toUpperCase(), style: V2Text.mono.copyWith(fontSize: 11, color: V2Colors.inkSoft)),
                        const SizedBox(height: 6),
                        Text(product.name, style: V2Text.display.copyWith(fontSize: 25)),
                        if (product.subtitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(product.subtitle, style: V2Text.body.copyWith(fontSize: 13)),
                          ),
                        const SizedBox(height: 14),
                        // 빅 프라이스 — 지불 금액이 주인공: 판매가 28px, 할인율은 한 단계 낮춰(18px) 보조.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            if (product.hasDiscount) ...[
                              Text(
                                product.discount.replaceAll('-', '').replaceAll('−', ''),
                                style: V2Text.title.copyWith(color: V2Colors.crave, fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(product.price, style: V2Text.display.copyWith(fontSize: 28)),
                            if (product.hasDiscount) ...[
                              const SizedBox(width: 8),
                              Text(
                                product.oldPrice,
                                // 할인 근거가 읽히도록 inkSoft(AA 대비)로.
                                style: V2Text.body.copyWith(fontSize: 13, color: V2Colors.inkSoft, decoration: TextDecoration.lineThrough),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '★ ${product.rating.toStringAsFixed(1)}  ·  리뷰 ${_formatCount(product.reviews)}',
                          style: V2Text.body.copyWith(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const V2SectionHeader(index: '01', title: '상품 정보', typeLine: 'Detail'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: V2Space.pad),
                    child: V2Panel(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.blurb.isEmpty ? '이 상품에 대한 설명이 곧 추가됩니다.' : product.blurb,
                            style: V2Text.body.copyWith(color: V2Colors.ink, fontSize: 13),
                          ),
                          if (product.tags.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [for (final t in product.tags) V2TagChip(_tagLabel(t))],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _actionBar(context, wished),
    );
  }

  Widget _bar(BuildContext context) {
    return Container(
      height: V2Space.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: V2Colors.pot,
        border: Border(bottom: BorderSide(color: V2Colors.gold, width: 2)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left_rounded, color: V2Colors.potInk),
          ),
          Text('상품 상세', style: V2Text.title.copyWith(color: V2Colors.potInk, fontSize: 17)),
          const Spacer(),
          // 층 레일이 없는 상세에서도 백화점 은유를 잇는 층 표찰(M층 매대).
          Text('M · SHOWROOM', style: V2Text.mono.copyWith(color: V2Colors.gold, fontSize: 9)),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _actionBar(BuildContext context, bool wished) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(V2Space.pad, 10, V2Space.pad, 10 + bottomInset),
      decoration: const BoxDecoration(
        color: V2Colors.paper,
        border: Border(top: BorderSide(color: V2Colors.line)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => AppStateScope.read(context).toggleWishlist(widget.product),
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: V2Colors.paper,
                borderRadius: BorderRadius.circular(V2Space.radius),
                border: Border.all(color: V2Colors.line),
              ),
              child: Icon(wished ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: V2Colors.crave),
            ),
          ),
          const SizedBox(width: 10),
          // 수량 스테퍼 — 담기 CTA 바로 곁에서 수량을 정한다(콘텐츠 바닥에서 이동).
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: V2Colors.paper,
              borderRadius: BorderRadius.circular(V2Space.radius),
              border: Border.all(color: V2Colors.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyButton(icon: Icons.remove_rounded, onTap: () => _changeQuantity(-1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('$_quantity', style: V2Text.title.copyWith(fontSize: 16)),
                ),
                _QtyButton(icon: Icons.add_rounded, onTap: () => _changeQuantity(1)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: (_added && widget.onGoToCart != null) ? widget.onGoToCart : _addToCart,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: V2Colors.pot,
                  borderRadius: BorderRadius.circular(V2Space.radius),
                  border: Border.all(color: V2Colors.gold, width: 1.2),
                ),
                child: Text(
                  (_added && widget.onGoToCart != null) ? '장바구니 보기' : '장바구니에 담기',
                  style: V2Text.title.copyWith(color: V2Colors.potInk, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 18, color: V2Colors.ink),
      ),
    );
  }
}
