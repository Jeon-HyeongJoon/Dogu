import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(colorOf('카테고리'), AppColors.accentBright);
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
    expect(tester.widget<Text>(find.text('SALE')).style!.color, AppColors.alertBright, reason: 'SALE은 빨간 포인트');
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
}
