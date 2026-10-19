part of '../main.dart';

class DoguApp extends StatefulWidget {
  const DoguApp({
    super.key,
    this.store,
    this.initializeStore = true,
    this.initialTabIndex = 0,
  });

  final AppStore? store;
  final bool initializeStore;
  final int initialTabIndex;

  @override
  State<DoguApp> createState() => _DoguAppState();
}

// 5개 탭 라우트 경로 — 인덱스(0=홈 … 4=장바구니)와 1:1로 대응한다.
const List<String> kTabPaths = ['/', '/category', '/search', '/wish', '/cart'];

String pathForTabIndex(int index) =>
    (index >= 0 && index < kTabPaths.length) ? kTabPaths[index] : kTabPaths.first;

// 탭 콘텐츠 하단 여백 — 하단 탭바(+세이프에어리어)만큼 확보한다.
double _tabContentBottomPadding(BuildContext context) {
  final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
  return AppLayout.tabHeight + bottomInset + 18;
}

// 장바구니 탭은 결제바 높이만큼 여백을 더 준다.
double _cartContentBottomPadding(BuildContext context) =>
    _tabContentBottomPadding(context) + AppLayout.checkoutHeight + 18;

class _DoguAppState extends State<DoguApp> {
  late final AppStore _store;
  late final bool _ownsStore;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? AppStore();
    _ownsStore = widget.store == null;
    if (widget.initializeStore) {
      unawaited(_store.initialize());
    }
    _router = _buildRouter(pathForTabIndex(widget.initialTabIndex));
  }

  GoRouter _buildRouter(String initialLocation) {
    StatefulShellBranch tab(String path, Widget Function(BuildContext) build) {
      return StatefulShellBranch(
        routes: [GoRoute(path: path, builder: (context, state) => build(context))],
      );
    }

    return GoRouter(
      initialLocation: initialLocation,
      // 없는 경로는 홈으로 — 정적 호스팅이 모든 경로를 index.html로 폴백하므로
      // 예전 /v2 같은 죽은 링크가 라우터 에러 화면으로 떨어지지 않게 한다.
      // (errorBuilder로 에러 페이지를 그린 뒤 이동하면 셸의 GlobalKey가 중복되므로
      //  아예 라우팅 단계에서 홈으로 돌린다.)
      onException: (context, state, router) => router.go(kTabPaths.first),
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            tab('/', (c) => HomePage(bottomPadding: _tabContentBottomPadding(c))),
            tab('/category', (c) => CategoryTabPage(bottomPadding: _tabContentBottomPadding(c))),
            tab('/search', (c) => SearchTabPage(bottomPadding: _tabContentBottomPadding(c))),
            tab('/wish', (c) => WishTabPage(bottomPadding: _tabContentBottomPadding(c))),
            tab('/cart', (c) => CartTabPage(bottomPadding: _cartContentBottomPadding(c))),
          ],
        ),
        GoRoute(
          path: '/product/:id',
          builder: (context, state) {
            final extra = state.extra;
            final product = extra is ProductItem
                ? extra
                : AppStateScope.read(context).findProduct(state.pathParameters['id']!) ?? ProductItem.pending(state.pathParameters['id']!);
            return ProductDetailPage(product: product);
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    if (_ownsStore) {
      _store.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      store: _store,
      child: MaterialApp.router(
        title: '욕망의장바구니',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.bg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.accent,
            surface: AppColors.bg,
          ),
          fontFamily: doguFontFamily,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: AppColors.ink, height: 1.5),
          ),
        ),
        routerConfig: _router,
        // 전역 장바구니 토스트 — 모든 라우트 위에 떠서 결제바 유무에 따라 위치가 움직인다.
        builder: (context, child) {
          return Stack(
            children: [
              if (child != null) child,
              const CartToast(),
            ],
          );
        },
      ),
    );
  }
}


/// 앱 화면 배치 값(탭바·결제바·헤더 높이) — 디자인 토큰이 아니라 이 앱 셸의 치수라 앱에 둔다.
class AppLayout {
  // 탭 바 높이는 컴포넌트(DoguTabBar)가 정한다 — 콘텐츠 하단 여백 계산이 같은 값을 쓰게.
  static const tabHeight = DoguTabBar.barHeight;
  // 결제 바 높이는 컴포넌트(CheckoutBarView)가 정한다.
  static const checkoutHeight = CheckoutBarView.barHeight;
  // 상단 헤더 높이: IconBox(38) + 위 패딩 10 + 아래 패딩 4 — 메뉴 드롭다운이 타이틀 구간 아래로 내려오도록 기준
  static const headerHeight = 52.0;
}


