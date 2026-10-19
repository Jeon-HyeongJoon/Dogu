import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_ui/dogu_ui.dart';

import '../support.dart';

const _data = ProductCardData(
  brand: '스파클Mart',
  name: '스파클 생수 2L 12병',
  price: '₩9,900',
  oldPrice: '₩13,900',
  discount: '-29%',
  hasDiscount: true,
  badge: 'BEST',
  meta: '4.6 · 1237 reviews',
);

void main() {
  testWidgets('ProductCardView shows price, discount, badge and meta', (tester) async {
    await tester.pumpWidget(host(const SizedBox(width: 200, child: ProductCardView(data: _data))));
    for (final text in ['스파클Mart', '스파클 생수 2L 12병', '₩9,900', '₩13,900', 'BEST', '4.6 · 1237 reviews', 'WISH +']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('-29%'), findsNWidgets(2), reason: '이미지 위 뱃지와 가격 줄');
    expect(find.text('이미지 준비 중'), findsOneWidget, reason: '이미지 주소가 없으면 준비 중 자리');
  });

  testWidgets('ProductCardView reports taps and wishes separately', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(host(SizedBox(
      width: 200,
      child: ProductCardView(data: _data, wished: true, onTap: () => calls.add('open'), onWishTap: () => calls.add('wish')),
    )));
    expect(find.text('WISH ♥'), findsOneWidget);
    await tester.tap(find.text('WISH ♥'));
    await tester.tap(find.text('스파클 생수 2L 12병'));
    expect(calls, ['wish', 'open']);
  });

  testWidgets('ProductCardView shrinks to 0.97 while pressed', (tester) async {
    await tester.pumpWidget(host(const SizedBox(width: 200, child: ProductCardView(data: _data))));
    double scale() => tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
    expect(scale(), 1.0);
    final gesture = await tester.startGesture(tester.getCenter(find.byType(ProductCardView)));
    await tester.pump();
    expect(scale(), 0.97);
    await gesture.up();
    await tester.pump();
    expect(scale(), 1.0);
  });

  testWidgets('ProductImage shows the preparing surface without a url', (tester) async {
    await tester.pumpWidget(host(const SizedBox(width: 120, height: 120, child: ProductImage(child: Text('overlay')))));
    expect(find.byType(PreparingImageSurface), findsOneWidget);
    expect(find.text('overlay'), findsOneWidget);
  });
}
