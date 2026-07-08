part of '../main.dart';

class DoguRepository {
  DoguRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(ApiConfig.baseUrl);
    return base.replace(path: path, queryParameters: query);
  }

  Future<dynamic> _getJson(String path, [Map<String, String>? query, Duration timeout = const Duration(seconds: 3)]) async {
    final response = await _client.get(_uri(path, query)).timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) throw StateError('GET $path failed: ${response.statusCode}');
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<void> checkHealth() async {
    await _getJson('/health', null, const Duration(milliseconds: 1500));
  }

  Future<List<CategoryItem>> fetchCategories() async {
    final json = await _getJson('/api/categories');
    return parseCategories(json);
  }

  Future<Map<String, dynamic>> fetchHome() async {
    final json = await _getJson('/api/home', null, const Duration(seconds: 6));
    if (json is Map<String, dynamic>) return json;
    return const {};
  }

  List<CategoryItem> parseCategories(dynamic json) {
    return readList(json, ['categories', 'items', 'results']).whereType<Map>().map((item) => CategoryItem.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  List<ProductItem> parseProducts(dynamic json, List<String> keys) {
    return readList(json, keys).whereType<Map>().map((item) => ProductItem.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<List<ProductItem>> fetchProducts({String? section, String? categoryId, String? tag, int limit = 100}) async {
    final query = <String, String>{'limit': '$limit'};
    if (section != null && section.isNotEmpty) query['section'] = section;
    if (categoryId != null && categoryId.isNotEmpty) query['category_id'] = categoryId;
    if (tag != null && tag.isNotEmpty) query['tag'] = tag;
    final json = await _getJson('/api/products', query);
    return parseProducts(json, ['products', 'items', 'results']);
  }

  Future<ProductItem> fetchProduct(String productId) async {
    final json = await _getJson('/api/products/$productId');
    if (json is Map<String, dynamic>) return ProductItem.fromJson(json);
    throw StateError('Invalid product response for $productId');
  }

  Future<List<SearchTrend>> fetchTrending() async {
    final json = await _getJson('/api/search/trending');
    return readList(json, ['trending', 'items', 'terms', 'results'])
        .whereType<Map>()
        .map((item) => SearchTrend.fromJson(Map<String, dynamic>.from(item)))
        .where((trend) => trend.term.isNotEmpty)
        .toList();
  }

  Future<List<String>> fetchSuggestions() async {
    final json = await _getJson('/api/search/suggestions');
    return readList(json, ['suggestions', 'items', 'terms', 'results']).map((item) {
      if (item is Map) return readString(Map<String, dynamic>.from(item), ['term', 'query', 'name', 'title']) ?? '';
      return item.toString();
    }).where((term) => term.isNotEmpty).toList();
  }

  Future<List<ProductItem>> searchProducts(String query, {String? categoryId}) async {
    final params = <String, String>{'q': query};
    if (categoryId != null && categoryId.isNotEmpty) params['category_id'] = categoryId;
    final json = await _getJson('/api/search', params);
    return readList(json, ['products', 'items', 'results']).whereType<Map>().map((item) => ProductItem.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<Map<String, String>> fetchNewsletter() async {
    final json = await _getJson('/api/newsletter');
    if (json is! Map<String, dynamic>) return const {};
    return {
      'eyebrow': readString(json, ['eyebrow', 'subtitle', 'cadence']) ?? '— 매주 수요일 발송',
      'title': readString(json, ['title', 'headline']) ?? '조용한 신상품을\n가장 먼저.',
      'note': readString(json, ['note', 'description']) ?? '// 언제든 한 번의 클릭으로 구독 취소',
    };
  }

  Future<void> subscribeNewsletter(String email) async {
    await _client.post(
      _uri('/api/newsletter/subscribe'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'email': email}),
    ).timeout(const Duration(seconds: 4));
  }

  Future<Map<String, dynamic>> submitOrder(List<({ProductItem product, int quantity})> lines) async {
    final response = await _client.post(
      _uri('/api/orders'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'items': [
          for (final line in lines)
            {
              'product_id': line.product.id,
              'quantity': line.quantity,
            }
        ]
      }),
    ).timeout(const Duration(seconds: 4));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('POST /api/orders failed: ${response.statusCode}');
    }
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json is Map<String, dynamic>) return json;
    throw StateError('Invalid order response');
  }
}

/// 번들된 seed.json에서 카탈로그를 읽는 서버리스 데이터 소스.
/// 네트워크 없이 rootBundle만 사용하며, 백엔드 build_home 변환(ID → 상품 해석)을 재현한다.
class LocalSeedSource {
  LocalSeedSource({AssetBundle? bundle, String assetKey = 'assets/seed.json'})
      : _bundle = bundle ?? rootBundle,
        _assetKey = assetKey;

  final AssetBundle _bundle;
  final String _assetKey;
  Future<Map<String, dynamic>>? _seedFuture;

  // Future를 memoize해 병렬 호출 시 asset load/decode가 한 번만 실행되게 한다.
  Future<Map<String, dynamic>> _seed() => _seedFuture ??= _loadSeed();

  Future<Map<String, dynamic>> _loadSeed() async {
    final decoded = jsonDecode(await _bundle.loadString(_assetKey));
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> _rawProducts() async {
    final seed = await _seed();
    return readList(seed, ['products']).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, Map<String, dynamic>>> _productsById() async {
    return {
      for (final p in await _rawProducts())
        (readString(p, ['id', 'product_id', 'sku', 'slug']) ?? ''): p,
    };
  }

  Future<List<ProductItem>> fetchProducts({String? section, String? categoryId, String? tag, int limit = 100}) async {
    var items = (await _rawProducts()).map(ProductItem.fromJson).toList();
    final mappedSection = const {'deals': 'today_deal', 'new': 'new_arrival'}[section];
    if (mappedSection != null) items = items.where((p) => p.tags.contains(mappedSection)).toList();
    if (categoryId != null && categoryId.isNotEmpty) {
      // 입력 카테고리도 상품과 동일하게 정규화 (raw seed id 'gadget'/'fashion' → 'tech'/'clothing')
      final key = _normalizeCategoryKey(categoryId);
      items = items.where((p) => p.categoryKey == key || p.categoryIds.contains(key)).toList();
    }
    if (tag != null && tag.isNotEmpty) items = items.where((p) => p.tags.contains(tag)).toList();
    final capped = limit.clamp(0, items.length);
    return items.sublist(0, capped);
  }

  Future<List<CategoryItem>> fetchCategories() async {
    final seed = await _seed();
    return readList(seed, ['categories'])
        .whereType<Map>()
        .map((e) => CategoryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> fetchHome() async {
    final seed = await _seed();
    final byId = await _productsById();
    final home = seed['home'] is Map ? Map<String, dynamic>.from(seed['home'] as Map) : <String, dynamic>{};
    List<Map<String, dynamic>> resolve(List<String> keys) =>
        readList(home, keys).map((e) => byId[e.toString()]).whereType<Map<String, dynamic>>().toList();
    final collections = readList(home, ['collections']).whereType<Map>().map((raw) {
      final c = Map<String, dynamic>.from(raw);
      final ids = readList(c, ['product_ids']).map((e) => byId[e.toString()]).whereType<Map<String, dynamic>>().toList();
      return {...c, 'products': ids};
    }).toList();
    return {
      'hero': home['hero'],
      'ticker': home['ticker'],
      'nav': home['nav'],
      'editorial': home['editorial'],
      'brands': home['brands'],
      'categories': seed['categories'],
      'deal_products': resolve(['deal_product_ids']),
      'new_products': resolve(['new_product_ids']),
      'featured_product': byId[readString(home, ['featured_product_id']) ?? ''],
      'collections': collections,
      'newsletter': seed['newsletter'],
    };
  }

  Future<List<SearchTrend>> fetchTrending() async {
    final seed = await _seed();
    return readList(seed, ['trending'])
        .whereType<Map>()
        .map((e) => SearchTrend.fromJson(Map<String, dynamic>.from(e)))
        .where((t) => t.term.isNotEmpty)
        .toList();
  }

  Future<List<String>> fetchSuggestions() async {
    final seed = await _seed();
    return readList(seed, ['suggestions']).map((e) {
      if (e is Map) return readString(Map<String, dynamic>.from(e), ['term', 'query', 'name', 'title']) ?? '';
      return e.toString();
    }).where((s) => s.isNotEmpty).toList();
  }

  Future<Map<String, String>> fetchNewsletter() async {
    final seed = await _seed();
    final n = seed['newsletter'] is Map ? Map<String, dynamic>.from(seed['newsletter'] as Map) : <String, dynamic>{};
    return {
      'eyebrow': readString(n, ['eyebrow', 'subtitle', 'cadence']) ?? '— 매주 수요일 발송',
      'title': readString(n, ['title', 'headline']) ?? '조용한 신상품을\n가장 먼저.',
      'note': readString(n, ['note', 'description', 'disclaimer']) ?? '// 언제든 한 번의 클릭으로 구독 취소',
    };
  }
}

class CartLine {
  const CartLine({required this.productId, required this.quantity});
  final String productId;
  final int quantity;
}

class AppStore extends ChangeNotifier {
  AppStore({DoguRepository? repository, LocalSeedSource? seedSource})
      : _repository = repository ?? DoguRepository(),
        _seedSource = seedSource ?? LocalSeedSource();
  final DoguRepository _repository;
  final LocalSeedSource _seedSource;
  int _searchRequestVersion = 0;

  List<CategoryItem> categories = fallbackCategories;
  List<ProductItem> catalogProducts = [...fallbackNewProducts, ...fallbackDealProducts];
  List<ProductItem> dealProducts = fallbackDealProducts;
  List<ProductItem> newProducts = fallbackNewProducts;
  ProductItem? featuredProduct;
  List<ProductItem> recommendedProducts = const [];
  String heroEyebrow = '● 2026 SPRING DROP';
  String heroDate = '05.12 — 05.26';
  String heroTitle = '오늘 사고 싶은 것만, 가볍게 담아두세요.';
  String heroSubtitle = '새로 들어온 상품부터 오늘의 특가까지. 마음에 드는 것만 빠르게 골라 담는 쇼핑 리스트.';
  String heroPrimaryAction = '지금 둘러보기 →';
  String heroSecondaryAction = '노트';
  List<(String, String)> heroStats = const [('218', '신상품'), ('14', '브랜드'), ('−42%', '평균 할인')];
  List<SearchTrend> trendingItems = const [
    SearchTrend(term: '린넨 오버셔츠', movement: '▲ 12'),
    SearchTrend(term: '세라믹 푸어오버', movement: '▲ 8'),
    SearchTrend(term: '메리노 크루넥', movement: '▲ 4'),
    SearchTrend(term: '스톤웨어 머그', movement: '— 유지'),
    SearchTrend(term: '알루미늄 데스크 램프', movement: '— 유지'),
    SearchTrend(term: '시더 우드 디퓨저', movement: 'NEW'),
    SearchTrend(term: '유리 카라프', movement: '— 유지'),
    SearchTrend(term: '코튼 파자마', movement: '— 유지'),
    SearchTrend(term: '하드커버 노트북', movement: '— 유지'),
    SearchTrend(term: '소이 캔들 220g', movement: '— 유지'),
  ];
  List<String> suggestions = const ['soft·studio', 'good machine', 'objet·han', 'QUIET CO.', 'NORM /', 'slow craft'];
  List<String> recentSearches = const ['린넨 셔츠', '스피커', '머그컵', '메리노 니트', '디퓨저', 'soft·studio'];
  List<ProductItem> searchResults = const [];
  String lastSearchTerm = '';
  Set<String> wishlistIds = <String>{};
  Map<String, int> cartQuantities = {};
  Set<String> _selectedCartIds = <String>{};
  bool _cartSelectionTouched = false;
  String categoryQuickFilter = 'all';
  String? selectedCategoryKey;
  List<ProductItem> categoryProducts = const [];
  Map<String, dynamic>? lastOrderSummary;
  Map<String, String> newsletter = const {'eyebrow': '— 매주 수요일 발송', 'title': '조용한 신상품을\n가장 먼저.', 'note': '// 언제든 한 번의 클릭으로 구독 취소'};
  bool usingFallback = true;

  // 전역 장바구니 토스트 — 결제바 표시 여부에 따라 위치가 움직인다
  String? cartToastMessage;
  bool checkoutBarVisible = false;
  Timer? _cartToastTimer;
  int _cartToastSeq = 0;

  // 장바구니 담기 토스트 표시 — 일정 시간 뒤 자동 해제
  void showCartToast(String message) {
    cartToastMessage = message;
    _cartToastSeq++;
    final seq = _cartToastSeq;
    _cartToastTimer?.cancel();
    notifyListeners();
    _cartToastTimer = Timer(const Duration(seconds: 3), () {
      if (seq != _cartToastSeq) return;
      cartToastMessage = null;
      notifyListeners();
    });
  }

  // 결제바(CheckoutBar) 노출 여부 — 토스트가 그 위로 올라갈지 결정
  void setCheckoutBarVisible(bool visible) {
    if (checkoutBarVisible == visible) return;
    checkoutBarVisible = visible;
    notifyListeners();
  }

  List<ProductItem>? _allProductsCache;

  @override
  void notifyListeners() {
    _allProductsCache = null; // 데이터 변경 시 캐시 무효화
    super.notifyListeners();
  }

  @override
  void dispose() {
    _cartToastTimer?.cancel();
    super.dispose();
  }

  List<ProductItem> get allProducts {
    return _allProductsCache ??= usingFallback
        ? [...catalogProducts, ...newProducts, ...dealProducts, ...fallbackNewProducts, ...fallbackDealProducts]
        : [...catalogProducts, ...newProducts, ...dealProducts];
  }
  List<String> get trendingTerms => trendingItems.map((item) => item.term).toList();
  set trendingTerms(List<String> terms) {
    trendingItems = terms.map((term) => SearchTrend(term: term, movement: '— 유지')).toList();
  }
  int get cartCount => cartQuantities.values.fold(0, (sum, quantity) => sum + quantity);
  int get cartTotal => cartLines.fold(0, (sum, line) => sum + line.product.numericPrice * line.quantity);
  int get cartOldTotal => cartLines.fold(0, (sum, line) => sum + line.product.numericOldPrice * line.quantity);
  int get cartDiscount => cartOldTotal - cartTotal;
  List<({ProductItem product, int quantity})> get cartLines => cartQuantities.entries.map((entry) => (product: productById(entry.key), quantity: entry.value)).toList();
  Set<String> get selectedCartIds {
    if (!_cartSelectionTouched) return cartQuantities.keys.toSet();
    return _selectedCartIds.intersection(cartQuantities.keys.toSet());
  }
  List<({ProductItem product, int quantity})> get selectedCartLines => cartLines.where((line) => selectedCartIds.contains(line.product.id)).toList();
  int get selectedCartCount => selectedCartLines.fold(0, (sum, line) => sum + line.quantity);
  int get selectedCartTotal => selectedCartLines.fold(0, (sum, line) => sum + line.product.numericPrice * line.quantity);
  int get selectedCartOldTotal => selectedCartLines.fold(0, (sum, line) => sum + line.product.numericOldPrice * line.quantity);
  int get selectedCartDiscount => selectedCartOldTotal - selectedCartTotal;
  List<ProductItem> get wishlistProducts {
    final result = <ProductItem>[];
    for (final id in wishlistIds) {
      ProductItem? found;
      for (final p in allProducts) {
        if (p.id == id) { found = p; break; }
      }
      found ??= _productCache[id];
      if (found != null) result.add(found);
    }
    return result;
  }
  List<ProductItem> get categoryBrowseProducts {
    final seen = <String>{};
    Iterable<ProductItem> items = selectedCategoryKey != null
        ? categoryProducts.where((item) => seen.add(item.id))
        : allProducts.where((item) => seen.add(item.id));

    switch (categoryQuickFilter) {
      case 'new':
        items = items.where((item) => item.tags.contains('new_arrival'));
        break;
      case 'best':
        items = items.where((item) => item.rating >= 4.5 || item.badge == 'BEST');
        break;
      case 'sale':
        items = items.where((item) => item.hasDiscount);
        break;
      case 'deal':
        items = items.where((item) => item.tags.contains('today_deal'));
        break;
    }

    return items.toList();
  }

  ProductItem productById(String id) {
    for (final p in allProducts) {
      if (p.id == id) return p;
    }
    return _productCache[id] ?? fallbackNewProducts.first;
  }

  Future<void> initialize() async {
    await _loadLocalState();
    await _loadCatalogData();    // 1단계: 번들 seed로 즉시 페인트
    await _refreshFromBackend(); // 2단계: 백엔드 최신 데이터로 갱신(best-effort)
  }

  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    recentSearches = prefs.getStringList('recentSearches') ?? recentSearches;
    final savedWish = prefs.getStringList('wishlistIds');
    if (savedWish != null) {
      // drop old hardcoded fallback IDs that start with 'new-' or 'deal-'
      wishlistIds = savedWish.where((id) => !id.startsWith('new-') && !id.startsWith('deal-')).toSet();
    }
    final rawCart = prefs.getString('cartQuantities');
    if (rawCart != null) {
      final decoded = jsonDecode(rawCart);
      if (decoded is Map) {
        final loaded = decoded.map((key, value) => MapEntry(key.toString(), (value as num).toInt()));
        // drop old hardcoded fallback cart items
        cartQuantities = Map.fromEntries(
          loaded.entries.where((e) => !e.key.startsWith('new-') && !e.key.startsWith('deal-')),
        );
      }
    }
    _selectedCartIds = cartQuantities.keys.toSet();
    _cartSelectionTouched = false;
    notifyListeners();
  }

  /// instant-paint 1단계: 번들된 seed(LocalSeedSource)로 첫 화면을 즉시 채운다(네트워크 0).
  Future<void> _loadCatalogData() async {
    try {
      final results = await Future.wait<dynamic>([
        _seedSource.fetchHome(),
        _seedSource.fetchProducts(),
        _seedSource.fetchTrending(),
        _seedSource.fetchSuggestions(),
        _seedSource.fetchNewsletter(),
      ]);
      _applyCatalog(
        home: results[0] as Map<String, dynamic>,
        allCatalog: results[1] as List<ProductItem>,
        trending: results[2] as List<SearchTrend>,
        suggestions: results[3] as List<String>,
        newsletter: results[4] as Map<String, String>,
      );
      usingFallback = false;
    } catch (_) {
      usingFallback = true;
    }
    notifyListeners();
  }

  /// instant-paint 2단계: 첫 페인트 후 백엔드에서 최신/전체 데이터를 받아 덮어쓴다.
  /// 백엔드가 없거나 실패하면 조용히 번들 seed 상태를 유지한다(best-effort).
  Future<void> _refreshFromBackend() async {
    try {
      final results = await Future.wait<dynamic>([
        _repository.fetchHome(),
        _repository.fetchProducts(),
        _repository.fetchTrending(),
        _repository.fetchSuggestions(),
        _repository.fetchNewsletter(),
      ]);
      _applyCatalog(
        home: results[0] as Map<String, dynamic>,
        allCatalog: results[1] as List<ProductItem>,
        trending: results[2] as List<SearchTrend>,
        suggestions: results[3] as List<String>,
        newsletter: results[4] as Map<String, String>,
      );
      usingFallback = false;
      notifyListeners();
    } catch (_) {
      // 백엔드 미가용 → 번들 seed로 계속 동작
    }
  }

  /// home/products/trending/suggestions/newsletter를 스토어 필드에 반영한다.
  /// seed(즉시 페인트)와 backend(갱신) 양쪽이 동일 로직으로 사용한다.
  void _applyCatalog({
    required Map<String, dynamic> home,
    required List<ProductItem> allCatalog,
    required List<SearchTrend> trending,
    required List<String> suggestions,
    required Map<String, String> newsletter,
  }) {
    final hero = home['hero'] is Map<String, dynamic> ? home['hero'] as Map<String, dynamic> : const <String, dynamic>{};
    final homeCategories = _repository.parseCategories(home);
    final homeDeals = _repository.parseProducts(home, ['deal_products', 'deals', 'featured_products']);
    final homeNew = _repository.parseProducts(home, ['new_products', 'products', 'new_arrivals']);
    final homeFeaturedRaw = home['featured_product'];
    final homeFeatured = homeFeaturedRaw is Map<String, dynamic> ? ProductItem.fromJson(homeFeaturedRaw) : null;
    final homeCollections = readList(home, ['collections'])
        .whereType<Map>()
        .map((item) => _repository.parseProducts(Map<String, dynamic>.from(item), ['products']))
        .where((items) => items.isNotEmpty)
        .toList();
    categories = homeCategories.isNotEmpty ? homeCategories : (categories.isEmpty ? fallbackCategories : categories);
    catalogProducts = allCatalog.isEmpty ? catalogProducts : allCatalog;
    dealProducts = homeDeals.isNotEmpty ? homeDeals : dealProducts;
    newProducts = homeNew.isNotEmpty ? homeNew : newProducts;
    if (homeFeatured != null) featuredProduct = homeFeatured;
    if (homeCollections.isNotEmpty) recommendedProducts = homeCollections.first;
    final rawEyebrow = readString(hero, ['eyebrow']) ?? heroEyebrow;
    final eyebrowParts = rawEyebrow.split('·').map((part) => part.trim()).toList();
    heroEyebrow = eyebrowParts.isNotEmpty ? eyebrowParts.first : rawEyebrow;
    heroDate = eyebrowParts.length > 1 ? eyebrowParts.sublist(1).join(' · ') : heroDate;
    heroTitle = readString(hero, ['title']) ?? heroTitle;
    heroSubtitle = readString(hero, ['subtitle']) ?? heroSubtitle;
    heroPrimaryAction = readString(hero, ['primary_action']) ?? heroPrimaryAction;
    heroSecondaryAction = readString(hero, ['secondary_action']) ?? heroSecondaryAction;
    final stats = readList(hero, ['stats'])
        .whereType<Map>()
        .map((item) => (readString(Map<String, dynamic>.from(item), ['value']) ?? '', readString(Map<String, dynamic>.from(item), ['label']) ?? ''))
        .where((item) => item.$1.isNotEmpty || item.$2.isNotEmpty)
        .toList();
    heroStats = stats.isNotEmpty ? stats : heroStats;
    trendingItems = trending.isEmpty ? trendingItems : trending;
    this.suggestions = suggestions.isEmpty ? this.suggestions : suggestions;
    this.newsletter = newsletter.isEmpty ? this.newsletter : newsletter;
  }

  Future<void> addRecentSearch(String term) async {
    final cleaned = term.trim();
    if (cleaned.isEmpty) return;
    recentSearches = [cleaned, ...recentSearches.where((item) => item != cleaned)].take(8).toList();
    await _saveStringList('recentSearches', recentSearches);
    notifyListeners();
  }

  Future<void> performSearch(String term) async {
    final cleaned = term.trim();
    if (cleaned.isEmpty) {
      resetSearch();
      return;
    }

    final requestVersion = ++_searchRequestVersion;

    await addRecentSearch(cleaned);
    if (requestVersion != _searchRequestVersion) return;

    lastSearchTerm = cleaned;

    try {
      final results = await _repository.searchProducts(cleaned, categoryId: selectedCategoryKey);
      if (requestVersion != _searchRequestVersion) return;
      searchResults = results;
    } catch (_) {
      if (requestVersion != _searchRequestVersion) return;
      searchResults = _searchLocalProducts(cleaned);
    }

    if (requestVersion != _searchRequestVersion) return;
    notifyListeners();
  }

  void resetSearch() {
    _searchRequestVersion++;
    lastSearchTerm = '';
    searchResults = const [];
    notifyListeners();
  }

  List<ProductItem> _searchLocalProducts(String term) {
    final query = term.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final seen = <String>{};
    final searchableProducts = [...catalogProducts, ...newProducts, ...dealProducts];
    return searchableProducts.where((product) {
      final haystack = '${product.brand} ${product.name} ${product.subtitle} ${product.blurb} ${product.meta} ${product.tags.join(' ')}'.toLowerCase();
      return haystack.contains(query) && seen.add(product.id);
    }).toList();
  }

  Future<void> clearRecentSearches() async {
    recentSearches = const [];
    await _saveStringList('recentSearches', recentSearches);
    notifyListeners();
  }

  Future<void> removeRecentSearch(String term) async {
    recentSearches = recentSearches.where((item) => item != term).toList();
    await _saveStringList('recentSearches', recentSearches);
    notifyListeners();
  }

  final Map<String, ProductItem> _productCache = {};

  void cacheProduct(ProductItem product) {
    _productCache[product.id] = product;
  }

  Future<void> toggleWishlist(ProductItem product) async {
    _productCache[product.id] = product;
    if (!wishlistIds.add(product.id)) wishlistIds.remove(product.id);
    await _saveStringList('wishlistIds', wishlistIds.toList());
    notifyListeners();
  }

  Future<void> changeCartQuantity(String productId, int delta) async {
    final next = (cartQuantities[productId] ?? 0) + delta;
    cartQuantities = {...cartQuantities};
    if (next <= 0) {
      cartQuantities.remove(productId);
      _selectedCartIds = _selectedCartIds.difference({productId});
    } else {
      cartQuantities[productId] = next;
      if (!_cartSelectionTouched || delta > 0) {
        _selectedCartIds = {...selectedCartIds, productId};
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cartQuantities', jsonEncode(cartQuantities));
    notifyListeners();
  }

  void toggleCartSelection(String productId) {
    if (!cartQuantities.containsKey(productId)) return;
    final next = selectedCartIds.toSet();
    if (!next.add(productId)) next.remove(productId);
    _selectedCartIds = next;
    _cartSelectionTouched = true;
    notifyListeners();
  }

  void toggleAllCartSelection() {
    final allIds = cartQuantities.keys.toSet();
    final selectedIds = selectedCartIds;
    _selectedCartIds = selectedIds.length == allIds.length ? <String>{} : allIds;
    _cartSelectionTouched = true;
    notifyListeners();
  }

  Map<String, dynamic>? buildOrderSummary() {
    if (selectedCartLines.isEmpty) return null;
    return {
      'count': selectedCartCount,
      'total': selectedCartTotal,
      'items': selectedCartLines.map((line) => '${line.product.name} × ${line.quantity}').toList(),
    };
  }

  void rememberOrderSummary(Map<String, dynamic>? summary) {
    lastOrderSummary = summary;
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitSelectedOrder() async {
    final lines = selectedCartLines;
    if (lines.isEmpty) throw StateError('No selected cart lines');
    final response = {
      'order_id': 'ord_local_${Random().nextInt(999999).toString().padLeft(6, '0')}',
      'accepted': true,
      'items': [
        for (final line in lines)
          {
            'product_id': line.product.id,
            'name': line.product.name,
            'quantity': line.quantity,
            'unit_price': line.product.numericPrice,
            'line_total': line.product.numericPrice * line.quantity,
          }
      ],
      'item_count': selectedCartCount,
      'total_price': selectedCartTotal,
      'message': '테스트 결제가 완료되었습니다.',
    };
    rememberOrderSummary(response);
    for (final line in lines) {
      await changeCartQuantity(line.product.id, -line.quantity);
    }
    return response;
  }

  void setCategoryQuickFilter(String filter) {
    categoryQuickFilter = filter;
    notifyListeners();
  }

  Future<void> selectCategoryBrowse(String? categoryKey) async {
    if (selectedCategoryKey == categoryKey) return;
    selectedCategoryKey = categoryKey;
    if (categoryKey == null) {
      categoryProducts = const [];
      notifyListeners();
      return;
    }
    final key = _normalizeCategoryKey(categoryKey);
    // 1차(즉시): 메모리에 적재된 allProducts에서 로컬 필터로 빠른 피드백.
    //   raw seed id('gadget'/'fashion')·한글('의류')·정규화 키 모두 매칭.
    categoryProducts = allProducts
        .where((item) => item.categoryKey == key || item.categoryIds.contains(key))
        .toList();
    notifyListeners();
    // 2차(서버): 전체 카탈로그가 클 수 있으므로 해당 카테고리를 서버에서 직접 받아 보강한다.
    //   (메모리에는 limit개만 적재돼 대부분 카테고리가 비어 보이는 문제 해결)
    try {
      final fetched = await _repository.fetchProducts(categoryId: key);
      if (selectedCategoryKey != categoryKey) return; // 그새 선택이 바뀌면 무시
      if (fetched.isNotEmpty) {
        categoryProducts = fetched;
        notifyListeners();
      }
    } catch (_) {
      // 서버 미가용 → 1차 로컬 필터 결과 유지
    }
  }

  Future<ProductItem> fetchProductDetail(String productId) {
    return _repository.fetchProduct(productId);
  }

  Future<void> _saveStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }
}

class AppStateScope extends InheritedNotifier<AppStore> {
  const AppStateScope({required AppStore store, required super.child, super.key}) : super(notifier: store);
  static AppStore watch(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppStateScope>()!.notifier!;
  static AppStore read(BuildContext context) => context.getInheritedWidgetOfExactType<AppStateScope>()!.notifier!;
}

class AppShell extends StatefulWidget {
  const AppShell({this.initialIndex = 0, super.key});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  // 방문한 탭 순서 기록 — 뒤로가기로 이전 탭을 복원하기 위함
  late List<int> _tabHistory;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabHistory = [widget.initialIndex];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncCheckoutBar();
    });
  }

  // 결제바(CheckoutBar) 노출 여부를 스토어에 반영 — 전역 토스트 위치 결정에 사용
  void _syncCheckoutBar() {
    AppStateScope.read(context).setCheckoutBarVisible(_currentIndex == 4);
  }

  // 탭 전환 — 히스토리에 쌓아 뒤로가기로 되돌아갈 수 있게 한다
  void _goToTab(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _tabHistory.add(index);
      _currentIndex = index;
    });
    _syncCheckoutBar();
  }

  // 뒤로가기: 탭 히스토리가 남아 있으면 이전 탭으로 복원(앱을 벗어나지 않음)
  void _handleBack(bool didPop, Object? result) {
    if (didPop || _tabHistory.length <= 1) return;
    setState(() {
      _tabHistory.removeLast();
      _currentIndex = _tabHistory.last;
    });
    _syncCheckoutBar();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final contentBottomPadding = AppSpace.tabHeight + bottomInset + 18;
    final cartBottomPadding = contentBottomPadding + AppSpace.checkoutHeight + 18;

    return PopScope(
      // 탭 히스토리가 남아 있으면 뒤로가기를 가로채 이전 탭으로 복원
      canPop: _tabHistory.length <= 1,
      onPopInvokedWithResult: _handleBack,
      child: Scaffold(
      body: Container(
        color: AppColors.bg,
        child: SafeArea(
          top: true,
          bottom: false,
          child: AppNavigationScope(
            selectTab: _goToTab,
            currentTab: _currentIndex,
            child: Stack(
              children: [
                IndexedStack(
                  index: _currentIndex,
                  children: [
                    HomePage(bottomPadding: contentBottomPadding),
                    CategoryTabPage(bottomPadding: contentBottomPadding),
                    SearchTabPage(bottomPadding: contentBottomPadding),
                    WishTabPage(bottomPadding: contentBottomPadding),
                    CartTabPage(bottomPadding: cartBottomPadding),
                  ],
                ),
                if (_currentIndex == 4)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: AppSpace.tabHeight + bottomInset,
                    child: const CheckoutBar(),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: BottomTabs(
                    currentIndex: _currentIndex,
                    bottomInset: bottomInset,
                    onTap: _goToTab,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class AppNavigationScope extends InheritedWidget {
  const AppNavigationScope({
    required this.selectTab,
    required this.currentTab,
    required super.child,
    super.key,
  });

  final ValueChanged<int> selectTab;
  final int currentTab;

  static AppNavigationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppNavigationScope>();
  }

  static void select(BuildContext context, int index) {
    maybeOf(context)?.selectTab(index);
  }

  @override
  bool updateShouldNotify(AppNavigationScope oldWidget) =>
      oldWidget.selectTab != selectTab || oldWidget.currentTab != currentTab;
}

