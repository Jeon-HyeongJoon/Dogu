// 기능 모듈 테스트가 함께 쓰는 가짜 저장소·에셋 번들·HTTP 클라이언트.
// 각 모듈(test/features/<기능>/)은 이것과 fixtures.dart, harness.dart만 공유한다.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:dogu_mobile_shop/main.dart';

/// 테스트용 인메모리 AssetBundle — seed.json 대신 임의 JSON을 주입한다.
class StubAssetBundle extends CachingAssetBundle {
  StubAssetBundle(this._payload);
  final String _payload;

  @override
  Future<ByteData> load(String key) async {
    final bytes = utf8.encode(_payload);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => _payload;
}

class MissingProductRepository extends FakeRepository {
  MissingProductRepository({required this.missing});
  final Set<String> missing;

  @override
  Future<ProductItem> fetchProduct(String productId) async {
    if (missing.contains(productId)) throw ApiStatusError('/api/products/$productId', 404);
    return super.fetchProduct(productId);
  }
}

class GatedProductsRepository extends FakeRepository {
  GatedProductsRepository(this.gate, this.products);
  final Future<void> gate;
  final List<ProductItem> products;

  @override
  Future<List<ProductItem>> fetchProducts({String? section, String? categoryId, String? tag, int limit = 100}) async {
    await gate;
    return products;
  }
}

/// 상품 상세 응답을 gate가 열릴 때까지 붙잡는다 — 상품 주소로 바로 들어왔을 때의 로딩 화면.
class GatedDetailRepository extends FakeRepository {
  GatedDetailRepository(this.gate);
  final Future<void> gate;

  @override
  Future<ProductItem> fetchProduct(String productId) async {
    await gate;
    return super.fetchProduct(productId);
  }
}

class GatedRepository extends FakeRepository {
  GatedRepository(this.gate);
  final Future<void> gate;

  @override
  Future<Map<String, dynamic>> fetchHome() async {
    await gate;
    return super.fetchHome();
  }
}

class FakeRepository extends DoguRepository {
  FakeRepository({
    this.results = const [],
    this.shouldThrow = false,
    this.searchHandler,
    this.detailProduct,
    this.shouldThrowDetail = false,
    this.backendHome,
    this.backendProducts = const [],
  });

  final List<ProductItem> results;
  final bool shouldThrow;
  final Future<List<ProductItem>> Function(String query)? searchHandler;
  final ProductItem? detailProduct;
  final bool shouldThrowDetail;
  final Map<String, dynamic>? backendHome;
  final List<ProductItem> backendProducts;

  @override
  Future<Map<String, dynamic>> fetchHome() async {
    if (shouldThrow) throw Exception('offline');
    return backendHome ?? const {};
  }

  @override
  Future<List<ProductItem>> fetchProducts({String? section, String? categoryId, String? tag, int limit = 100}) async {
    if (shouldThrow) throw Exception('offline');
    return backendProducts;
  }

  @override
  Future<List<SearchTrend>> fetchTrending() async {
    if (shouldThrow) throw Exception('offline');
    return const [];
  }

  @override
  Future<List<String>> fetchSuggestions() async {
    if (shouldThrow) throw Exception('offline');
    return const [];
  }

  @override
  Future<Map<String, String>> fetchNewsletter() async {
    if (shouldThrow) throw Exception('offline');
    return const {};
  }

  @override
  Future<List<ProductItem>> searchProducts(String query, {String? categoryId}) async {
    if (searchHandler != null) return searchHandler!(query);
    if (shouldThrow) throw Exception('offline');
    return results;
  }

  @override
  Future<ProductItem> fetchProduct(String productId) async {
    if (shouldThrowDetail) throw Exception('detail offline');
    return detailProduct ??
        ProductItem(
          id: productId,
          brand: 'DETAIL',
          name: 'Fetched $productId',
          price: '₩0',
          oldPrice: '₩0',
          discount: '-0%',
          pattern: PatternKind.dots,
        );
  }

}

// 카테고리별 서버 필터링을 흉내내는 저장소 — fetchProducts(categoryId)로 다른 결과를 돌려준다
class CategoryFakeRepository extends DoguRepository {
  CategoryFakeRepository({required this.initialCatalog, required this.byCategory});
  final List<ProductItem> initialCatalog;
  final Map<String, List<ProductItem>> byCategory;

  @override
  Future<Map<String, dynamic>> fetchHome() async => const {};

  @override
  Future<List<ProductItem>> fetchProducts({String? section, String? categoryId, String? tag, int limit = 100}) async {
    if (categoryId != null && categoryId.isNotEmpty) return byCategory[categoryId] ?? const [];
    return initialCatalog;
  }

  @override
  Future<List<SearchTrend>> fetchTrending() async => const [];
  @override
  Future<List<String>> fetchSuggestions() async => const [];
  @override
  Future<Map<String, String>> fetchNewsletter() async => const {};
}

// 절대 응답하지 않는 HTTP 클라이언트 — timeout 타이머만 남아 FakeAsync 안전
class SlowHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Completer<http.StreamedResponse>().future; // 절대 complete 안 됨
}
