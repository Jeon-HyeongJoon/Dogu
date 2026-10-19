import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/fakes.dart';
import '../../support/harness.dart';

void main() {
  setUpDoguTest();

  testWidgets('wishlist tap on product card does not open detail page', (tester) async {
    final product = const ProductItem(
      id: 'wish-only',
      brand: 'DETAIL',
      name: '찜 전용 상품',
      price: '₩15,000',
      oldPrice: '₩20,000',
      discount: '-25%',
      pattern: PatternKind.cross,
    );
    final store = AppStore(repository: FakeRepository(detailProduct: product));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 220, child: ProductCard(product: ProductItem(
                id: 'wish-only',
                brand: 'DETAIL',
                name: '찜 전용 상품',
                price: '₩15,000',
                oldPrice: '₩20,000',
                discount: '-25%',
                pattern: PatternKind.cross,
              ))),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('WISH +'));
    await tester.pumpAndSettle();

    expect(store.wishlistIds.contains('wish-only'), isTrue);
    expect(find.byType(ProductDetailPage), findsNothing);
  });

  testWidgets('wishlist sale filter narrows items and shows an empty state', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
    store.newProducts = const [
      ProductItem(
        id: 'wish-sale',
        brand: 'SALE',
        name: '세일 상품',
        price: '₩10,000',
        oldPrice: '₩20,000',
        discount: '-50%',
        pattern: PatternKind.dots,
      ),
      ProductItem(
        id: 'wish-regular',
        brand: 'REGULAR',
        name: '정가 상품',
        price: '₩20,000',
        oldPrice: '₩20,000',
        discount: '-0%',
        pattern: PatternKind.grid,
      ),
    ];
    store.dealProducts = const [];
    store.wishlistIds = {'wish-sale', 'wish-regular'};

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: WishTabPage(bottomPadding: 0))),
      ),
    );

    expect(find.text('세일 상품'), findsOneWidget);
    expect(find.text('정가 상품'), findsOneWidget);

    await tester.tap(find.text('세일 중'));
    await tester.pumpAndSettle();

    expect(find.text('세일 상품'), findsOneWidget);
    expect(find.text('정가 상품'), findsNothing);

    await tester.tap(find.text('♥'));
    await tester.pumpAndSettle();

    expect(find.text('세일 중인 찜 상품이 없습니다.'), findsOneWidget);
  });
}
