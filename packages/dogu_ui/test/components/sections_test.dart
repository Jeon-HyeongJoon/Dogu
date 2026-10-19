import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_ui/dogu_ui.dart';

import '../support.dart';

void main() {
  testWidgets('TagSection: plain tags search, removable tags search or remove', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(host(Column(children: [
      TagSection(title: '[ 01 ] 최근 검색', action: '전체 삭제', tags: const ['가디건'], onAction: () => calls.add('clear'), onTagTap: (t) => calls.add('search:$t'), onRemove: (t) => calls.add('remove:$t')),
      TagSection(title: '[ 02 ] 추천 브랜드', tags: const ['스파클Mart'], onTagTap: (t) => calls.add('brand:$t')),
    ])));
    expect(find.byType(RecentSearchTag), findsOneWidget, reason: 'onRemove가 있으면 지우기가 붙는다');
    await tester.tap(find.text('가디건'));
    await tester.tap(find.byKey(const Key('recent-remove-가디건')));
    await tester.tap(find.text('스파클Mart'));
    await tester.tap(find.text('전체 삭제'));
    expect(calls, ['search:가디건', 'remove:가디건', 'brand:스파클Mart', 'clear']);
  });

  testWidgets('TagSection shows an empty note (and hides the action), or loading dots', (tester) async {
    await tester.pumpWidget(host(const TagSection(title: '[ 01 ] 최근 검색', action: '전체 삭제', tags: [], emptyText: '최근 검색어가 없어요')));
    expect(find.text('최근 검색어가 없어요'), findsOneWidget);
    expect(find.text('전체 삭제'), findsNothing);
    await tester.pumpWidget(host(const TagSection(title: '[ 02 ] 추천 브랜드', tags: ['a'], loading: true)));
    expect(find.byType(LoadingDots), findsOneWidget);
    expect(find.text('a'), findsNothing);
  });

  testWidgets('CartLineView reports toggle, quantity and remove; shows selection and note', (tester) async {
    final calls = <String>[];
    Widget line({bool selected = false, String? note}) => host(SizedBox(
          width: 390,
          child: CartLineView(
            index: 1, brand: '스파클Mart', name: '스파클 생수 2L 12병', price: '₩9,900', oldPrice: '₩13,900', discount: '-29%', hasDiscount: true,
            quantity: 2, selected: selected, note: note,
            onToggle: () => calls.add('toggle'), onMinus: () => calls.add('minus'), onPlus: () => calls.add('plus'), onRemove: () => calls.add('remove'),
          ),
        ));
    await tester.pumpWidget(line(selected: true, note: '안내 한 줄'));
    expect(find.text('✓'), findsOneWidget);
    expect(find.text('001'), findsOneWidget);
    expect(find.text('안내 한 줄'), findsOneWidget);
    await tester.tap(find.text('+'));
    await tester.tap(find.text('−'));
    await tester.tap(find.text('삭제 ×'));
    await tester.tap(find.text('스파클 생수 2L 12병'));
    expect(calls, ['plus', 'minus', 'remove', 'toggle']);

    await tester.pumpWidget(line());
    expect(find.text('✓'), findsNothing);
    expect(find.text('안내 한 줄'), findsNothing);
  });

  testWidgets('CategoryListRow shows index, name and description', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(CategoryListRow(index: 7, name: '조명/인테리어', description: '스탠드 · 무드등', onTap: () => taps++)));
    expect(find.text('07'), findsOneWidget);
    expect(find.text('스탠드 · 무드등'), findsOneWidget);
    await tester.tap(find.text('조명/인테리어'));
    expect(taps, 1);
  });

  testWidgets('CheckoutBarView: enabled pays, disabled does not', (tester) async {
    var pays = 0;
    await tester.pumpWidget(host(CheckoutBarView(label: '결제 금액', total: '₩162,200', buttonLabel: '결제하기 (3)  →', onCheckout: () => pays++)));
    expect(tester.getSize(find.byType(CheckoutBarView)).height, CheckoutBarView.barHeight);
    await tester.tap(find.text('결제하기 (3)  →'));
    expect(pays, 1);
    await tester.pumpWidget(host(CheckoutBarView(label: '결제 금액', total: '₩0', buttonLabel: '결제하기 (0)  →', enabled: false, onCheckout: () => pays++)));
    await tester.tap(find.text('결제하기 (0)  →'));
    expect(pays, 1);
  });
}
