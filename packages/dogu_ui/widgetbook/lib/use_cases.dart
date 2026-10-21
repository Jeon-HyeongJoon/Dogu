// 디자인 시스템 컴포넌트의 사용 사례 — 카탈로그(Widgetbook)와 컴포넌트 골든 테스트가 같은 목록을 쓴다.
// 카탈로그에서 보는 모습이 곧 골든으로 고정된다. 새 컴포넌트를 만들면 여기에 사례를 더한다.
import 'package:dogu_ui/dogu_ui.dart';
import 'package:flutter/material.dart';

/// 사례 하나 — [frame]은 골든을 찍는 틀의 크기, [dark]면 어두운 바탕 위에 그린다.
class DoguUseCase {
  const DoguUseCase(this.name, this.build, {this.frame = const Size(360, 120), this.dark = false});

  final String name;
  final WidgetBuilder build;
  final Size frame;
  final bool dark;
}

/// 컴포넌트 하나와 그 사례들.
class DoguComponentCases {
  const DoguComponentCases(this.group, this.component, this.cases);

  /// atoms · molecules · organisms · brand — 패키지의 `lib/src/components/{group}/`
  final String group;
  final String component;
  final List<DoguUseCase> cases;
}

void _noop() {}
void _noopValue(Object? _) {}

const _product = ProductCardData(
  brand: '스파클Mart',
  name: '스파클 생수 2L 12병',
  price: '₩9,900',
  oldPrice: '₩13,900',
  discount: '-29%',
  hasDiscount: true,
  badge: 'BEST',
  meta: '4.6 · 1237 reviews',
);

const _plainProduct = ProductCardData(brand: '헤븐센스', name: '유아 저자극 로션 300ml', price: '₩18,500', meta: '4.8 · 512 reviews');

const _stats = [('6', '신상품'), ('16,092', '브랜드'), ('−32%', '평균 할인')];

