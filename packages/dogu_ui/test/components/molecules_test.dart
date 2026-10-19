import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_ui/dogu_ui.dart';

import '../support.dart';

void main() {
  testWidgets('SectionHead shows eyebrow, title and a tappable link', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(SectionHead(index: '01', eyebrow: 'SHOP BY CATEGORY', title: '카테고리', link: '전체 →', onLinkTap: () => taps++)));
    expect(find.text('카테고리'), findsOneWidget);
    await tester.tap(find.text('전체 →'));
    expect(taps, 1);
  });

  testWidgets('SectionBorder and SoftDividerBlock wrap their child', (tester) async {
    await tester.pumpWidget(host(const Column(children: [SectionBorder(child: Text('a')), SoftDividerBlock(child: Text('b'))])));
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
  });

  testWidgets('EmptyStateBlock and SummaryLine show their texts', (tester) async {
    await tester.pumpWidget(host(const Column(children: [
      EmptyStateBlock(title: '찜한 상품이 없습니다.', body: '마음에 드는 상품을 담아 보세요.'),
      SummaryLine(label: '결제 예정 금액', value: '₩162,200', total: true),
    ])));
    for (final text in ['찜한 상품이 없습니다.', '마음에 드는 상품을 담아 보세요.', '결제 예정 금액', '₩162,200']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('QtyBox calls minus and plus', (tester) async {
    var value = 2;
    await tester.pumpWidget(host(QtyBox(value: '$value', onMinus: () => value--, onPlus: () => value++)));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('−'));
    expect(value, 3);
  });

  testWidgets('RecentSearchTag separates search and remove taps', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(host(RecentSearchTag(label: '가디건', onTap: () => calls.add('search'), onRemove: () => calls.add('remove'))));
    await tester.tap(find.text('가디건'));
    await tester.tap(find.byKey(const Key('recent-remove-가디건')));
    expect(calls, ['search', 'remove']);
  });

  testWidgets('StatGrid shows the numbers, or loading dots in the same frame', (tester) async {
    const stats = [('6', '신상품'), ('16,092', '브랜드'), ('−32%', '평균 할인')];
    // 앱처럼 높이 제한 없는 세로 배치 안에서 잰다.
    Widget grid({bool loading = false}) => Column(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 360, child: StatGrid(stats: stats, loading: loading))]);
    await tester.pumpWidget(host(grid()));
    expect(find.text('16,092'), findsOneWidget);
    final height = tester.getSize(find.byType(StatGrid)).height;

    await tester.pumpWidget(host(grid(loading: true)));
    expect(find.byType(LoadingDots), findsOneWidget);
    // 숫자 줄은 높이를 잡으려고 보이지 않게만 깔려 있다 — 화면에 보이거나 눌리지 않는다.
    expect(find.text('16,092').hitTestable(), findsNothing);
    expect(tester.getSize(find.byType(StatGrid)).height, height, reason: '로딩 자리 높이가 같아야 숫자가 나타날 때 밀리지 않는다');
  });

  testWidgets('QuickFilterRow reports the tapped index', (tester) async {
    int? selected;
    await tester.pumpWidget(host(QuickFilterRow(items: const ['전체', '신상', '베스트'], activeIndex: 0, onSelectedIndex: (i) => selected = i)));
    await tester.tap(find.text('베스트'));
    expect(selected, 2);
  });

  testWidgets('CountdownTimer ticks down once per second', (tester) async {
    await tester.pumpWidget(host(const CountdownTimer(initialSeconds: 3661)));
    expect(find.text('01:01:01'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('01:01:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // 타이머 정리
  });

  testWidgets('image surfaces: preparing placeholder and neutral surface', (tester) async {
    await tester.pumpWidget(host(const Column(children: [
      SizedBox(width: 120, height: 120, child: PreparingImageSurface()),
      SizedBox(width: 120, height: 120, child: NeutralImageSurface()),
    ])));
    expect(find.text('이미지 준비 중'), findsOneWidget);
    expect(find.byType(NeutralImageSurface), findsOneWidget);
  });
}
