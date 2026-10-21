import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_ui/dogu_ui.dart';

import '../support.dart';

void main() {
  testWidgets('MonoText and StrikeText render their text with the mono style', (tester) async {
    await tester.pumpWidget(host(const Column(children: [MonoText('001 / FEATURED'), StrikeText('₩29,000')])));
    expect(find.text('001 / FEATURED'), findsOneWidget);
    final strike = tester.widget<Text>(find.text('₩29,000'));
    expect(strike.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('Eyebrow, Tag, BadgePill and SmallChip show their labels', (tester) async {
    await tester.pumpWidget(host(const Column(children: [
      Eyebrow(index: '01', text: 'SHOP BY CATEGORY'),
      Tag(text: '● 2026 SPRING DROP'),
      BadgePill(text: 'BEST', color: AppColors.accent),
      SmallChip(text: '세일', active: true),
    ])));
    // Eyebrow는 번호와 문구를 RichText 한 줄로 그린다.
    expect(find.textContaining('[ 01 ] SHOP BY CATEGORY', findRichText: true), findsOneWidget);
    for (final label in ['2026 SPRING DROP', 'BEST', '세일']) {
      expect(find.textContaining(label), findsWidgets, reason: label);
    }
    // '● '로 시작하는 태그는 점을 글자 대신 빨간 '지금' 표시로 그린다.
    expect(find.textContaining('●'), findsNothing);
  });

  testWidgets('PriceText draws prices in the serif with lining figures', (tester) async {
    await tester.pumpWidget(host(const PriceText('₩24,900', size: 18, color: AppColors.accentBright)));
    final style = tester.widget<Text>(find.text('₩24,900')).style!;
    expect(style.fontFamily, doguSerifFontFamily);
    expect(style.fontFamilyFallback, [doguFontFamily], reason: '한글은 본문체로');
    expect(style.fontSize, 18);
    expect(style.color, AppColors.accentBright);
  });

  testWidgets('BadgePill picks a readable ink for its fill', (tester) async {
    await tester.pumpWidget(host(const Row(children: [
      BadgePill(text: 'GOLD', color: AppColors.accent),
      BadgePill(text: 'RED', color: AppColors.alert),
    ])));
    Color inkOf(String text) => tester.widget<Text>(find.text(text)).style!.color!;
    expect(inkOf('GOLD'), AppColors.invert, reason: '금 면엔 초록 글씨');
    expect(inkOf('RED'), AppColors.ink, reason: '빨간 면엔 크림 글씨');
  });

  testWidgets('AppButton calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(AppButton(text: '지금 둘러보기 →', primary: true, onTap: () => taps++)));
    await tester.tap(find.text('지금 둘러보기 →'));
    expect(taps, 1);
  });

  testWidgets('IconBox exposes its label to assistive tech and shows a badge', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(host(IconBox(icon: Icons.shopping_cart_outlined, label: '장바구니', count: '3', onTap: () => taps++)));
    expect(find.bySemanticsLabel(RegExp('장바구니')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byType(IconBox));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('NavLabel and CornerMark build', (tester) async {
    await tester.pumpWidget(host(const Column(children: [NavLabel(text: '신상품', active: true), SizedBox(width: 20, height: 20, child: CornerMark(alignment: Alignment.topLeft))])));
    expect(find.text('신상품'), findsOneWidget);
    expect(find.byType(CornerMark), findsOneWidget);
  });

  testWidgets('LoadingDots animates, and stops when animations are disabled', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(const LoadingDots()));
    expect(find.bySemanticsLabel('불러오는 중'), findsOneWidget);
    semantics.dispose();
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(const MediaQuery(data: MediaQueryData(disableAnimations: true), child: Directionality(textDirection: TextDirection.ltr, child: LoadingDots())));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('SkeletonProductCard has a light and a dark variant', (tester) async {
    Color fillOf() => (tester.widget<ColoredBox>(find.descendant(of: find.byType(AspectRatio), matching: find.byType(ColoredBox)).first)).color;
    await tester.pumpWidget(host(const SizedBox(width: 200, child: SkeletonProductCard())));
    expect(fillOf(), AppColors.bgAlt);
    await tester.pumpWidget(host(const SizedBox(width: 200, child: SkeletonProductCard(dark: true))));
    expect(fillOf(), AppColors.bgSoft);
  });
}