enum PatternKind { dots, grid, lines, checker, cross, wave, diag, halftone }

class ApiConfig {
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    return kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';
  }

  /// 네이버 이미지 서버가 주는 축소본 너비(type=f300/f640 — f960 이상은 404). 원본은 1000px·장당
  /// 약 455KB인데 카드는 그보다 훨씬 작게 그려서, 목록은 축소본(640px 약 28KB)을 받는다.
  static const thumbnailWidths = {300, 640};

  static String imageUrl(String? url, {int? thumbnailWidth}) {
    var trimmed = url?.trim() ?? '';
    final uri = Uri.tryParse(trimmed);
    final host = uri?.host.toLowerCase() ?? '';
    if (host.endsWith('pstatic.net')) {
      if (thumbnailWidth != null && thumbnailWidths.contains(thumbnailWidth)) {
        trimmed = uri!.replace(queryParameters: {...uri.queryParameters, 'type': 'f$thumbnailWidth'}).toString();
      }
      final base = Uri.parse(baseUrl);
      return base.replace(path: '/api/proxy/image', queryParameters: {'url': trimmed}).toString();
    }
    return trimmed;
  }

  /// 화면에 넘길 이미지 주소 — 불러올 수 없으면 null('이미지 준비 중'), 네이버 이미지는 프록시·축소본으로.
  static String? displayImageUrl(String? url, {int? thumbnailWidth}) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty || !canLoadImageDirectly(trimmed)) return null;
    return imageUrl(trimmed, thumbnailWidth: thumbnailWidth);
  }

  static bool canLoadImageDirectly(String? url) {
    final host = Uri.tryParse(url?.trim() ?? '')?.host.toLowerCase() ?? '';
    return host.isNotEmpty;
  }
}

String formatWon(num value) {
  final text = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return '₩$buffer';
}

String? readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) return value.toString();
  }
  return null;
}

num? readNum(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (parsed != null) return parsed;
    }
  }
  return null;
}

List<dynamic> readList(dynamic json, List<String> keys) {
  if (json is List) return json;
  if (json is Map<String, dynamic>) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) return value;
    }
  }
  return const [];
}

PatternKind patternFor(String seed) {
  final patterns = PatternKind.values;
  return patterns[seed.codeUnits.fold<int>(0, (sum, code) => sum + code) % patterns.length];
}

class CategoryItem {
  const CategoryItem(this.name, this.count, this.pattern, {this.id = '', this.description = '', this.tone = '', this.featured = false, this.homeRank, this.imageUrl});
  final String id;
  final String name;
  final String count;
  final PatternKind pattern;
  final String description;
  final String tone;
  final bool featured;
  /// 메인화면 '카테고리' 칸의 노출 순위(1부터, 백엔드가 수요 순으로 매김). 없으면 null.
  final int? homeRank;
  final String? imageUrl;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    final id = readString(json, ['id', 'category_id', 'slug', 'key']) ?? '';
    final name = readString(json, ['name', 'title', 'label', 'category']) ?? '카테고리';
    final count = readString(json, ['count', 'product_count', 'products_count']) ?? '0';
    return CategoryItem(
      name,
      count,
      patternFor(id.isEmpty ? name : id),
      id: id,
      description: readString(json, ['description', 'subtitle', 'summary']) ?? '',
      tone: readString(json, ['tone']) ?? '',
      featured: json['featured'] == true,
      homeRank: (json['home_rank'] as num?)?.toInt(),
      imageUrl: readString(json, ['image_url', 'imageUrl', 'image']),
    );
  }
}

class ProductArtwork {
  const ProductArtwork({
    required this.hue,
    required this.saturation,
    required this.lightness,
    required this.mono,
    required this.motif,
  });

  final int hue;
  final int saturation;
  final int lightness;
  final String mono;
  final String motif;

  factory ProductArtwork.fromJson(Map<String, dynamic> json) {
    return ProductArtwork(
      hue: (json['hue'] as num?)?.round() ?? 0,
      saturation: (json['saturation'] as num?)?.round() ?? 0,
      lightness: (json['lightness'] as num?)?.round() ?? 70,
      mono: readString(json, ['mono']) ?? '◦',
      motif: readString(json, ['motif']) ?? 'circle',
    );
  }

  Map<String, dynamic> toJson() => {'hue': hue, 'saturation': saturation, 'lightness': lightness, 'mono': mono, 'motif': motif};
}

