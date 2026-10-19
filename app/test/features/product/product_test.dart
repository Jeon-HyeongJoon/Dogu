import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

import '../../support/fakes.dart';
import '../../support/harness.dart';

void main() {
  setUpDoguTest();

  testWidgets('product cards render the reusable fallback image surface without image URLs', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: ProductCard(product: ProductItem(
                  id: 'fallback-card',
                  brand: 'Fallback',
                  name: '기본 이미지 상품',
                  price: '₩10,000',
                  oldPrice: '₩12,000',
                  discount: '-16%',
                  pattern: PatternKind.lines,
                )),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PreparingImageSurface), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is Image && widget.image is NetworkImage), findsNothing);
  });

  testWidgets('product cards prefer network images when image URLs exist', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: ProductCard(product: ProductItem(
                  id: 'network-card',
                  brand: 'Remote',
                  name: '원격 이미지 상품',
                  price: '₩10,000',
                  oldPrice: '₩12,000',
                  discount: '-16%',
                  pattern: PatternKind.grid,
                  imageUrl: 'https://cdn.example.test/product.png',
                )),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byWidgetPredicate((widget) => widget is Image && widget.image is NetworkImage), findsOneWidget);
  });

  testWidgets('product image surface shows the unified preparing placeholder when image url is absent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 220,
            child: ProductImageSurface(
              pattern: PatternKind.grid,
              artwork: const ProductArtwork(hue: 220, saturation: 25, lightness: 70, mono: '⌬', motif: 'circle'),
              child: const Center(child: Text('Artwork overlay')),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PreparingImageSurface), findsOneWidget);
    expect(find.text('이미지 준비 중'), findsOneWidget);
    expect(find.text('Artwork overlay'), findsOneWidget);
  });

  testWidgets('product image surface preserves fallback overlay when network image loading fails', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 220,
            child: ProductImageSurface(
              pattern: PatternKind.grid,
              imageUrl: 'https://cdn.example.test/broken.png',
              child: Center(child: Text('Overlay label')),
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image).first);
    final fallback = image.errorBuilder!(tester.element(find.byType(Image).first), Exception('broken'), StackTrace.empty);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: fallback),
      ),
    );

    expect(find.byType(PreparingImageSurface), findsOneWidget);
    expect(find.text('Overlay label'), findsOneWidget);
    expect(find.text('이미지 준비 중'), findsOneWidget);
  });

  testWidgets('product image surface shows fallback while network image is still loading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 220,
            child: ProductImageSurface(
              pattern: PatternKind.diag,
              imageUrl: 'https://cdn.example.test/loading.png',
              child: Center(child: Text('Loading overlay')),
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image).first);
    final loadingFallback = image.loadingBuilder!(
      tester.element(find.byType(Image).first),
      const SizedBox.shrink(),
      const ImageChunkEvent(cumulativeBytesLoaded: 1, expectedTotalBytes: 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: loadingFallback),
      ),
    );

    expect(find.byType(PreparingImageSurface), findsOneWidget);
    expect(find.text('Loading overlay'), findsOneWidget);
  });

  testWidgets('tapping a product card opens product detail page', (tester) async {
    final detailProduct = const ProductItem(
      id: 'detail-card',
      brand: 'DETAIL',
      name: '상세 페이지 상품',
      price: '₩55,000',
      oldPrice: '₩75,000',
      discount: '-27%',
      pattern: PatternKind.diag,
      meta: '4.9 · 120 reviews',
    );
    final store = AppStore(repository: FakeRepository(detailProduct: detailProduct));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 220, child: ProductCard(product: ProductItem(
                id: 'detail-card',
                brand: 'DETAIL',
                name: '상세 페이지 상품',
                price: '₩55,000',
                oldPrice: '₩75,000',
                discount: '-27%',
                pattern: PatternKind.diag,
                meta: '4.9 · 120 reviews',
              ))),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('상세 페이지 상품'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailPage), findsOneWidget);
    expect(find.text('상세 페이지 상품'), findsWidgets);
    expect(find.text('DETAIL'), findsWidgets);
    expect(find.text('장바구니 담기'), findsOneWidget);
  });

  testWidgets('product detail refreshes with fetched product data by id', (tester) async {
    final fetchedProduct = const ProductItem(
      id: 'detail-fetch',
      brand: 'FETCHED',
      name: '서버 상세 상품',
      price: '₩88,000',
      oldPrice: '₩120,000',
      discount: '-27%',
      pattern: PatternKind.grid,
      meta: '4.8 · fetched',
    );
    final store = AppStore(repository: FakeRepository(detailProduct: fetchedProduct));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: MaterialApp(
          home: ProductDetailPage(
            product: const ProductItem(
              id: 'detail-fetch',
              brand: 'LOCAL',
              name: '로컬 상품',
              price: '₩10,000',
              oldPrice: '₩12,000',
              discount: '-16%',
              pattern: PatternKind.lines,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('서버 상세 상품'), findsOneWidget);
    expect(find.text('FETCHED'), findsWidgets);
  });

  testWidgets('product detail keeps local product when fetch fails', (tester) async {
    final store = AppStore(repository: FakeRepository(shouldThrowDetail: true));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: MaterialApp(
          home: ProductDetailPage(
            product: const ProductItem(
              id: 'detail-fallback',
              brand: 'LOCAL',
              name: '로컬 유지 상품',
              price: '₩10,000',
              oldPrice: '₩12,000',
              discount: '-16%',
              pattern: PatternKind.lines,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('로컬 유지 상품'), findsOneWidget);
    expect(find.text('LOCAL'), findsWidgets);
  });

  // ── TDD P2-2: ProductCard 탭 피드백 ──────────────────────────────────────────

  testWidgets('product card is stateful to support press animation', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              child: ProductCard(
                product: ProductItem(
                  id: 'anim-test',
                  brand: 'ANIM',
                  name: '애니메이션 테스트',
                  price: '₩10,000',
                  oldPrice: '₩12,000',
                  discount: '-16%',
                  pattern: PatternKind.dots,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // StatefulWidget으로 변환됐는지 확인 (StatelessWidget이면 throws)
    expect(tester.state(find.byType(ProductCard)), isNotNull);
  });

  testWidgets('product card scale drops to 0.97 on press and returns to 1.0 on release', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
    const product = ProductItem(
      id: 'scale-test',
      brand: 'SCALE',
      name: '스케일 테스트',
      price: '₩10,000',
      oldPrice: '₩12,000',
      discount: '-16%',
      pattern: PatternKind.dots,
    );

    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 220, child: ProductCard(product: product)),
          ),
        ),
      ),
    );

    AnimatedScale cardScale() => tester.widget<AnimatedScale>(find.byType(AnimatedScale, skipOffstage: false));

    expect(cardScale().scale, 1.0); // 초기 상태

    final gesture = await tester.startGesture(tester.getCenter(find.byType(ProductCard)));
    await tester.pump();

    expect(cardScale().scale, 0.97); // 눌린 상태

    await gesture.up();
    await tester.pumpAndSettle();

    expect(cardScale().scale, 1.0); // 복원
  });

  testWidgets('product page opened by address shows loading, then the fetched product', (tester) async {
    final store = AppStore(repository: FakeRepository(results: const []));
    await tester.pumpWidget(
      AppStateScope(
        store: store,
        child: MaterialApp(home: ProductDetailPage(product: ProductItem.pending('deep-1'))),
      ),
    );
    expect(find.byType(LoadingDots), findsOneWidget);
    await tester.pump();
    await tester.pump();
    expect(find.byType(LoadingDots), findsNothing);
    expect(find.text('Fetched deep-1'), findsWidgets);
  });

  // ── [ui] 이미지 로딩 전 placeholder를 통일된 "준비 이미지"로 ──
  testWidgets('product image surface shows the unified preparing placeholder without an image url', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 220,
            child: ProductImageSurface(pattern: PatternKind.lines),
          ),
        ),
      ),
    );
    expect(find.byType(PreparingImageSurface), findsOneWidget);
    expect(find.text('이미지 준비 중'), findsOneWidget);
    expect(find.byType(PatternBox), findsNothing, reason: '랜덤 패턴 배경 대신 준비 이미지');
  });
}