final doguComponentCases = <DoguComponentCases>[
  // ── atoms ───────────────────────────────────────────────────────────────
  DoguComponentCases('atoms', 'MonoText', [
    DoguUseCase('default', (_) => const MonoText('001 / FEATURED', size: 12)),
    DoguUseCase('muted small', (_) => const MonoText('4.6 · 1237 reviews', size: 9.5, color: AppColors.ink4)),
  ]),
  DoguComponentCases('atoms', 'StrikeText', [DoguUseCase('default', (_) => const StrikeText('₩13,900'))]),
  DoguComponentCases('atoms', 'Eyebrow', [
    DoguUseCase('default', (_) => const Eyebrow(index: '01', text: 'SHOP BY CATEGORY')),
    DoguUseCase('inverted', (_) => const Eyebrow(index: '02', text: 'TODAY ONLY', inverted: true), dark: true),
  ]),
  DoguComponentCases('atoms', 'Tag', [
    DoguUseCase('default', (_) => const Tag(text: '● 2026 SPRING DROP')),
    DoguUseCase('compact', (_) => const Tag(text: '스파클Mart', compact: true)),
    DoguUseCase('dark', (_) => const Tag(text: '● 2026 SPRING DROP', dark: true), dark: true),
  ]),
  DoguComponentCases('atoms', 'BadgePill', [
    DoguUseCase('accent', (_) => const BadgePill(text: '-29%', color: AppColors.accent)),
    DoguUseCase('bordered', (_) => const BadgePill(text: 'BEST', color: AppColors.bg, ink: AppColors.ink, bordered: true)),
    DoguUseCase('compact alert', (_) => const BadgePill(text: '3', color: AppColors.alert, compact: true)),
  ]),
  DoguComponentCases('atoms', 'AppButton', [
    DoguUseCase('default', (_) => const AppButton(text: '노트', onTap: _noop)),
    DoguUseCase('primary large', (_) => const AppButton(text: '지금 둘러보기 →', primary: true, large: true, onTap: _noop)),
    DoguUseCase('on dark', (_) => const AppButton(text: '지금 둘러보기 →', primary: true, onDark: true, onTap: _noop), dark: true),
  ]),
  DoguComponentCases('atoms', 'LoadingDots', [
    DoguUseCase('default', (_) => const LoadingDots()),
    DoguUseCase('on dark', (_) => const LoadingDots(color: AppColors.heroInk3), dark: true),
  ]),
  DoguComponentCases('atoms', 'SkeletonProductCard', [
    DoguUseCase('light', (_) => const SizedBox(width: 180, child: SkeletonProductCard()), frame: Size(220, 320)),
    DoguUseCase('dark', (_) => const SizedBox(width: 180, child: SkeletonProductCard(dark: true)), frame: Size(220, 320), dark: true),
  ]),
  DoguComponentCases('atoms', 'SmallChip', [
    DoguUseCase('inactive', (_) => const SmallChip(text: '전체')),
    DoguUseCase('active', (_) => const SmallChip(text: '세일', active: true)),
  ]),
  DoguComponentCases('atoms', 'NavLabel', [
    DoguUseCase('default', (_) => const NavLabel(text: '베스트')),
    DoguUseCase('active', (_) => const NavLabel(text: '신상품', active: true)),
    DoguUseCase('sale', (_) => const NavLabel(text: 'SALE', sale: true)),
  ]),
  DoguComponentCases('atoms', 'IconBox', [
    DoguUseCase('default', (_) => const IconBox(icon: Icons.search, label: '검색', onTap: _noop)),
    DoguUseCase('inverted with count', (_) => const IconBox(icon: Icons.shopping_cart_outlined, label: '장바구니', inverted: true, count: '3', onTap: _noop)),
  ]),
  DoguComponentCases('atoms', 'CornerMark', [
    DoguUseCase('four corners', (_) => const SizedBox(
          width: 80,
          height: 80,
          child: Stack(children: [
            CornerMark(alignment: Alignment.topLeft),
            CornerMark(alignment: Alignment.topRight),
            CornerMark(alignment: Alignment.bottomLeft),
            CornerMark(alignment: Alignment.bottomRight),
          ]),
        )),
  ]),

  // ── molecules ───────────────────────────────────────────────────────────
  DoguComponentCases('molecules', 'SectionHead', [
    DoguUseCase('with link', (_) => const SectionHead(index: '01', eyebrow: 'SHOP BY CATEGORY', title: '카테고리', link: '전체 →', onLinkTap: _noop), frame: Size(390, 110)),
    DoguUseCase('title only', (_) => const SectionHead(index: '03', eyebrow: 'NEW ARRIVALS', title: '이번 주 신상품'), frame: Size(390, 110)),
  ]),
  DoguComponentCases('molecules', 'SectionBorder', [
    DoguUseCase('default', (_) => const SectionBorder(child: Padding(padding: EdgeInsets.all(20), child: Text('섹션 내용'))), frame: Size(390, 120)),
  ]),
  DoguComponentCases('molecules', 'SoftDividerBlock', [
    DoguUseCase('default', (_) => const SoftDividerBlock(child: Padding(padding: EdgeInsets.all(20), child: Text('구분된 블록'))), frame: Size(390, 120)),
  ]),
  DoguComponentCases('molecules', 'EmptyStateBlock', [
    DoguUseCase('default', (_) => const EmptyStateBlock(title: '찜한 상품이 없습니다.', body: '마음에 드는 상품을 찜해 보세요.'), frame: Size(390, 200)),
  ]),
  DoguComponentCases('molecules', 'SummaryLine', [
    DoguUseCase('default', (_) => const SummaryLine(label: '상품 금액', value: '₩205,800'), frame: Size(360, 60)),
    DoguUseCase('accent', (_) => const SummaryLine(label: '할인', value: '−₩43,600', accent: true), frame: Size(360, 60)),
    DoguUseCase('total', (_) => const SummaryLine(label: '결제 예정 금액', value: '₩162,200', total: true), frame: Size(360, 70)),
  ]),
  DoguComponentCases('molecules', 'QtyBox', [
    DoguUseCase('default', (_) => const QtyBox(value: '2', onMinus: _noop, onPlus: _noop)),
  ]),
  DoguComponentCases('molecules', 'RecentSearchTag', [
    DoguUseCase('default', (_) => const RecentSearchTag(label: '가디건', onTap: _noop, onRemove: _noop)),
  ]),
  DoguComponentCases('molecules', 'StatGrid', [
    DoguUseCase('light', (_) => const StatGrid(stats: _stats), frame: Size(390, 110)),
    DoguUseCase('dark', (_) => const StatGrid(stats: _stats, dark: true), frame: Size(390, 110), dark: true),
    DoguUseCase('loading', (_) => const StatGrid(stats: [], dark: true, loading: true), frame: Size(390, 110), dark: true),
  ]),
  DoguComponentCases('molecules', 'QuickFilterRow', [
    DoguUseCase('first active', (_) => const QuickFilterRow(items: ['전체', '신상', '베스트', '세일', '딜'], activeIndex: 0, onSelectedIndex: _noopValue), frame: Size(390, 80)),
  ]),
  DoguComponentCases('molecules', 'CountdownTimer', [
    DoguUseCase('default', (_) => const CountdownTimer(initialSeconds: 7 * 3600 + 42 * 60 + 18), dark: true),
  ]),
  DoguComponentCases('molecules', 'PreparingImageSurface', [
    DoguUseCase('light', (_) => const SizedBox(width: 160, height: 160, child: PreparingImageSurface()), frame: Size(200, 200)),
    DoguUseCase('dark', (_) => const SizedBox(width: 160, height: 160, child: PreparingImageSurface(dark: true)), frame: Size(200, 200), dark: true),
  ]),
  DoguComponentCases('molecules', 'NeutralImageSurface', [
    DoguUseCase('default', (_) => const SizedBox(width: 160, height: 200, child: NeutralImageSurface()), frame: Size(200, 240)),
  ]),
  DoguComponentCases('molecules', 'ProductImage', [
    DoguUseCase('without url', (_) => const SizedBox(width: 160, height: 160, child: ProductImage(child: Padding(padding: EdgeInsets.all(8), child: BadgePill(text: '-29%', color: AppColors.ink)))), frame: Size(200, 200)),
  ]),
  DoguComponentCases('molecules', 'ProductCardView', [
    DoguUseCase('discount + badge', (_) => const SizedBox(width: 180, child: ProductCardView(data: _product, onTap: _noop, onWishTap: _noop)), frame: Size(220, 340)),
    DoguUseCase('plain, wished', (_) => const SizedBox(width: 180, child: ProductCardView(data: _plainProduct, wished: true, onTap: _noop, onWishTap: _noop)), frame: Size(220, 340)),
    DoguUseCase('dark', (_) => const SizedBox(width: 200, child: ProductCardView(data: _product, dark: true, onTap: _noop, onWishTap: _noop)), frame: Size(240, 360), dark: true),
  ]),
  DoguComponentCases('molecules', 'CategoryTile', [
    DoguUseCase('default', (_) => const SizedBox(width: 112, height: 72, child: CategoryTile(index: 1, name: '식품', onTap: _noop)), frame: Size(160, 110)),
  ]),
  DoguComponentCases('molecules', 'CategoryListRow', [
    DoguUseCase('default', (_) => const CategoryListRow(index: 7, name: '조명/인테리어', description: '큐레이션 · 베스트 · 신상품 · 한정판', onTap: _noop), frame: Size(390, 100)),
  ]),

  // ── organisms ───────────────────────────────────────────────────────────
  DoguComponentCases('organisms', 'DoguHeaderBar', [
    DoguUseCase('default', (_) => const DoguHeaderBar(onMenu: _noop, onSearch: _noop, onCart: _noop), frame: Size(390, 80)),
    DoguUseCase('cart badge', (_) => const DoguHeaderBar(cartBadge: '3', onMenu: _noop, onSearch: _noop, onCart: _noop), frame: Size(390, 80)),
  ]),
  DoguComponentCases('organisms', 'DoguTabBar', [
    DoguUseCase('home with badges', (_) => const DoguTabBar(
          currentIndex: 0,
          onTap: _noopValue,
          tabs: [
            DoguTab(icon: Icons.home_outlined, label: '홈'),
            DoguTab(icon: Icons.grid_view_outlined, label: '카테고리'),
            DoguTab(icon: Icons.search, label: '검색'),
            DoguTab(icon: Icons.favorite_border, label: '찜', badge: '2'),
            DoguTab(icon: Icons.shopping_cart_outlined, label: '장바구니', badge: '3', badgeColor: AppColors.alert),
          ],
        ), frame: Size(390, 100)),
  ]),
  DoguComponentCases('organisms', 'DoguNavBar', [
    DoguUseCase('categories', (_) => const DoguNavBar(items: [
          DoguNavItem(label: '신상품', active: true),
          DoguNavItem(label: '베스트'),
          DoguNavItem(label: '식품'),
          DoguNavItem(label: '생활용품'),
          DoguNavItem(label: 'SALE', sale: true),
        ], onTap: _noopValue), frame: Size(390, 80)),
    DoguUseCase('loading', (_) => const DoguNavBar(items: [
          DoguNavItem(label: '신상품'),
          DoguNavItem(label: '베스트'),
          DoguNavItem(label: 'SALE', sale: true),
        ], loadingIndex: 2, onTap: _noopValue), frame: Size(390, 80)),
  ]),
  DoguComponentCases('organisms', 'TagSection', [
    DoguUseCase('removable', (_) => const TagSection(title: '[ 01 ] 최근 검색', action: '전체 삭제', tags: ['가디건', '생수'], onTagTap: _noopValue, onRemove: _noopValue, onAction: _noop), frame: Size(390, 130)),
    DoguUseCase('plain', (_) => const TagSection(title: '[ 02 ] 추천 브랜드', tags: ['스파클Mart', '아모레퍼시픽몰 헤어바디', '닥터바이', '미엘물티슈'], onTagTap: _noopValue), frame: Size(390, 150)),
    DoguUseCase('empty', (_) => const TagSection(title: '[ 01 ] 최근 검색', action: '전체 삭제', tags: [], emptyText: '최근 검색어가 없어요'), frame: Size(390, 110)),
    DoguUseCase('loading', (_) => const TagSection(title: '[ 02 ] 추천 브랜드', tags: [], loading: true), frame: Size(390, 110)),
  ]),
  DoguComponentCases('organisms', 'CartLineView', [
    DoguUseCase('selected', (_) => const CartLineView(index: 1, brand: '스파클Mart', name: '스파클 생수 2L 12병', price: '₩9,900', oldPrice: '₩13,900', discount: '-29%', hasDiscount: true, quantity: 2, selected: true, onToggle: _noop, onMinus: _noop, onPlus: _noop, onRemove: _noop), frame: Size(390, 200)),
    DoguUseCase('not selected', (_) => const CartLineView(index: 2, brand: '헤븐센스', name: '유아 저자극 로션 300ml', price: '₩18,500', quantity: 1, onToggle: _noop, onMinus: _noop, onPlus: _noop, onRemove: _noop), frame: Size(390, 200)),
  ]),
  DoguComponentCases('organisms', 'CheckoutBarView', [
    DoguUseCase('enabled', (_) => const CheckoutBarView(label: '결제 금액', total: '₩162,200', buttonLabel: '결제하기 (3)  →', onCheckout: _noop), frame: Size(390, 110)),
    DoguUseCase('disabled', (_) => const CheckoutBarView(label: '결제 금액', total: '₩0', buttonLabel: '결제하기 (0)  →', enabled: false), frame: Size(390, 110)),
  ]),

  // ── brand ───────────────────────────────────────────────────────────────
  DoguComponentCases('brand', 'DoguBrandMark', [DoguUseCase('48', (_) => const DoguBrandMark(size: 48), frame: Size(120, 120))]),
  DoguComponentCases('brand', 'DoguLogoMark', [DoguUseCase('48', (_) => const DoguLogoMark(size: 48), frame: Size(120, 120))]),
  DoguComponentCases('brand', 'DoguBrandLockup', [DoguUseCase('default', (_) => const DoguBrandLockup(), frame: Size(300, 80))]),
];