class SearchTrend {
  const SearchTrend({required this.term, required this.movement});

  final String term;
  final String movement;

  factory SearchTrend.fromJson(Map<String, dynamic> json) {
    return SearchTrend(
      term: readString(json, ['term', 'query', 'name', 'title']) ?? '',
      movement: readString(json, ['movement', 'delta', 'change']) ?? '— 유지',
    );
  }
}

class ProductItem {
  const ProductItem({
    required this.id,
    required this.brand,
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.pattern,
    this.categoryKey = 'all',
    this.categoryIds = const [],
    this.imageUrl,
    this.badge,
    this.subtitle = '',
    this.blurb = '',
    this.rating = 4.8,
    this.reviews = 0,
    this.tags = const [],
    this.artwork,
    this.meta = '4.8 · 12K',
  });

  final String id;
  final String brand;
  final String name;
  final String price;
  final String oldPrice;
  final String discount;
  final PatternKind pattern;
  final String categoryKey;
  final List<String> categoryIds;
  final String? imageUrl;
  final String? badge;
  final String subtitle;
  final String blurb;
  final double rating;
  final int reviews;
  final List<String> tags;
  final ProductArtwork? artwork;
  final String meta;

  /// 아직 정보를 못 받은 상품(상품 주소로 바로 들어온 경우). 화면은 로딩 표시를 하고
  /// 상세 응답으로 채운다 — 예전엔 엉뚱한 기본 상품을 대신 보여줬다.
  factory ProductItem.pending(String id) =>
      ProductItem(id: id, brand: '', name: '', price: '', oldPrice: '', discount: '', pattern: patternFor(id), meta: '');

  bool get isPending => name.isEmpty;

  /// 기기 저장용 스냅샷 — fromJson으로 그대로 되살아난다(장바구니·찜을 다시 열 때 표시).
  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'name': name,
        'price_text': price,
        'old_price_text': oldPrice,
        'discount_text': discount,
        'category_key': categoryKey,
        'category_ids': categoryIds,
        if (imageUrl != null) 'image_url': imageUrl,
        if (badge != null) 'badge': badge,
        'subtitle': subtitle,
        'blurb': blurb,
        'rating': rating,
        'reviews': reviews,
        'tags': tags,
        if (artwork != null) 'artwork': artwork!.toJson(),
        'meta': meta,
      };

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final id = readString(json, ['id', 'product_id', 'sku', 'slug']) ?? readString(json, ['name', 'title']) ?? 'product';
    final name = readString(json, ['name', 'title', 'product_name']) ?? '이름 없는 상품';
    final brand = readString(json, ['brand', 'brand_name', 'maker', 'vendor']) ?? 'Dogu';
    final subtitle = readString(json, ['subtitle', 'summary', 'sub_title']) ?? '';
    final salePrice = readString(json, ['price_text', 'sale_price_text']) ?? formatWon(readNum(json, ['sale_price', 'price', 'current_price']) ?? 0);
    final oldPrice = readString(json, ['old_price_text', 'original_price_text', 'compare_at_price_text']) ?? formatWon(readNum(json, ['old_price', 'original_price', 'compare_at_price']) ?? readNum(json, ['sale_price', 'price', 'current_price']) ?? 0);
    final discountText = readString(json, ['discount_text', 'discount', 'discount_label']);
    final discountNum = readNum(json, ['discount_percent', 'discount_rate']);
    final categoryIds = readList(json, ['category_ids', 'categories']).map((item) => item.toString()).where((id) => id.isNotEmpty).toList();
    final normalizedCategoryIds = categoryIds.map(_normalizeCategoryKey).toList();
    final rating = (readNum(json, ['rating']) ?? 4.8).toDouble();
    final reviews = (readNum(json, ['reviews', 'review_count']) ?? 0).round();
    final tags = readList(json, ['tags']).map((item) => item.toString()).where((tag) => tag.isNotEmpty).toList();
    final artworkJson = json['artwork'];
    return ProductItem(
      id: id,
      brand: brand,
      name: name,
      price: salePrice,
      oldPrice: oldPrice,
      discount: discountText ?? (discountNum == null ? '-0%' : '-${discountNum.round()}%'),
      pattern: patternFor(id),
      categoryKey: readString(json, ['cat', 'category_key', 'categoryKey', 'category'])?.trim().toLowerCase() ?? (normalizedCategoryIds.isNotEmpty ? normalizedCategoryIds.first : _inferCategoryKey(name, brand)),
      categoryIds: normalizedCategoryIds,
      imageUrl: readString(json, ['image_url', 'imageUrl', 'image', 'thumbnail_url', 'thumbnail', 'photo_url', 'photo']),
      badge: readString(json, ['badge', 'label', 'tag']),
      subtitle: subtitle,
      blurb: readString(json, ['blurb', 'description', 'body']) ?? '',
      rating: rating,
      reviews: reviews,
      tags: tags,
      artwork: artworkJson is Map ? ProductArtwork.fromJson(Map<String, dynamic>.from(artworkJson)) : null,
      meta: readString(json, ['meta', 'rating_text']) ?? '${rating.toStringAsFixed(1)} · ${reviews > 0 ? '$reviews reviews' : (subtitle.isNotEmpty ? subtitle : 'NEW')}',
    );
  }

  int get numericPrice => int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  int get numericOldPrice => int.tryParse(oldPrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? numericPrice;
  bool get hasDiscount => numericOldPrice > numericPrice;
}

