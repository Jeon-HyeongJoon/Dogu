import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

import 'package:dogu_ui/dogu_ui.dart';

import '../support.dart';

void main() {
  testWidgets('DoguHeaderBar reports menu, search and cart taps and shows the cart badge', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(host(DoguHeaderBar(
      cartBadge: '3',
      onMenu: () => calls.add('menu'),
      onSearch: () => calls.add('search'),
      onCart: () => calls.add('cart'),
    )));
    await tester.pump();
    expect(find.byType(DoguBrandLockup), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.tap(find.byIcon(Icons.search));
    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    expect(calls, ['menu', 'search', 'cart']);
  });

  testWidgets('DoguHeaderBar hides the cart badge without a count', (tester) async {
    await tester.pumpWidget(host(const DoguHeaderBar()));
    expect(find.byType(BadgePill), findsNothing);
  });

  testWidgets('DoguTabBar marks the current tab, shows badges and reports taps', (tester) async {
    int? tapped;
    await tester.pumpWidget(host(DoguTabBar(
      currentIndex: 1,
      onTap: (i) => tapped = i,
      bottomInset: 10,
      tabs: const [
        DoguTab(icon: Icons.home_outlined, label: '홈'),
        DoguTab(icon: Icons.grid_view_outlined, label: '카테고리'),
        DoguTab(icon: Icons.favorite_border, label: '찜', badge: '2'),
        DoguTab(icon: Icons.shopping_cart_outlined, label: '장바구니', badge: '5', badgeColor: AppColors.alert),
      ],
    )));
    expect(tester.getSize(find.byType(DoguTabBar)).height, DoguTabBar.barHeight + 10);
    Color colorOf(String label) => tester.widget<Text>(find.text(label)).style!.color!;
    expect(colorOf('카테고리'), AppColors.ink);
    expect(colorOf('홈'), AppColors.ink4);
    expect(tester.widget<BadgePill>(find.widgetWithText(BadgePill, '5')).color, AppColors.alert);
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.text('찜'));
    expect(tapped, 2);
  });

  testWidgets('DoguNavBar separates items, marks the active one and can hold a loading slot', (tester) async {
    int? tapped;
    const items = [DoguNavItem(label: '신상품', active: true), DoguNavItem(label: '베스트'), DoguNavItem(label: 'SALE', sale: true)];
    await tester.pumpWidget(host(DoguNavBar(items: items, onTap: (i) => tapped = i)));
    expect(find.text('|'), findsNWidgets(2));
    expect(tester.widget<Text>(find.text('신상품')).style!.color, AppColors.ink);
    expect(tester.widget<Text>(find.text('SALE')).style!.color, AppColors.accent);
    await tester.tap(find.text('SALE'));
    expect(tapped, 2, reason: '로딩 자리와 무관하게 항목 번호로 알린다');

    await tester.pumpWidget(host(DoguNavBar(items: items, loadingIndex: 2, onTap: (i) => tapped = i)));
    expect(find.byType(LoadingDots), findsOneWidget);
    expect(find.text('|'), findsNWidgets(3));
    await tester.tap(find.text('SALE'));
    expect(tapped, 2);
  });

  testWidgets('CategoryTile shows a two-digit index and the name', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(SizedBox(width: 120, height: 72, child: CategoryTile(index: 3, name: '반려동물용품', onTap: () => taps++))));
    expect(find.text('03'), findsOneWidget);
    await tester.tap(find.text('반려동물용품'));
    expect(taps, 1);
  });

  testWidgets('DoguNavBar scrolls sideways with a mouse drag (web mice have no horizontal wheel)', (tester) async {
    // 운영(넓은 화면)에서 마우스로는 화면 밖 칸에 닿을 수 없었다 — 웹 기본 스크롤은 마우스 끌기를 막는다.
    final items = [for (var i = 0; i < 12; i++) DoguNavItem(label: '카테고리$i')];
    await tester.pumpWidget(host(SizedBox(width: 320, child: DoguNavBar(items: items, onTap: (_) {}))));
    final position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    expect(position.pixels, 0);

    await tester.drag(find.text('카테고리1'), const Offset(-200, 0), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(100));
  });
}