/// Canonical category-key aliases — the single source of truth mapping every
/// raw seed id, English key, and Korean display name to its canonical key.
/// Both `_normalizeCategoryKey` (id/name → key) and the category-list name
/// lookup derive from this map, so a new category is declared in exactly one
/// place instead of being duplicated across normalization helpers.
const Map<String, String> _categoryKeyByAlias = {
  'fashion': 'clothing',
  'clothing': 'clothing',
  '의류': 'clothing',
  'gadget': 'tech',
  'tech': 'tech',
  '전자제품': 'tech',
  'home': 'home',
  'home_living': 'home',
  '홈·리빙': 'home',
  'beauty': 'beauty',
  '뷰티': 'beauty',
  'sports': 'sports',
  '스포츠': 'sports',
  'kids': 'kids',
  '키즈': 'kids',
};

String _normalizeCategoryKey(String raw) {
  final key = raw.trim().toLowerCase();
  return _categoryKeyByAlias[key] ?? key;
}

String _inferCategoryKey(String name, String brand) {
  final haystack = '$name $brand'.toLowerCase();
  if (RegExp(r'셔츠|후드|니트|티|집업|beanie|hoodie|crew|overshirt').hasMatch(haystack)) return 'clothing';
  if (RegExp(r'머그|디퓨저|노트|의자|lamp|mug|diffuser|notebook|desk|홈|리빙').hasMatch(haystack)) return 'home';
  if (RegExp(r'충전|speaker|이어|모니터|fan|bottle|tech|스피커|보온병|선풍기').hasMatch(haystack)) return 'tech';
  if (RegExp(r'cream|beauty|페이셜|크림').hasMatch(haystack)) return 'beauty';
  return 'all';
}

// instant-paint 0ms 첫 프레임 + seed·backend 모두 빈/실패 시의 최후 방어용 fallback 카탈로그.
// 손으로 옮겨 적던 카탈로그 중복을 없애고 단일 원천 seed.json에서 파생한다:
// bundled_seed.g.dart(sync_seed.py가 canonical seed.json에서 생성)의 임베드 JSON을
// 동기 파싱해 기존 fromJson으로 만든다(분류/분할 로직은 LocalSeedSource와 동일).
final Map<String, dynamic> _bundledSeed = () {
  final decoded = jsonDecode(kBundledSeedJson);
  return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
}();

Map<String, Map<String, dynamic>> _bundledSeedProductsById() {
  final result = <String, Map<String, dynamic>>{};
  for (final raw in readList(_bundledSeed, ['products']).whereType<Map>()) {
    final map = Map<String, dynamic>.from(raw);
    final id = readString(map, ['id', 'product_id', 'sku', 'slug']);
    if (id != null) result[id] = map;
  }
  return result;
}

List<ProductItem> _bundledHomeProducts(String idsKey) {
  final home = _bundledSeed['home'] is Map
      ? Map<String, dynamic>.from(_bundledSeed['home'] as Map)
      : const <String, dynamic>{};
  final byId = _bundledSeedProductsById();
  return readList(home, [idsKey])
      .map((e) => byId[e.toString()])
      .whereType<Map<String, dynamic>>()
      .map(ProductItem.fromJson)
      .toList();
}

final List<CategoryItem> fallbackCategories = readList(_bundledSeed, ['categories'])
    .whereType<Map>()
    .map((e) => CategoryItem.fromJson(Map<String, dynamic>.from(e)))
    .toList();

final List<ProductItem> fallbackDealProducts = _bundledHomeProducts('deal_product_ids');
final List<ProductItem> fallbackNewProducts = _bundledHomeProducts('new_product_ids');

