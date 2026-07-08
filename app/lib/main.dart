import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const doguFontFamily = 'Pretendard';
const doguFontAssets = <String>[
  'assets/fonts/pretendard/Pretendard-Regular.otf',
  'assets/fonts/pretendard/Pretendard-SemiBold.otf',
  'assets/fonts/pretendard/Pretendard-Bold.otf',
  'assets/fonts/pretendard/Pretendard-ExtraBold.otf',
];

// 첫 페인트 전에 먼저 등록할 필수 폰트 — 한글 글리프가 포함된 기본 본문체(Pretendard Regular).
// 이게 없으면 첫 프레임에서 한글이 fallback(한글 없음) 폰트로 그려져 ⊠(두부) 박스가 보인다.
const doguEssentialFontAssets = <String>[
  'assets/fonts/pretendard/Pretendard-Regular.otf',
];

// 메인 광고(히어로) 헤드라인/타이틀 전용 — 굴림 느낌의 둥근 고딕
// Pretendard와 동일하게 assets: + 런타임 FontLoader로 등록한다.
// (FontLoader는 각 파일의 내장 굵기를 인식해 굵기 매칭이 정상 동작 — 웹 CanvasKit에서 FontManifest 다중 굵기 매칭이 어긋나는 문제 회피)
const doguHeroFontFamily = 'NanumSquareRound';
const doguHeroFontAssets = <String>[
  'assets/fonts/nanumsquareround/NanumSquareRoundL.ttf',
  'assets/fonts/nanumsquareround/NanumSquareRoundR.ttf',
  'assets/fonts/nanumsquareround/NanumSquareRoundB.ttf',
  'assets/fonts/nanumsquareround/NanumSquareRoundEB.ttf',
];

typedef AppRunner = void Function(Widget app);

void main() => bootstrap();

/// 첫 페인트에서 한글이 ⊠(두부) 박스로 보이지 않도록, 한글 글리프가 있는 필수 본문체
/// (Pretendard Regular, 약 1.5MB)만 첫 페인트 전에 먼저 로드한다.
/// 나머지 굵기·둥근 헤더체는 첫 프레임 이후 비차단 로드해 첫 페인트 지연을 최소화한다.
/// 로드된 폰트가 등록되면 system fonts change 알림으로 텍스트 레이아웃이 재계산된다.
Future<void> bootstrap({
  AppRunner runner = runApp,
  Future<void> Function()? loadFonts,
  Future<void> Function()? loadEssentialFont,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  // 한글 두부 박스 방지: 필수 폰트는 첫 페인트 전에 등록(실패해도 fallback으로 계속)
  await (loadEssentialFont ?? loadDoguEssentialFont)().catchError(_onFontLoadError);
  runner(const DoguApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited((loadFonts ?? loadDoguFonts)().catchError(_onFontLoadError));
  });
}

void _onFontLoadError(Object error, StackTrace stack) {
  // release에선 fallback 폰트로 조용히 진행, debug/profile에선 진단만 남긴다.
  if (kDebugMode || kProfileMode) {
    debugPrint('폰트 로드 실패(폴백 폰트로 계속): $error');
  }
}

Future<void> loadDoguEssentialFont() {
  return _loadFontFamily(doguFontFamily, doguEssentialFontAssets);
}

Future<void> loadDoguFonts() async {
  await Future.wait([
    _loadFontFamily(doguFontFamily, doguFontAssets),
    _loadFontFamily(doguHeroFontFamily, doguHeroFontAssets),
  ]);
}

Future<void> _loadFontFamily(String family, List<String> assets) {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  return loader.load();
}

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

class _DoguAppState extends State<DoguApp> {
  late final AppStore _store;
  late final bool _ownsStore;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? AppStore();
    _ownsStore = widget.store == null;
    if (widget.initializeStore) {
      unawaited(_store.initialize());
    }
  }

  @override
  void dispose() {
    if (_ownsStore) {
      _store.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      store: _store,
      child: MaterialApp(
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
        home: AppShell(initialIndex: widget.initialTabIndex),
        // 전역 장바구니 토스트 — 모든 라우트 위에 떠서 결제바 유무에 따라 위치가 움직인다
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

class AppColors {
  static const bg = Color(0xffffffff);
  static const bgSoft = Color(0xfffafafa);
  static const bgAlt = Color(0xfff4f4f3);
  static const shell = Color(0xffededeb);
  static const ink = Color(0xff0a0a0a);
  static const ink2 = Color(0xff2a2a2a);
  static const ink3 = Color(0xff6b6b6b);
  static const ink4 = Color(0xffa3a3a3);
  static const line = Color(0xffe6e6e5);
  static const lineSoft = Color(0xffefefee);
  static const accent = Color(0xff13402d);
  static const accentSoft = Color(0xffeef4f0);
  static const accentBright = Color(0xff1f8a5b);
  static const accentDeep = Color(0xff14533a);
  static const alert = Color(0xffff3b1f);
  static const invert = Color(0xfffafafa);
  // 메인 광고(히어로) 전용 — 진한 회색 배경 위 밝은 회색 글씨
  static const heroBg = Color(0xff1c1c1c);
  static const heroInk = Color(0xffd6d6d6);
  static const heroInk2 = Color(0xffc2c2c2);
  static const heroInk3 = Color(0xff9a9a9a);
  static const heroLine = Color(0xff3a3a3a);
  // eyebrow 태그(2026 SPRING DROP) — 밝은 회색 배경 + 검은 글씨
  static const heroChip = Color(0xffd6d6d6);
}


class AppSpace {
  static const pad = 20.0;
  static const maxMobileWidth = 390.0;
  static const tabHeight = 70.0;
  static const checkoutHeight = 83.0;
  // 상단 헤더 높이: IconBox(38) + 위 패딩 10 + 아래 패딩 4 — 메뉴 드롭다운이 타이틀 구간 아래로 내려오도록 기준
  static const headerHeight = 52.0;
}

const monoStyle = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: [doguFontFamily],
  letterSpacing: 0.1,
);

enum PatternKind { dots, grid, lines, checker, cross, wave, diag, halftone }

class ApiConfig {
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    return kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';
  }

  static String imageUrl(String? url) {
    final trimmed = url?.trim() ?? '';
    final uri = Uri.tryParse(trimmed);
    final host = uri?.host.toLowerCase() ?? '';
    if (host.endsWith('pstatic.net')) {
      final base = Uri.parse(baseUrl);
      return base.replace(path: '/api/proxy/image', queryParameters: {'url': trimmed}).toString();
    }
    return trimmed;
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
  const CategoryItem(this.name, this.count, this.pattern, {this.id = '', this.description = '', this.tone = '', this.featured = false, this.imageUrl});
  final String id;
  final String name;
  final String count;
  final PatternKind pattern;
  final String description;
  final String tone;
  final bool featured;
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

String _normalizeCategoryKey(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'fashion':
    case 'clothing':
    case '의류':
      return 'clothing';
    case 'gadget':
    case 'tech':
    case '전자제품':
      return 'tech';
    case 'home':
    case 'home_living':
    case '홈·리빙':
      return 'home';
    case 'beauty':
    case '뷰티':
      return 'beauty';
    case 'sports':
    case '스포츠':
      return 'sports';
    case 'kids':
    case '키즈':
      return 'kids';
    default:
      return raw.trim().toLowerCase();
  }
}

String _inferCategoryKey(String name, String brand) {
  final haystack = '$name $brand'.toLowerCase();
  if (RegExp(r'셔츠|후드|니트|티|집업|beanie|hoodie|crew|overshirt').hasMatch(haystack)) return 'clothing';
  if (RegExp(r'머그|디퓨저|노트|의자|lamp|mug|diffuser|notebook|desk|홈|리빙').hasMatch(haystack)) return 'home';
  if (RegExp(r'충전|speaker|이어|모니터|fan|bottle|tech|스피커|보온병|선풍기').hasMatch(haystack)) return 'tech';
  if (RegExp(r'cream|beauty|페이셜|크림').hasMatch(haystack)) return 'beauty';
  return 'all';
}

const fallbackCategories = [
  CategoryItem('의류', '412', PatternKind.dots),
  CategoryItem('전자제품', '186', PatternKind.grid),
  CategoryItem('홈·리빙', '298', PatternKind.lines),
  CategoryItem('뷰티', '154', PatternKind.checker),
  CategoryItem('스포츠', '87', PatternKind.cross),
  CategoryItem('키즈', '112', PatternKind.wave),
];

const fallbackDealProducts = [
  ProductItem(
    id: 'deal-lumio-lamp',
    brand: 'Lumio',
    name: 'LED 무드 테이블 램프',
    price: '₩12,900',
    oldPrice: '₩32,000',
    discount: '-60%',
    pattern: PatternKind.grid,
    categoryKey: 'home',
    badge: 'TODAY',
    meta: '07:42 left',
  ),
  ProductItem(
    id: 'deal-glowlab-cream',
    brand: 'GlowLab',
    name: '콜라겐 페이셜 크림',
    price: '₩18,000',
    oldPrice: '₩39,000',
    discount: '-53%',
    pattern: PatternKind.dots,
    categoryKey: 'beauty',
    badge: 'BEAUTY',
    meta: '8560 reviews',
  ),
  ProductItem(
    id: 'deal-outly-lantern',
    brand: 'Outly',
    name: '캠핑용 LED 충전식 랜턴',
    price: '₩19,800',
    oldPrice: '₩38,000',
    discount: '-48%',
    pattern: PatternKind.wave,
    categoryKey: 'tech',
    badge: 'LIMITED',
    meta: 'IPX4',
  ),
];

const fallbackNewProducts = [
  ProductItem(
    id: 'new-novatech-charger',
    brand: 'NovaTech',
    name: '폴더블 무선 충전 거치대 3 in 1',
    price: '₩24,900',
    oldPrice: '₩49,000',
    discount: '-49%',
    pattern: PatternKind.cross,
    categoryKey: 'tech',
    badge: 'BEST',
    meta: '4.8 · 12K',
  ),
  ProductItem(
    id: 'new-thermogo-bottle',
    brand: 'ThermoGo',
    name: '스테인리스 진공 보온병 1L',
    price: '₩14,500',
    oldPrice: '₩28,000',
    discount: '-48%',
    pattern: PatternKind.lines,
    categoryKey: 'tech',
    meta: '24H warm',
  ),
  ProductItem(
    id: 'new-breezy-fan',
    brand: 'Breezy',
    name: '미니 휴대용 핸디 선풍기',
    price: '₩9,800',
    oldPrice: '₩19,900',
    discount: '-51%',
    pattern: PatternKind.dots,
    categoryKey: 'tech',
    badge: 'NEW',
    meta: '6h battery',
  ),
  ProductItem(
    id: 'new-dailyfits-hoodie',
    brand: 'Daily.fits',
    name: '오버사이즈 코튼 후드 집업',
    price: '₩22,000',
    oldPrice: '₩45,000',
    discount: '-51%',
    pattern: PatternKind.checker,
    categoryKey: 'clothing',
    badge: 'NEW',
    meta: 'unisex',
  ),
  ProductItem(
    id: 'new-ergosit-chair',
    brand: 'ErgoSit',
    name: '오피스 인체공학 메쉬 의자',
    price: '₩89,000',
    oldPrice: '₩159,000',
    discount: '-44%',
    pattern: PatternKind.diag,
    categoryKey: 'home',
    badge: 'LIMITED',
    meta: '5yr care',
  ),
  ProductItem(
    id: 'new-flowline-yoga-mat',
    brand: 'FlowLine',
    name: '실리콘 미끄럼방지 요가 매트 6mm',
    price: '₩21,800',
    oldPrice: '₩49,000',
    discount: '-56%',
    pattern: PatternKind.wave,
    categoryKey: 'beauty',
    meta: '6mm',
  ),
];

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

class HomePage extends StatelessWidget {
  const HomePage({required this.bottomPadding, super.key});
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('home-tab'),
      slivers: [
        const SliverToBoxAdapter(child: Header()),
        const SliverToBoxAdapter(child: SearchBarBlock()),
        const SliverToBoxAdapter(child: CategoryNav()),
        const SliverToBoxAdapter(child: HeroBlock()),
        const SliverToBoxAdapter(child: TickerStrip()),
        const SliverToBoxAdapter(child: CategorySection()),
        const SliverToBoxAdapter(child: DealSection()),
        const SliverToBoxAdapter(child: ProductSection()),
        const SliverToBoxAdapter(child: BrandSection()),
        const SliverToBoxAdapter(child: NewsletterSection()),
        const SliverToBoxAdapter(child: FooterSection()),
        SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
      ],
    );
  }
}
class Header extends StatelessWidget {
  const Header({super.key});

  void _openMenu(BuildContext context) {
    final navigation = AppNavigationScope.maybeOf(context);
    final currentTab = navigation?.currentTab ?? 0;
    void selectTab(int index) => navigation?.selectTab(index);

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '메뉴 닫기',
      // 기본 배리어는 투명 — 어둡게 하는 처리는 헤더 아래 영역만 커스텀 dim으로 직접
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, __) {
        void choose(int index) {
          Navigator.of(dialogContext).pop();
          selectTab(index);
        }

        final reveal = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

        const items = [
          (Icons.home_outlined, '홈', 0),
          (Icons.grid_view_outlined, '카테고리', 1),
          (Icons.search, '검색', 2),
          (Icons.favorite_border, '찜', 3),
          (Icons.shopping_cart_outlined, '장바구니', 4),
        ];

        return Stack(
          children: [
            // 상단 타이틀(헤더) 영역은 어둡게 하지 않고, 그 아래 공간만 어둡게 — 탭은 배리어로 통과시켜 닫기 유지
            Positioned.fill(
              child: IgnorePointer(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpace.headerHeight),
                    child: Container(color: Colors.black54),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Material(
                type: MaterialType.transparency,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    // 상단 타이틀 구간(헤더) 아래로 내려오도록 헤더 높이만큼 띄워 일체감 확보
                    padding: const EdgeInsets.only(top: AppSpace.headerHeight),
                // 헤더 하단 라인을 전경에 항상 고정 — 이 라인에서 메뉴가 빠져나오는 것처럼
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.line)),
                  ),
                  // 헤더 하단 라인에서부터 말려 내려오는 효과: 패널을 잘라낸 뒤 위에서 아래로 슬라이드
                  child: ClipRect(
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(reveal),
                      child: Container(
                      key: const ValueKey('menuDropdown'),
                      width: double.infinity,
                      // 상단 바와 일체화: 좌우/상단 여백 없이 풀폭, 하단 경계선만(바가 아래로 확장된 느낌)
                      decoration: const BoxDecoration(
                        color: AppColors.bg,
                        border: Border(bottom: BorderSide(color: AppColors.line)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(AppSpace.pad, 16, AppSpace.pad, 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: MonoText('MENU', size: 12, color: AppColors.ink3, weight: FontWeight.w700),
                            ),
                          ),
                          for (final item in items)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => choose(item.$3),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad, vertical: 16),
                                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.lineSoft))),
                                child: Row(
                                  children: [
                                    Icon(item.$1, size: 23, color: item.$3 == currentTab ? AppColors.accent : AppColors.ink3),
                                    const SizedBox(width: 14),
                                    Text(item.$2, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: item.$3 == currentTab ? AppColors.accent : AppColors.ink)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
            ),
            ),
          ],
        );
      },
      transitionBuilder: (_, animation, __, child) {
        // 슬라이드는 헤더 라인 아래 ClipRect 안에서 처리하므로, 여기선 가벼운 페이드만
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = AppStateScope.watch(context).cartCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 10, AppSpace.pad, 4),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          IconBox(icon: Icons.menu, label: '메뉴', onTap: () => _openMenu(context)),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/logo-square.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 9),
                const Text(
                  '욕망의 장바구니',
                  style: TextStyle(
                    fontFamily: doguHeroFontFamily,
                    fontFamilyFallback: [doguFontFamily],
                    color: AppColors.accent,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconBox(icon: Icons.search, label: '검색', onTap: () => AppNavigationScope.select(context, 2)),
              const SizedBox(width: 8),
              IconBox(icon: Icons.shopping_cart_outlined, label: '장바구니', inverted: true, count: cartCount > 0 ? cartCount.toString() : null, onTap: () => AppNavigationScope.select(context, 4)),
            ],
          ),
        ],
      ),
    );
  }
}

class IconBox extends StatelessWidget {
  const IconBox({
    required this.icon,
    required this.label,
    this.inverted = false,
    this.count,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool inverted;
  final String? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: inverted ? AppColors.accent : AppColors.bg,
                  border: Border.all(color: inverted ? AppColors.accent : AppColors.line),
                ),
                child: Icon(icon, size: 18, color: inverted ? AppColors.invert : AppColors.ink),
              ),
              if (count != null)
                Positioned(
                  top: -5,
                  right: -1,
                  child: BadgePill(text: count!, color: AppColors.alert, compact: true),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchBarBlock extends StatelessWidget {
  const SearchBarBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 12, AppSpace.pad, 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => AppNavigationScope.select(context, 2),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.bgSoft,
            border: Border.all(color: AppColors.line),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, size: 16, color: AppColors.ink3),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '찾고 싶은 욕망을 입력하세요',
                  style: TextStyle(fontSize: 13, color: AppColors.ink4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryNav extends StatelessWidget {
  const CategoryNav({super.key});

  @override
  Widget build(BuildContext context) {
    const items = ['신상품', '베스트', '의류', '홈·리빙', '전자제품', '뷰티', 'SALE'];
    const mappings = <String, (String, String?)>{
      '신상품': ('new', null),
      '베스트': ('best', null),
      '의류': ('all', 'clothing'),
      '홈·리빙': ('all', 'home'),
      '전자제품': ('all', 'tech'),
      '뷰티': ('all', 'beauty'),
      'SALE': ('sale', null),
    };
    final store = AppStateScope.watch(context);
    final currentFilter = store.categoryQuickFilter;
    final currentCategory = store.selectedCategoryKey;
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 12, AppSpace.pad, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final mapping = mappings[items[i]]!;
                  AppStateScope.read(context).setCategoryQuickFilter(mapping.$1);
                  AppStateScope.read(context).selectCategoryBrowse(mapping.$2);
                  AppNavigationScope.select(context, 1);
                },
                child: NavLabel(
                  text: items[i],
                  sale: items[i] == 'SALE',
                  active: mappings[items[i]]!.$1 == currentFilter &&
                      mappings[items[i]]!.$2 == currentCategory,
                ),
              ),
              if (i != items.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 11),
                  child: Text('|', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300, color: AppColors.ink4)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class NavLabel extends StatelessWidget {
  const NavLabel({required this.text, this.active = false, this.sale = false, super.key});
  final String text;
  final bool active;
  final bool sale;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: sale ? FontWeight.w700 : FontWeight.w500,
            color: sale ? AppColors.accent : (active ? AppColors.ink : AppColors.ink3),
          ),
        ),
        const SizedBox(height: 14),
        Container(width: active ? 42 : 0, height: 2, color: active ? AppColors.ink : Colors.transparent),
      ],
    );
  }
}

class HeroBlock extends StatelessWidget {
  const HeroBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return SectionBorder(
      child: Container(
        color: AppColors.heroBg,
        padding: const EdgeInsets.fromLTRB(AppSpace.pad, 28, AppSpace.pad, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Tag(text: store.heroEyebrow, dark: true),
                const SizedBox(width: 10),
                MonoText(store.heroDate, size: 10.5, color: AppColors.heroInk3),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              store.heroTitle.replaceFirst(', ', ',\n'),
              style: const TextStyle(
                fontFamily: doguFontFamily,
                color: Colors.white,
                fontSize: 44,
                height: 1.08,
                fontWeight: FontWeight.w400,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              store.heroSubtitle,
              style: const TextStyle(fontSize: 13.5, color: AppColors.heroInk2, height: 1.6),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: AppButton(text: store.heroPrimaryAction, primary: true, onDark: true, onTap: () => AppNavigationScope.select(context, 1))),
                const SizedBox(width: 8),
                AppButton(text: store.heroSecondaryAction, onDark: true, onTap: () => AppNavigationScope.select(context, 2)),
              ],
            ),
            const SizedBox(height: 28),
            StatGrid(stats: store.heroStats, dark: true),
            if (store.featuredProduct != null) ...[
              const SizedBox(height: 22),
              const FeaturedCard(),
            ],
          ],
        ),
      ),
    );
  }
}

class StatGrid extends StatelessWidget {
  const StatGrid({required this.stats, this.dark = false, super.key});

  final List<(String, String)> stats;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final lineColor = dark ? AppColors.heroLine : AppColors.line;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: lineColor), bottom: BorderSide(color: lineColor)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++)
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 12, right: 8),
                decoration: BoxDecoration(
                  border: i == 0 ? null : Border(left: BorderSide(color: lineColor)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoText(stats[i].$1, size: 20, weight: FontWeight.w500, color: dark ? AppColors.heroInk : AppColors.ink),
                    const SizedBox(height: 2),
                    MonoText(stats[i].$2, size: 10.5, color: dark ? AppColors.heroInk3 : AppColors.ink4),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final featured = AppStateScope.watch(context).featuredProduct;
    if (featured == null) {
      return Container(
        decoration: BoxDecoration(color: AppColors.bgAlt, border: Border.all(color: AppColors.line)),
        child: const AspectRatio(
          aspectRatio: 4 / 5,
          child: NeutralImageSurface(),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(color: AppColors.bgAlt, border: Border.all(color: AppColors.line)),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: ProductImageSurface(
              pattern: featured.pattern,
              imageUrl: featured.imageUrl,
              artwork: featured.artwork,
              child: Stack(
                children: [
                  const Positioned(top: 12, left: 12, child: MonoText('001 / FEATURED', size: 9.5, color: AppColors.ink3)),
                  if (featured.badge != null) Positioned(top: 12, right: 12, child: BadgePill(text: featured.badge!, color: AppColors.accent)),
                ],
              ),
            ),
          ),
          Container(height: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.all(14),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(
                      product: featured,
                      onGoToCart: () => AppNavigationScope.select(context, 4),
                    ),
                  ),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(featured.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        MonoText(featured.brand, size: 11, color: AppColors.ink3),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (featured.hasDiscount) StrikeText(featured.oldPrice),
                      MonoText(featured.price, size: 14.5, color: AppColors.accent, weight: FontWeight.w700),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TickerStrip extends StatefulWidget {
  const TickerStrip({super.key});

  @override
  State<TickerStrip> createState() => _TickerStripState();
}

class _TickerStripState extends State<TickerStrip> {
  final ScrollController _sc = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  void _startScroll() {
    if (!mounted || !_sc.hasClients) return;
    final half = _sc.position.maxScrollExtent;
    if (half <= 0) return;
    // 28초 주기, 50ms 간격으로 위치를 직접 이동
    // animateTo 대신 jumpTo를 사용해 테스트의 pumpAndSettle과 충돌하지 않음
    const intervalMs = 50;
    final step = half * intervalMs / 28000;
    _timer = Timer.periodic(const Duration(milliseconds: intervalMs), (_) {
      if (!mounted || !_sc.hasClients) return;
      var next = _sc.offset + step;
      if (next >= half) next -= half;
      _sc.jumpTo(next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const items = ['FREE SHIPPING', '14-DAY RETURNS', '매일 오후 2시 신상', '12개월 할부', '리퍼브 · 빈티지'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        color: AppColors.bgSoft,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: SingleChildScrollView(
        controller: _sc,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            const SizedBox(width: AppSpace.pad),
            for (final item in [...items, ...items]) ...[
              MonoText(item, size: 10.5, color: AppColors.ink2),
              Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 22), color: AppColors.ink3),
            ],
          ],
        ),
      ),
    );
  }
}

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = AppStateScope.watch(context).categories;
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        children: [
          SectionHead(index: '01', eyebrow: 'SHOP BY CATEGORY', title: '카테고리', link: '전체 →', onLinkTap: () => AppNavigationScope.select(context, 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: items.length > 9 ? 9 : items.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisExtent: 72,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) => CategoryCard(index: index + 1, item: items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({required this.index, required this.item, super.key});
  final int index;
  final CategoryItem item;

  String? _categoryKey() {
    switch (item.name) {
      case '의류':
        return 'clothing';
      case '홈·리빙':
        return 'home';
      case '전자제품':
        return 'tech';
      case '뷰티':
        return 'beauty';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppStateScope.read(context).setCategoryQuickFilter('all');
        AppStateScope.read(context).selectCategoryBrowse(item.id.isEmpty ? _categoryKey() : _normalizeCategoryKey(item.id));
        AppNavigationScope.select(context, 1);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MonoText(index.toString().padLeft(2, '0'), size: 8.5, color: AppColors.ink4),
            const SizedBox(height: 5),
            Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            MonoText(item.count, size: 8.5, color: AppColors.ink3),
          ],
        ),
      ),
    );
  }
}

// 매초 카운트다운 텍스트만 업데이트 — DealSection 전체 rebuild 방지
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({required this.initialSeconds, super.key});
  final int initialSeconds;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late final ValueNotifier<int> _seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _seconds = ValueNotifier(widget.initialSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds.value > 0) _seconds.value -= 1;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _seconds.dispose();
    super.dispose();
  }

  static String _format(int total) {
    final h = (total ~/ 3600).toString().padLeft(2, '0');
    final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _seconds,
      builder: (_, remaining, __) =>
          MonoText(_format(remaining), size: 18, color: AppColors.invert, weight: FontWeight.w600),
    );
  }
}

class DealSection extends StatelessWidget {
  const DealSection({super.key});

  static const int _initialCountdownSeconds = (7 * 60 * 60) + (42 * 60) + 18;

  @override
  Widget build(BuildContext context) {
    final items = AppStateScope.watch(context).dealProducts;
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 36),
      padding: const EdgeInsets.symmetric(vertical: 32),
      color: AppColors.ink,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(index: '02', text: 'TODAY ONLY', inverted: true),
                    Text('오늘의 딜', style: TextStyle(fontSize: 34, height: 1, color: AppColors.invert, fontWeight: FontWeight.w800, letterSpacing: -1.2)),
                  ],
                ),
                const CountdownTimer(initialSeconds: _initialCountdownSeconds),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad),
            child: Row(
              children: [
                for (final product in items) ...[
                  SizedBox(width: 200, child: ProductCard(product: product, dark: true)),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductSection extends StatelessWidget {
  const ProductSection({super.key});

  static const initialVisibleCount = 8;
  static const loadMoreCount = 8;

  @override
  Widget build(BuildContext context) {
    return const ProductSectionContent();
  }
}

class ProductSectionContent extends StatefulWidget {
  const ProductSectionContent({super.key});

  @override
  State<ProductSectionContent> createState() => _ProductSectionContentState();
}

class _ProductSectionContentState extends State<ProductSectionContent> {
  int _visibleCount = ProductSection.initialVisibleCount;
  String _activeFilter = 'all';

  List<ProductItem> _filterProducts(List<ProductItem> items) {
    if (_activeFilter == 'all') return items;
    return items.where((item) => item.categoryKey == _activeFilter).toList();
  }

  void _showMore(int total) {
    setState(() {
      _visibleCount = (_visibleCount + ProductSection.loadMoreCount).clamp(0, total).toInt();
    });
  }

  void _selectFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      _visibleCount = ProductSection.initialVisibleCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);

    if (store.usingFallback) {
      return Padding(
        padding: const EdgeInsets.only(top: 36),
        child: Column(
          children: [
            const SectionHead(index: '03', eyebrow: 'NEW ARRIVALS', title: '이번 주 신상품'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.58,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 12,
                ),
                itemCount: ProductSection.initialVisibleCount,
                itemBuilder: (_, __) => const SkeletonProductCard(),
              ),
            ),
          ],
        ),
      );
    }

    final newProds = store.newProducts;
    final newIds = newProds.map((p) => p.id).toSet();
    final supplement = store.catalogProducts.where((p) => !newIds.contains(p.id)).toList();
    final items = [...newProds, ...supplement];
    final filteredItems = _filterProducts(items);
    final visibleItems = filteredItems.take(_visibleCount).toList();
    final hasMore = visibleItems.length < filteredItems.length;
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        children: [
          const SectionHead(index: '03', eyebrow: 'NEW ARRIVALS', title: '이번 주 신상품'),
          ChipRow(activeFilter: _activeFilter, onSelected: _selectFilter),
          Padding(
            // 좌우 AppSpace.pad만큼 들여쓰기 → 상품 이미지와 동일한 인셋
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad),
            child: Column(
              children: [
                for (var row = 0; row * 2 < visibleItems.length; row++) ...[
                  if (row > 0)
                    // 줄 구분 가로선: 상품 이미지가 양 끝에서 떨어진 만큼(좌우 패딩)만 차지
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, thickness: 1, color: AppColors.line),
                    ),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: ProductCard(product: visibleItems[row * 2])),
                        const SizedBox(width: 12),
                        Expanded(
                          child: row * 2 + 1 < visibleItems.length
                              ? ProductCard(product: visibleItems[row * 2 + 1])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.pad, 28, AppSpace.pad, 0),
              child: AppButton(text: '더 보기  +8', large: true, onTap: () => _showMore(filteredItems.length)),
            ),
        ],
      ),
    );
  }
}

class ChipRow extends StatelessWidget {
  const ChipRow({required this.activeFilter, required this.onSelected, super.key});

  final String activeFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const chips = [
      ('전체', 'all'),
      ('의류', 'clothing'),
      ('홈', 'home'),
      ('테크', 'tech'),
      ('뷰티', 'beauty'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 0, AppSpace.pad, 16),
      child: Row(
        children: [
          for (final chip in chips)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(chip.$2),
              child: Container(
                height: 30,
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: chip.$2 == activeFilter ? AppColors.accent : AppColors.bg,
                  border: Border.all(color: chip.$2 == activeFilter ? AppColors.accent : AppColors.line),
                ),
                child: Text(chip.$1, style: TextStyle(fontSize: 12, color: chip.$2 == activeFilter ? AppColors.invert : AppColors.ink2)),
              ),
            ),
        ],
      ),
    );
  }
}

class ProductImageSurface extends StatelessWidget {
  const ProductImageSurface({required this.pattern, this.imageUrl, this.artwork, this.child, this.dark = false, super.key});

  final PatternKind pattern;
  final String? imageUrl;
  final ProductArtwork? artwork;
  final Widget? child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl?.trim();
    // 이미지 로딩 전/실패/부재 시 모두 통일된 "준비 이미지"를 보여준다(랜덤 패턴 배경 제거).
    final preparing = PreparingImageSurface(dark: dark, child: child);
    if (trimmedUrl == null || trimmedUrl.isEmpty || !ApiConfig.canLoadImageDirectly(trimmedUrl)) {
      return preparing;
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: dark ? const Color(0xff1f1f1f) : AppColors.line)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            ApiConfig.imageUrl(trimmedUrl),
            fit: BoxFit.cover,
            loadingBuilder: (context, childWidget, loadingProgress) {
              if (loadingProgress == null) return childWidget;
              return preparing;
            },
            errorBuilder: (context, error, stackTrace) => preparing,
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

// 통일된 "준비 이미지" placeholder — 모든 상품 이미지 로딩 전/실패 시 동일하게 표시
class PreparingImageSurface extends StatelessWidget {
  const PreparingImageSurface({this.child, this.dark = false, super.key});

  final Widget? child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xff151515) : AppColors.bgAlt,
        border: Border.all(color: dark ? const Color(0xff2a2a2a) : AppColors.line),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: dark ? 0.4 : 0.5,
                child: Image.asset('assets/logo-square.png', width: 44, height: 44, fit: BoxFit.cover),
              ),
              const SizedBox(height: 10),
              MonoText('이미지 준비 중', size: 9.5, color: dark ? const Color(0xff6a6a6a) : AppColors.ink4),
            ],
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class NeutralImageSurface extends StatelessWidget {
  const NeutralImageSurface({this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.line),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Opacity(
              opacity: 0.14,
              child: Image.asset(
                'assets/logo-square.png',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class RemoteNeutralImageSurface extends StatelessWidget {
  const RemoteNeutralImageSurface({this.imageUrl, this.child, super.key});

  final String? imageUrl;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl?.trim();
    final fallback = NeutralImageSurface(child: child);
    if (trimmedUrl == null || trimmedUrl.isEmpty || !ApiConfig.canLoadImageDirectly(trimmedUrl)) return fallback;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.line),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            ApiConfig.imageUrl(trimmedUrl),
            fit: BoxFit.cover,
            loadingBuilder: (context, childWidget, loadingProgress) {
              if (loadingProgress == null) return childWidget;
              return fallback;
            },
            errorBuilder: (context, error, stackTrace) => fallback,
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  const ProductCard({required this.product, this.dark = false, super.key});
  final ProductItem product;
  final bool dark;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _pressed = false;

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: widget.product,
          onGoToCart: () => AppNavigationScope.select(context, 4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final wished = store.wishlistIds.contains(widget.product.id);
    final product = widget.product;
    final dark = widget.dark;
    final line = dark ? const Color(0xff1f1f1f) : AppColors.line;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openDetail(context),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ProductImageSurface(
              pattern: product.pattern,
              imageUrl: product.imageUrl,
              artwork: product.artwork,
              dark: dark,
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.hasDiscount)
                          BadgePill(text: product.discount, color: dark ? AppColors.accent : AppColors.ink),
                        if (product.badge != null) ...[
                          const SizedBox(height: 3),
                          BadgePill(text: product.badge!, color: dark ? const Color(0xff1a1a1a) : AppColors.bg, ink: dark ? AppColors.invert : AppColors.ink, bordered: true),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: line),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonoText(product.brand, size: 9.5, color: dark ? const Color(0xff7a7a7a) : AppColors.ink4),
                const SizedBox(height: 3),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, height: 1.35, color: dark ? AppColors.invert : AppColors.ink, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 7),
                if (product.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(product.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: dark ? const Color(0xff9a9a9a) : AppColors.ink3)),
                  ),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (product.hasDiscount)
                      MonoText(product.discount, size: 12, color: AppColors.accent, weight: FontWeight.w700),
                    MonoText(product.price, size: 13, color: dark ? AppColors.invert : AppColors.ink, weight: FontWeight.w700),
                    if (product.hasDiscount) StrikeText(product.oldPrice),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: MonoText(product.meta, size: 9.5, color: dark ? const Color(0xff6a6a6a) : AppColors.ink4),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => AppStateScope.read(context).toggleWishlist(product),
                      child: MonoText(wished ? 'WISH ♥' : 'WISH +', size: 9.5, color: wished ? AppColors.accent : (dark ? const Color(0xff6a6a6a) : AppColors.ink4)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),    // Column
    ),    // GestureDetector
  );    // AnimatedScale
  }
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({required this.product, this.onGoToCart, super.key});

  final ProductItem product;
  final VoidCallback? onGoToCart;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late ProductItem _product;
  bool _loading = false;
  bool _addedToCart = false;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() => _loading = true);
    try {
      final product = await AppStateScope.read(context).fetchProductDetail(widget.product.id);
      if (!mounted) return;
      setState(() => _product = product);
    } catch (_) {
      // Keep initial product as fallback.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeQuantity(int delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(1, 99);
    });
  }

  String _tagLabel(String tag) {
    switch (tag) {
      case 'today_deal': return '오늘의 딜';
      case 'new_arrival': return '신상품';
      default: return tag;
    }
  }

  Future<void> _addToCart() async {
    AppStateScope.read(context).cacheProduct(_product);
    await AppStateScope.read(context).changeCartQuantity(_product.id, _quantity);
    if (!mounted) return;
    setState(() => _addedToCart = true);
    AppStateScope.read(context).showCartToast('${_product.name} $_quantity개를 장바구니에 담았습니다.');
  }

  void _goToCart() {
    final onGoToCart = widget.onGoToCart;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (onGoToCart != null) {
      onGoToCart();
    } else {
      AppNavigationScope.select(context, 4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final wished = store.wishlistIds.contains(_product.id);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('상품 정보', style: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              AspectRatio(
                aspectRatio: 1,
            child: ProductImageSurface(
              pattern: _product.pattern,
              imageUrl: _product.imageUrl,
              artwork: _product.artwork,
              child: Stack(
                    children: [
                      if (_loading)
                        const Positioned(
                          top: 16,
                          right: 16,
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.pad, 24, AppSpace.pad, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoText(_product.brand, size: 10.5, color: AppColors.ink4),
                    const SizedBox(height: 10),
                    Text(_product.name, style: const TextStyle(fontSize: 28, height: 1.08, letterSpacing: -0.8, fontWeight: FontWeight.w700)),
                    if (_product.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_product.subtitle, style: const TextStyle(fontSize: 13.5, color: AppColors.ink3, height: 1.5)),
                    ],
                    const SizedBox(height: 10),
                    Text('${_product.rating.toStringAsFixed(1)} · ${_product.reviews} reviews', style: const TextStyle(fontSize: 12.5, color: AppColors.ink3, height: 1.6)),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (_product.hasDiscount)
                          MonoText(_product.discount, size: 16, color: AppColors.accent, weight: FontWeight.w700),
                        MonoText(_product.price, size: 20, weight: FontWeight.w800),
                        if (_product.hasDiscount) StrikeText(_product.oldPrice),
                      ],
                    ),
                    if (_product.blurb.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.bgSoft, border: Border.all(color: AppColors.line)),
                        child: Text(_product.blurb, style: const TextStyle(fontSize: 13.5, color: AppColors.ink2, height: 1.65)),
                      ),
                    ],
                    if (_product.tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in _product.tags)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
                              child: MonoText(_tagLabel(tag), size: 10, color: AppColors.ink3),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    const MonoText('QUANTITY', size: 10, color: AppColors.ink4, weight: FontWeight.w700),
                    const SizedBox(height: 10),
                    QtyBox(value: _quantity.toString(), onMinus: () => _changeQuantity(-1), onPlus: () => _changeQuantity(1), buttonExtent: 56, valueExtent: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(AppSpace.pad, 12, AppSpace.pad, 16),
              decoration: const BoxDecoration(color: AppColors.bg, border: Border(top: BorderSide(color: AppColors.line))),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => AppStateScope.read(context).toggleWishlist(_product),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.bg, border: Border.all(color: AppColors.line)),
                      child: Text(wished ? '♥' : '♡', style: TextStyle(color: wished ? AppColors.accent : AppColors.ink3, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      text: _addedToCart ? '장바구니로 이동' : '장바구니 담기',
                      primary: !_addedToCart,
                      large: true,
                      onTap: _addedToCart ? _goToCart : _addToCart,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditorialSection extends StatefulWidget {
  const EditorialSection({super.key});

  @override
  State<EditorialSection> createState() => _EditorialSectionState();
}

class _EditorialSectionState extends State<EditorialSection> {
  bool _showNote = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      decoration: const BoxDecoration(
        color: AppColors.bgSoft,
        border: Border(top: BorderSide(color: AppColors.line), bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: const NeutralImageSurface(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.pad, 30, AppSpace.pad, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MonoText('FIELD NOTE — 005', size: 10, color: AppColors.ink3),
                const SizedBox(height: 14),
                const Text('"필요한 것"과 "갖고 싶은 것"의 그 사이.', style: TextStyle(fontSize: 30, height: 1.05, letterSpacing: -1, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                const Text('매주 14개의 브랜드와 218개의 상품을 다시 골라냅니다. 오래 두고 싶은 것들을 모읍니다.', style: TextStyle(fontSize: 13.5, height: 1.65, color: AppColors.ink2)),
                if (_showNote) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.bg, border: Border.all(color: AppColors.line)),
                    child: const Text('이번 노트는 외부 페이지로 이동하지 않고, 로컬 큐레이션 메모만 펼쳐 보여줍니다. 상품보다 오래 남는 감각을 기준으로 고른 기록입니다.', style: TextStyle(fontSize: 12.5, height: 1.65, color: AppColors.ink2)),
                  ),
                ],
                const SizedBox(height: 20),
                AppButton(text: _showNote ? '큐레이션 노트 닫기' : '큐레이션 노트 보기', primary: true, onTap: () => setState(() => _showNote = !_showNote)),
                const SizedBox(height: 24),
                const Divider(color: AppColors.line),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Text('EST. 2024 · SEOUL', style: monoStyle)),
                    Expanded(child: Text('ED. Vol.23 — 2026.05', style: monoStyle)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BrandSection extends StatelessWidget {
  const BrandSection({super.key});

  @override
  Widget build(BuildContext context) {
    const row1 = ['soft·studio', 'ATELIER 04', 'good machine', 'objet·han', 'NORM /', 'paperhouse', 'flat·flat'];
    const row2 = ['QUIET CO.', 'han·gul·works', 'monogram', 'slow craft', 'post script', 'edition·k', 'white room'];
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Padding(padding: EdgeInsets.symmetric(horizontal: AppSpace.pad), child: Eyebrow(index: '04', text: "THIS WEEK'S BRANDS")),
          Padding(padding: EdgeInsets.fromLTRB(AppSpace.pad, 8, AppSpace.pad, 20), child: Text('참여 브랜드', style: TextStyle(fontSize: 34, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1.2))),
          BrandRow(items: row1),
          BrandRow(items: row2, noTop: true),
        ],
      ),
    );
  }
}

class BrandRow extends StatelessWidget {
  const BrandRow({required this.items, this.noTop = false, super.key});
  final List<String> items;
  final bool noTop;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: noTop ? BorderSide.none : const BorderSide(color: AppColors.line),
          bottom: const BorderSide(color: AppColors.line),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: AppSpace.pad),
            for (final item in [...items, ...items])
              Padding(
                padding: const EdgeInsets.only(right: 28),
                child: Text(item, style: const TextStyle(fontSize: 20, color: AppColors.ink3, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
              ),
          ],
        ),
      ),
    );
  }
}

class NewsletterSection extends StatefulWidget {
  const NewsletterSection({super.key});

  @override
  State<NewsletterSection> createState() => _NewsletterSectionState();
}

class _NewsletterSectionState extends State<NewsletterSection> {
  final _controller = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final email = _controller.text.trim();
    if (email.isEmpty) return;
    try {
      await DoguRepository().subscribeNewsletter(email);
      setState(() => _message = '구독 요청을 보냈습니다.');
    } catch (_) {
      setState(() => _message = '오프라인 상태라 구독은 나중에 다시 시도해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = AppStateScope.watch(context).newsletter;
    return Container(
      color: AppColors.ink,
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 44, AppSpace.pad, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoText(data['eyebrow'] ?? '— 매주 수요일 발송', size: 10.5, color: AppColors.ink4),
          const SizedBox(height: 14),
          Text(data['title'] ?? '조용한 신상품을\n가장 먼저.', style: const TextStyle(fontSize: 36, height: 1, color: AppColors.invert, fontWeight: FontWeight.w700, letterSpacing: -1.4)),
          const SizedBox(height: 28),
          Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.ink2))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration.collapsed(hintText: 'you@email.com', hintStyle: TextStyle(fontSize: 13, color: Color(0xff555555), fontFamily: 'monospace')),
                    style: const TextStyle(fontSize: 13, color: AppColors.invert, fontFamily: 'monospace'),
                  ),
                ),
                GestureDetector(onTap: _subscribe, child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('구독', style: TextStyle(color: AppColors.invert, fontWeight: FontWeight.w600)))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MonoText(_message ?? data['note'] ?? '// 언제든 한 번의 클릭으로 구독 취소', size: 10.5, color: AppColors.ink4),
        ],
      ),
    );
  }
}

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    const groups = {
      'SHOP': ['신상품', '베스트', '오늘의 딜', 'SALE'],
      'CATEGORY': ['의류', '홈·리빙', '전자제품', '뷰티'],
      'HELP': ['고객센터', '배송 안내', '반품 / 교환', 'FAQ'],
      'ABOUT': ['브랜드 스토리', '큐레이션 노트', '입점 문의'],
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 32, AppSpace.pad, 28),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(child: Image.asset('assets/logo-square.png', width: 30, height: 30)),
              const SizedBox(width: 9),
              const Text('욕망의장바구니', style: TextStyle(color: AppColors.accent, fontSize: 21, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('매주 한 번, 조용한 큐레이션.\nSeoul, KR — since 2024.', style: TextStyle(fontSize: 12.5, color: AppColors.ink3, height: 1.6)),
          const SizedBox(height: 24),
          for (final entry in groups.entries) FooterGroup(title: entry.key, items: entry.value),
          const SizedBox(height: 22),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: const ['VISA', 'MC', 'AMEX', 'KAKAO', 'NAVER', 'TOSS'].map((pay) => Tag(text: pay, compact: true)).toList(),
          ),
          const SizedBox(height: 16),
          const MonoText('© 2026 욕망의장바구니\nBIZ 000-00-00000 · 서울 ○○구', size: 10.5, color: AppColors.ink4),
        ],
      ),
    );
  }
}

class FooterGroup extends StatefulWidget {
  const FooterGroup({required this.title, required this.items, super.key});
  final String title;
  final List<String> items;

  @override
  State<FooterGroup> createState() => _FooterGroupState();
}

class _FooterGroupState extends State<FooterGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MonoText(widget.title, size: 11, weight: FontWeight.w700),
                Text(_expanded ? '−' : '+', style: const TextStyle(color: AppColors.ink3)),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              for (final item in widget.items)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(item, style: const TextStyle(fontSize: 13, color: AppColors.ink2)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class BottomTabs extends StatelessWidget {
  const BottomTabs({
    required this.currentIndex,
    required this.onTap,
    required this.bottomInset,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final cartCount = store.cartCount;
    final wishCount = store.wishlistIds.length;
    const tabs = [
      (Icons.home_outlined, '홈'),
      (Icons.grid_view_outlined, '카테고리'),
      (Icons.search, '검색'),
      (Icons.favorite_border, '찜'),
      (Icons.shopping_cart_outlined, '장바구니'),
    ];
    return Container(
      height: AppSpace.tabHeight + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (i == currentIndex) Container(width: 38, height: 2, color: AppColors.ink),
                    Padding(
                      padding: const EdgeInsets.only(top: 11),
                      child: Column(
                        children: [
                          Icon(tabs[i].$1, size: 21, color: i == currentIndex ? AppColors.ink : AppColors.ink4),
                          const SizedBox(height: 4),
                          Text(tabs[i].$2, style: TextStyle(fontSize: 10.5, color: i == currentIndex ? AppColors.ink : AppColors.ink4, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (i == 3 && wishCount > 0) Positioned(top: 7, right: 20, child: BadgePill(text: wishCount.toString(), color: AppColors.accent, compact: true)),
                    if (i == 4 && cartCount > 0) Positioned(top: 7, right: 20, child: BadgePill(text: cartCount.toString(), color: AppColors.alert, compact: true)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryTabPage extends StatelessWidget {
  const CategoryTabPage({required this.bottomPadding, super.key});
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final categoryTotal = store.categories.fold<int>(0, (sum, item) => sum + (int.tryParse(item.count.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0));
    return ListView(
      key: const PageStorageKey('category-tab'),
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        const Header(),
        if (store.selectedCategoryKey != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AppStateScope.read(context).selectCategoryBrowse(null);
              AppStateScope.read(context).setCategoryQuickFilter('all');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(AppSpace.pad, 16, AppSpace.pad, 8),
              child: const MonoText('← 전체 카테고리', size: 11, color: AppColors.ink3, weight: FontWeight.w700),
            ),
          ),
        QuickFilterRow(
          items: ['전체  $categoryTotal', '신상', '베스트', '세일', '딜'],
          activeIndex: _categoryFilterIndexFor(store.categoryQuickFilter),
          onSelectedIndex: (index) {
            const filterKeys = ['all', 'new', 'best', 'sale', 'deal'];
            AppStateScope.read(context).setCategoryQuickFilter(filterKeys[index]);
          },
        ),
        const CategoryListBlock(),
        if (store.selectedCategoryKey != null || store.categoryQuickFilter != 'all') CategoryProductsBlock(products: store.categoryBrowseProducts),
        const SoftDividerBlock(child: BrandTagBlock(title: '[ + ] SHOP BY BRAND', action: '전체 보기 →')),
      ],
    );
  }
}

int _categoryFilterIndexFor(String filter) {
  const filters = ['all', 'new', 'best', 'sale', 'deal'];
  return filters.indexOf(filter).clamp(0, filters.length - 1);
}

class SearchTabPage extends StatelessWidget {
  const SearchTabPage({required this.bottomPadding, super.key});
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return ListView(
      key: const PageStorageKey('search-tab'),
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        const Header(),
        const BigSearchBox(),
        if (store.lastSearchTerm.isNotEmpty)
          SearchResultsBlock(
            query: store.lastSearchTerm,
            results: store.searchResults,
          ),
        SearchBlock(
          title: '[ 01 ] 최근 검색',
          action: '전체 삭제',
          tags: store.recentSearches.map((term) => '$term  ×').toList(),
          onAction: () => AppStateScope.read(context).clearRecentSearches(),
          onTagTap: (term) => AppStateScope.read(context).performSearch(term.replaceAll('  ×', '')),
        ),
        SoftDividerBlock(
          child: SearchBlock(
            title: '[ 02 ] 추천 브랜드',
            tags: store.suggestions,
            onTagTap: (term) => AppStateScope.read(context).performSearch(term),
          ),
        ),
      ],
    );
  }
}

class SearchResultsBlock extends StatelessWidget {
  const SearchResultsBlock({required this.query, required this.results, super.key});

  final String query;
  final List<ProductItem> results;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 8, AppSpace.pad, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '검색 결과',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '“$query”',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            results.isEmpty ? '검색 결과가 없습니다.' : '${results.length}개의 상품을 찾았어요.',
            style: const TextStyle(fontSize: 12.5, color: AppColors.ink3),
          ),
          if (results.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final product in results)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProductCard(product: product),
              ),
          ],
        ],
      ),
    );
  }
}

class WishTabPage extends StatefulWidget {
  const WishTabPage({required this.bottomPadding, super.key});
  final double bottomPadding;

  @override
  State<WishTabPage> createState() => _WishTabPageState();
}

class _WishTabPageState extends State<WishTabPage> {
  String _activeFilter = 'all';

  bool _isSaleProduct(ProductItem product) {
    return product.numericOldPrice > product.numericPrice || (product.discount.isNotEmpty && product.discount != '-0%');
  }

  List<ProductItem> _filterWishlist(List<ProductItem> items) {
    if (_activeFilter != 'sale') return items;
    return items.where(_isSaleProduct).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filterWishlist(AppStateScope.watch(context).wishlistProducts);
    return ListView(
      key: const PageStorageKey('wish-tab'),
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      children: [
        const Header(),
        WishSummary(
          activeFilter: _activeFilter,
          onFilterSelected: (filter) => setState(() => _activeFilter = filter),
        ),
        WishGridBlock(items: filteredItems, activeFilter: _activeFilter),
      ],
    );
  }
}

class CartTabPage extends StatelessWidget {
  const CartTabPage({required this.bottomPadding, super.key});
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('cart-tab'),
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: const [
        Header(),
        CartStatusBlock(),
        CartBannerBlock(),
        CartItemsBlock(),
        CartSummaryBlock(),
        SoftDividerBlock(child: RecommendedCartBlock()),
      ],
    );
  }
}

class QuickFilterRow extends StatefulWidget {
  const QuickFilterRow({required this.items, this.activeIndex, this.onSelectedIndex, super.key});
  final List<String> items;
  final int? activeIndex;
  final ValueChanged<int>? onSelectedIndex;

  @override
  State<QuickFilterRow> createState() => _QuickFilterRowState();
}

class _QuickFilterRowState extends State<QuickFilterRow> {
  int _activeIndex = 0;

  @override
  void didUpdateWidget(covariant QuickFilterRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != null && widget.activeIndex != _activeIndex) {
      _activeIndex = widget.activeIndex!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = widget.activeIndex ?? _activeIndex;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad, vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < widget.items.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (widget.onSelectedIndex != null) {
                    widget.onSelectedIndex!(i);
                  } else {
                    setState(() => _activeIndex = i);
                  }
                },
                child: Container(
                  height: 32,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == activeIndex ? AppColors.accent : AppColors.bg,
                    border: Border.all(color: i == activeIndex ? AppColors.accent : AppColors.line),
                  ),
                  child: Text(widget.items[i], style: TextStyle(fontSize: 12.5, color: i == activeIndex ? AppColors.invert : AppColors.ink2)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CategoryListBlock extends StatelessWidget {
  const CategoryListBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = AppStateScope.watch(context).categories;
    final selectedCategoryKey = AppStateScope.watch(context).selectedCategoryKey;
    final visibleRows = selectedCategoryKey == null
        ? rows
        : rows.where((row) => (row.id.isEmpty ? _categoryKeyFromName(row.name) : _normalizeCategoryKey(row.id)) == selectedCategoryKey).toList();
    return Column(
      children: [
        for (var i = 0; i < visibleRows.length; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AppStateScope.read(context).setCategoryQuickFilter('all');
              AppStateScope.read(context).selectCategoryBrowse(visibleRows[i].id.isEmpty ? _categoryKeyFromName(visibleRows[i].name) : _normalizeCategoryKey(visibleRows[i].id));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad, vertical: 14),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: MonoText((i + 1).toString().padLeft(2, '0'), size: 11, color: AppColors.ink4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(visibleRows[i].name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                        const SizedBox(height: 4),
                        Text(visibleRows[i].description.isEmpty ? '큐레이션 · 베스트 · 신상품 · 한정판' : visibleRows[i].description, style: const TextStyle(fontSize: 11.5, color: AppColors.ink3, height: 1.5)),
                      ],
                    ),
                  ),
                  Row(children: [MonoText(visibleRows[i].count, size: 11, color: AppColors.ink3), const SizedBox(width: 6), const Text('→')]),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String? _categoryKeyFromName(String name) {
  switch (name) {
    case '의류':
      return 'clothing';
    case '홈·리빙':
      return 'home';
    case '전자제품':
      return 'tech';
    case '뷰티':
      return 'beauty';
    default:
      return null;
  }
}

class CategoryProductsBlock extends StatelessWidget {
  const CategoryProductsBlock({required this.products, super.key});

  final List<ProductItem> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const EmptyStateBlock(
        title: '조건에 맞는 상품이 없습니다.',
        body: '다른 카테고리나 필터를 선택해 다시 확인해보세요.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpace.pad),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58,
          mainAxisSpacing: 24,
          crossAxisSpacing: 12,
        ),
        itemBuilder: (context, index) => ProductCard(product: products[index]),
      ),
    );
  }
}

class SoftDividerBlock extends StatelessWidget {
  const SoftDividerBlock({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.bgSoft, width: 8))),
      child: child,
    );
  }
}

class EmptyStateBlock extends StatelessWidget {
  const EmptyStateBlock({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSpace.pad),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(color: AppColors.bgSoft, border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 12.5, height: 1.6, color: AppColors.ink3)),
        ],
      ),
    );
  }
}

class BrandTagBlock extends StatelessWidget {
  const BrandTagBlock({required this.title, this.action, super.key});
  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    const brands = ['soft·studio  42', 'good machine  18', 'objet·han  36', 'NORM /  24', 'QUIET CO.  19', 'paperhouse  12', 'flat·flat  28', 'ATELIER 04  31'];
    return SearchBlock(title: title, action: action, tags: brands);
  }
}

class BigSearchBox extends StatefulWidget {
  const BigSearchBox({super.key});

  @override
  State<BigSearchBox> createState() => _BigSearchBoxState();
}

class _BigSearchBoxState extends State<BigSearchBox> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      AppStateScope.read(context).resetSearch();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _performSearch(value);
    });
  }

  void _performSearch(String value) {
    _debounce?.cancel();
    AppStateScope.read(context).performSearch(value);
  }

  void _cancelSearch() {
    _debounce?.cancel();
    _controller.clear();
    FocusScope.of(context).unfocus();
    AppStateScope.read(context).resetSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.all(AppSpace.pad - 4),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.ink), color: AppColors.bg),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _performSearch(_controller.text),
            child: const Icon(Icons.search, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              autofocus: false,
              decoration: const InputDecoration.collapsed(hintText: '찾고 싶은 욕망을 입력하세요', hintStyle: TextStyle(fontSize: 15, color: AppColors.ink4)),
              style: const TextStyle(fontSize: 15, color: AppColors.ink),
              onChanged: _onChanged,
              onSubmitted: _performSearch,
            ),
          ),
          GestureDetector(
            onTap: _cancelSearch,
            child: const Text('취소', style: TextStyle(fontSize: 13, color: AppColors.ink3)),
          ),
        ],
      ),
    );
  }
}

class SearchBlock extends StatelessWidget {
  const SearchBlock({required this.title, required this.tags, this.action, this.onAction, this.onTagTap, super.key});
  final String title;
  final String? action;
  final List<String> tags;
  final VoidCallback? onAction;
  final ValueChanged<String>? onTagTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 22, AppSpace.pad, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MonoText(title, size: 10, weight: FontWeight.w700),
              if (action != null) GestureDetector(onTap: onAction, child: Text(action!, style: const TextStyle(fontSize: 11, color: AppColors.ink4))),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in tags)
                title == '[ 01 ] 최근 검색' && tag.endsWith('  ×')
                    ? RecentSearchTag(
                        label: tag.replaceAll('  ×', ''),
                        onTap: onTagTap == null ? null : () => onTagTap!(tag.replaceAll('  ×', '')),
                        onRemove: () => AppStateScope.read(context).removeRecentSearch(tag.replaceAll('  ×', '')),
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onTagTap == null ? null : () => onTagTap!(tag),
                        child: Tag(text: tag, compact: true),
                      ),
            ],
          ),
        ],
      ),
    );
  }
}

class RecentSearchTag extends StatelessWidget {
  const RecentSearchTag({required this.label, this.onTap, this.onRemove, super.key});

  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), color: AppColors.bg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            key: Key('recent-remove-$label'),
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: const Text('×', style: TextStyle(fontSize: 12, color: AppColors.ink4)),
          ),
        ],
      ),
    );
  }
}

class TrendingBlock extends StatelessWidget {
  const TrendingBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = AppStateScope.watch(context).trendingItems;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 24, AppSpace.pad, 12),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [MonoText('[ 02 ] 실시간 인기 검색', size: 10, weight: FontWeight.w700), MonoText('14:02 기준', size: 11, color: AppColors.ink4)],
          ),
          const SizedBox(height: 12),
            for (var i = 0; i < rows.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => AppStateScope.read(context).performSearch(rows[i].term),
                child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.lineSoft))),
                child: Row(
                  children: [
                    SizedBox(width: 28, child: MonoText((i + 1).toString().padLeft(2, '0'), size: 14, color: i < 3 ? AppColors.accent : AppColors.ink, weight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(rows[i].term, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                    MonoText(rows[i].movement, size: 10.5, color: rows[i].movement.startsWith('▲') ? AppColors.accent : AppColors.ink3),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WishSummary extends StatelessWidget {
  const WishSummary({required this.activeFilter, required this.onFilterSelected, super.key});

  final String activeFilter;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final total = store.wishlistProducts.fold<int>(0, (sum, product) => sum + product.numericPrice);
    return Container(
      padding: const EdgeInsets.all(AppSpace.pad - 4),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Expanded(child: Text('${store.wishlistProducts.length} items · 총 ${formatWon(total)} 상당', style: const TextStyle(fontSize: 12.5, color: AppColors.ink3))),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onFilterSelected('all'),
            child: SmallChip(text: '전체', active: activeFilter == 'all'),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onFilterSelected('sale'),
            child: SmallChip(text: '세일 중', active: activeFilter == 'sale'),
          ),
        ],
      ),
    );
  }
}

class SmallChip extends StatelessWidget {
  const SmallChip({required this.text, this.active = false, super.key});
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: active ? AppColors.accent : AppColors.bg, border: Border.all(color: active ? AppColors.accent : AppColors.line)),
      child: Text(text, style: TextStyle(fontSize: 12, color: active ? AppColors.invert : AppColors.ink2)),
    );
  }
}

class WishGridBlock extends StatelessWidget {
  const WishGridBlock({required this.items, required this.activeFilter, super.key});

  final List<ProductItem> items;
  final String activeFilter;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyStateBlock(
        title: activeFilter == 'sale' ? '세일 중인 찜 상품이 없습니다.' : '찜한 상품이 없습니다.',
        body: activeFilter == 'sale' ? '전체 탭에서 관심 상품을 다시 확인해보세요.' : '상품 카드의 WISH 버튼으로 로컬 찜 목록을 채워보세요.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpace.pad),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.58, mainAxisSpacing: 24, crossAxisSpacing: 12),
        itemBuilder: (context, index) => Stack(
          children: [
            ProductCard(product: items[index]),
            Positioned(top: 8, right: 8, child: GestureDetector(onTap: () => AppStateScope.read(context).toggleWishlist(items[index]), child: Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.bg, border: Border.all(color: AppColors.line)), child: const Text('♥', style: TextStyle(color: AppColors.accent))))),
          ],
        ),
      ),
    );
  }
}

class PriceDropBlock extends StatelessWidget {
  const PriceDropBlock({super.key});

  @override
  Widget build(BuildContext context) {
    const drops = [
      ('Graphite Linen Overshirt', 'soft·studio', '₩189,000', '₩118,000'),
      ('Aluminum Desk Lamp', 'good machine', '₩198,000', '₩148,000'),
      ('Cedar Wood Diffuser', 'slow craft', '₩62,000', '₩46,000'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 24, AppSpace.pad, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MonoText('[ ↓ ] 가격 인하 알림', size: 10, weight: FontWeight.w700),
          const SizedBox(height: 12),
          const Text('관심상품 중 가격이 내려간 3개 항목이 있어요.', style: TextStyle(fontSize: 12.5, color: AppColors.ink3, height: 1.6)),
          const SizedBox(height: 14),
          for (final item in drops)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
              child: Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.$1, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)), MonoText(item.$2, size: 10.5, color: AppColors.ink4)])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [StrikeText(item.$3), MonoText(item.$4, size: 14, color: AppColors.accent, weight: FontWeight.w700)]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class CartStatusBlock extends StatelessWidget {
  const CartStatusBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MonoText('${store.selectedCartCount}개 상품 선택됨', size: 11, color: AppColors.ink3),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => AppStateScope.read(context).toggleAllCartSelection(),
            child: const Text('모두 선택', style: TextStyle(fontSize: 11, color: AppColors.ink3)),
          ),
        ],
      ),
    );
  }
}

class CartBannerBlock extends StatelessWidget {
  const CartBannerBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final remaining = (28000 - store.selectedCartTotal).clamp(0, 28000);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad, vertical: 12),
      decoration: const BoxDecoration(color: AppColors.bgSoft, border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)), const SizedBox(width: 10), Expanded(child: Text(remaining == 0 ? '무료 배송 조건이 충족됐어요' : '${formatWon(remaining)} 더 담으면 무료 배송 조건이 충족돼요', style: const TextStyle(fontSize: 12, color: AppColors.ink2)))]),
    );
  }
}

class CartItemsBlock extends StatelessWidget {
  const CartItemsBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final items = store.cartLines;
    if (items.isEmpty) {
      return const EmptyStateBlock(
        title: '장바구니가 비어 있습니다.',
        body: '홈과 카테고리에서 담은 상품이 이 기기에 로컬로 저장됩니다.',
      );
    }
    return Column(children: [for (var i = 0; i < items.length; i++) CartItemRow(index: i + 1, item: items[i])]);
  }
}

class CartItemRow extends StatelessWidget {
  const CartItemRow({required this.index, required this.item, super.key});
  final int index;
  final ({ProductItem product, int quantity}) item;

  @override
  Widget build(BuildContext context) {
    final selected = AppStateScope.watch(context).selectedCartIds.contains(item.product.id);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => AppStateScope.read(context).toggleCartSelection(item.product.id),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.pad - 2),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [SizedBox(width: 96, height: 96, child: ProductImageSurface(pattern: item.product.pattern, imageUrl: item.product.imageUrl, artwork: item.product.artwork, child: Padding(padding: const EdgeInsets.all(6), child: MonoText(index.toString().padLeft(3, '0'), size: 9, color: AppColors.ink4)))), Positioned(top: -2, left: -2, child: Container(width: 18, height: 18, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? AppColors.accent : AppColors.bg, border: Border.all(color: selected ? AppColors.accent : AppColors.line)), child: Text(selected ? '✓' : '', style: const TextStyle(color: AppColors.invert, fontSize: 11))))]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonoText(item.product.brand, size: 10, color: AppColors.ink4),
                  const SizedBox(height: 4),
                  Text(item.product.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  const MonoText('local cart · persisted on this device', size: 10.5, color: AppColors.ink3),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, children: [if (item.product.hasDiscount) MonoText(item.product.discount, size: 11, color: AppColors.accent, weight: FontWeight.w700), MonoText(item.product.price, size: 14, weight: FontWeight.w700), if (item.product.hasDiscount) StrikeText(item.product.oldPrice)]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [QtyBox(value: item.quantity.toString(), onMinus: () => AppStateScope.read(context).changeCartQuantity(item.product.id, -1), onPlus: () => AppStateScope.read(context).changeCartQuantity(item.product.id, 1)), GestureDetector(onTap: () => AppStateScope.read(context).changeCartQuantity(item.product.id, -item.quantity), child: const MonoText('삭제 ×', size: 11, color: AppColors.ink4))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QtyBox extends StatelessWidget {
  const QtyBox({required this.value, this.onMinus, this.onPlus, this.buttonExtent = 48, this.valueExtent = 40, super.key});
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final double buttonExtent;
  final double valueExtent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
      child: Row(children: [GestureDetector(behavior: HitTestBehavior.opaque, onTap: onMinus, child: SizedBox(width: buttonExtent, height: buttonExtent, child: const Center(child: MonoText('−', size: 16)))), Container(width: valueExtent, height: buttonExtent, alignment: Alignment.center, decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.line), right: BorderSide(color: AppColors.line))), child: MonoText(value, size: 13, weight: FontWeight.w700)), GestureDetector(behavior: HitTestBehavior.opaque, onTap: onPlus, child: SizedBox(width: buttonExtent, height: buttonExtent, child: const Center(child: MonoText('+', size: 16))))]),
    );
  }
}

class CartSummaryBlock extends StatelessWidget {
  const CartSummaryBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(AppSpace.pad + 2),
      color: AppColors.bgSoft,
      child: Column(
        children: [
          SummaryLine(label: '상품 금액', value: formatWon(store.selectedCartOldTotal)),
          SummaryLine(label: '할인', value: '−${formatWon(store.selectedCartDiscount)}', accent: true),
          const SummaryLine(label: '배송비', value: '무료'),
          const Divider(color: AppColors.line),
          SummaryLine(label: '결제 예정 금액', value: formatWon(store.selectedCartTotal), total: true),
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerLeft, child: MonoText('// 장바구니는 이 기기에 로컬 저장됩니다\n// API에는 결제·쿠폰 데이터를 전송하지 않음', size: 10.5, color: AppColors.ink4)),
        ],
      ),
    );
  }
}

class SummaryLine extends StatelessWidget {
  const SummaryLine({required this.label, required this.value, this.accent = false, this.total = false, super.key});
  final String label;
  final String value;
  final bool accent;
  final bool total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: total ? 14 : 13, fontWeight: total ? FontWeight.w700 : FontWeight.w400, color: AppColors.ink2)), MonoText(value, size: total ? 22 : 13, color: accent ? AppColors.accent : AppColors.ink, weight: total ? FontWeight.w800 : FontWeight.w500)]),
    );
  }
}

class RecommendedCartBlock extends StatelessWidget {
  const RecommendedCartBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final recos = AppStateScope.watch(context).recommendedProducts.take(4).toList();
    if (recos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 24, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MonoText('[ → ] 함께 담으면 좋은', size: 10, weight: FontWeight.w700),
          const SizedBox(height: 12),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final item in recos) Padding(padding: const EdgeInsets.only(right: 12), child: SizedBox(width: 160, child: ProductCard(product: item)))])),
        ],
      ),
    );
  }
}

class CheckoutBar extends StatelessWidget {
  const CheckoutBar({super.key});

  Future<void> _submitOrder(BuildContext context) async {
    final store = AppStateScope.read(context);
    final summary = store.buildOrderSummary();
    if (summary == null) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '결제 진행',
      // 기본 배리어는 투명 — 어둡게 처리는 하단 네비게이션 바를 제외하고 커스텀 dim으로 직접
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, __) {
        final navBarHeight = AppSpace.tabHeight + MediaQuery.viewPaddingOf(dialogContext).bottom;
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return Stack(
          children: [
            // 하단 네비게이션 바는 어둡게 하지 않고, 그 위 영역만 어둡게 (탭은 배리어로 통과시켜 닫기 유지)
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: curved,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: navBarHeight),
                    child: const ColoredBox(color: Colors.black26),
                  ),
                ),
              ),
            ),
            // 토스트: 네비게이션 바 바로 위에서 이어져 올라오는 느낌
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
              child: FadeTransition(
                opacity: curved,
                child: PaymentToastOverlay(
                  orderSummary: summary,
                  onConfirm: () => AppNavigationScope.select(context, 0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    return Container(
      height: AppSpace.checkoutHeight,
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 16, AppSpace.pad, 18),
      decoration: const BoxDecoration(color: AppColors.ink, border: Border(top: BorderSide(color: Color(0xff1a1a1a)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [const MonoText('결제 금액', size: 10, color: AppColors.ink4), MonoText(formatWon(store.selectedCartTotal), size: 18, color: AppColors.invert, weight: FontWeight.w800)]),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: store.selectedCartCount == 0 ? null : () => _submitOrder(context),
            child: Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 22), alignment: Alignment.center, color: store.selectedCartCount == 0 ? AppColors.ink2 : AppColors.alert, child: Text('결제하기 (${store.selectedCartCount})  →', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
          ),
        ],
      ),
    );
  }
}

class PaymentToastOverlay extends StatefulWidget {
  const PaymentToastOverlay({required this.orderSummary, this.onConfirm, super.key});

  final Map<String, dynamic> orderSummary;
  final VoidCallback? onConfirm;

  @override
  State<PaymentToastOverlay> createState() => _PaymentToastOverlayState();
}

class _PaymentToastOverlayState extends State<PaymentToastOverlay> {
  bool _submitting = false;
  Map<String, dynamic>? _response;

  Future<void> _completePayment() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
    });
    final store = AppStateScope.read(context);
    try {
      final results = await Future.wait<dynamic>([
        store.submitSelectedOrder(),
        Future<void>.delayed(const Duration(milliseconds: 650)),
      ]);
      if (!mounted) return;
      setState(() {
        _response = results.first as Map<String, dynamic>;
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.orderSummary['items'] as List<dynamic>? ?? const []).cast<String>();
    final count = widget.orderSummary['count'] as int? ?? 0;
    final total = widget.orderSummary['total'] as int? ?? 0;

    // 하단 네비게이션 바 높이만큼 띄워 바로 위에 밀착(이어져 올라오는 느낌)
    final navBarHeight = AppSpace.tabHeight + MediaQuery.viewPaddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: navBarHeight),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 24, offset: Offset(0, -2))],
          ),
            padding: const EdgeInsets.fromLTRB(AppSpace.pad, 14, AppSpace.pad, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_response == null) ...[
                  const Text('결제 진행', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('선택 상품 $count개 · ${formatWon(total)}', style: const TextStyle(fontSize: 13, color: AppColors.ink3)),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 10),
                  ],
                  for (final item in items.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(item, style: const TextStyle(fontSize: 13.5, color: AppColors.ink2)),
                    ),
                  if (items.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('외 ${items.length - 2}개 상품', style: const TextStyle(fontSize: 12, color: AppColors.ink4)),
                    ),
                  const SizedBox(height: 12),
                  if (_submitting)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else
                    AppButton(text: '결제하기', primary: true, large: true, onTap: _completePayment),
                ] else ...[
                  const Text('결제가 완료되었습니다.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('주문번호: ${_response!['order_id']}', style: const TextStyle(fontSize: 13, color: AppColors.ink3)),
                  const SizedBox(height: 10),
                  for (final item in (_response!['items'] as List<dynamic>).take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${item['name']} × ${item['quantity']}', style: const TextStyle(fontSize: 13.5, color: AppColors.ink2)),
                    ),
                  if ((_response!['items'] as List<dynamic>).length > 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('외 ${(_response!['items'] as List<dynamic>).length - 2}개 상품', style: const TextStyle(fontSize: 12, color: AppColors.ink4)),
                    ),
                  const SizedBox(height: 12),
                  AppButton(text: '확인', primary: true, large: true, onTap: () {
                    Navigator.of(context).pop();
                    widget.onConfirm?.call();
                  }),
                ],
              ],
            ),
          ),
        ),
      );
  }
}

// 전역 장바구니 토스트 — 결제바(CheckoutBar)가 보이면 그 위로 미끄러져 올라가고, 없으면 다시 내려온다
class CartToast extends StatefulWidget {
  const CartToast({super.key});

  @override
  State<CartToast> createState() => _CartToastState();
}

class _CartToastState extends State<CartToast> {
  String _lastMessage = '';

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final message = store.cartToastMessage;
    final visible = message != null;
    if (visible) _lastMessage = message;

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final navBarHeight = AppSpace.tabHeight + bottomInset;
    // 결제바가 떠 있으면 그 행의 위쪽으로, 아니면 네비게이션 바 바로 위로
    final restingBottom = navBarHeight + (store.checkoutBarVisible ? AppSpace.checkoutHeight : 0) + 12;

    return AnimatedPositioned(
      // 결제바 유무 변화 시 부드럽게 위/아래로 미끄러짐
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      left: 12,
      right: 12,
      bottom: restingBottom,
      child: AnimatedSlide(
        // 표시/숨김은 아래에서 미끄러져 올라오고 내려가는 모션
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, 1.6),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: visible ? 1 : 0,
          child: IgnorePointer(
            ignoring: !visible,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4))],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.accentBright, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _lastMessage,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionHead extends StatelessWidget {
  const SectionHead({required this.index, required this.eyebrow, required this.title, this.link, this.onLinkTap, super.key});
  final String index;
  final String eyebrow;
  final String title;
  final String? link;
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 0, AppSpace.pad, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(index: index, text: eyebrow),
              Text(title, style: const TextStyle(fontSize: 34, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1.3)),
            ],
          ),
          if (link != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onLinkTap,
              child: Text(link!, style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
            ),
        ],
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow({required this.index, required this.text, this.inverted = false, super.key});
  final String index;
  final String text;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: monoStyle.copyWith(fontSize: 10, color: inverted ? AppColors.ink4 : AppColors.ink3, letterSpacing: 0.4),
          children: [
            TextSpan(text: '[ $index ] ', style: const TextStyle(color: AppColors.accent)),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

class SkeletonProductCard extends StatelessWidget {
  const SkeletonProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AspectRatio(aspectRatio: 1, child: ColoredBox(color: AppColors.bgAlt)),
        Container(height: 1, color: AppColors.line),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 9, width: 56, color: AppColors.bgAlt, margin: const EdgeInsets.only(bottom: 6)),
              Container(height: 11, color: AppColors.bgAlt, margin: const EdgeInsets.only(bottom: 4)),
              Container(height: 11, width: 90, color: AppColors.bgAlt, margin: const EdgeInsets.only(bottom: 12)),
              Container(height: 13, width: 72, color: AppColors.bgAlt),
            ],
          ),
        ),
      ],
    );
  }
}

class AppButton extends StatelessWidget {
  const AppButton({required this.text, this.primary = false, this.large = false, this.onDark = false, this.onTap, super.key});
  final String text;
  final bool primary;
  final bool large;
  final bool onDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    if (onDark) {
      // 검은 광고 배경 위에서 테마색(accent)을 또렷하게 보여주는 버튼
      if (primary) {
        bgColor = AppColors.accentDeep;
        borderColor = AppColors.accentDeep;
        textColor = Colors.white;
      } else {
        // 노트 버튼: 밝은 회색 배경 + 검은 글씨 + 검은 테두리
        bgColor = AppColors.heroChip;
        borderColor = AppColors.ink;
        textColor = AppColors.ink;
      }
    } else {
      bgColor = primary ? AppColors.accent : AppColors.bg;
      borderColor = primary ? AppColors.accent : AppColors.line;
      textColor = primary ? AppColors.invert : AppColors.ink;
    }
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: large ? 48 : 42,
          padding: EdgeInsets.symmetric(horizontal: large ? 22 : 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
          ),
          child: Text(text, style: TextStyle(fontSize: (large ? 13.5 : 13) + (onDark && primary ? 2 : 0), fontWeight: FontWeight.w600, color: textColor)),
        ),
      ),
    );
  }
}

class PatternBox extends StatelessWidget {
  const PatternBox({required this.pattern, this.child, this.dark = false, super.key});
  final PatternKind pattern;
  final Widget? child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PatternPainter(pattern: pattern, dark: dark),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: dark ? const Color(0xff1f1f1f) : AppColors.line)),
        child: child,
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  const PatternPainter({required this.pattern, this.dark = false});
  final PatternKind pattern;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = dark ? const Color(0xff0f0f0f) : AppColors.bgAlt;
    canvas.drawRect(Offset.zero & size, bgPaint);
    final paint = Paint()
      ..color = dark ? const Color(0xff2a2a2a) : AppColors.ink4
      ..strokeWidth = 1;
    final soft = Paint()
      ..color = dark ? const Color(0xff1c1c1c) : AppColors.line
      ..strokeWidth = 1;

    switch (pattern) {
      case PatternKind.dots:
      case PatternKind.halftone:
        final radius = pattern == PatternKind.halftone ? 1.7 : 1.1;
        for (double x = 4; x < size.width; x += 8) {
          for (double y = 4; y < size.height; y += 8) {
            canvas.drawCircle(Offset(x, y), radius, pattern == PatternKind.halftone ? soft : paint);
          }
        }
        break;
      case PatternKind.grid:
      case PatternKind.cross:
        final step = pattern == PatternKind.cross ? 18.0 : 14.0;
        for (double x = 0; x < size.width; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), soft);
        }
        for (double y = 0; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), soft);
        }
        break;
      case PatternKind.lines:
        for (double x = 0; x < size.width; x += 7) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        break;
      case PatternKind.checker:
        final checkerPaint = Paint()..color = dark ? const Color(0xff161616) : AppColors.lineSoft;
        const step = 14.0;
        for (double y = 0; y < size.height; y += step) {
          for (double x = 0; x < size.width; x += step) {
            if (((x / step).floor() + (y / step).floor()).isEven) {
              canvas.drawRect(Rect.fromLTWH(x, y, step / 2, step / 2), checkerPaint);
              canvas.drawRect(Rect.fromLTWH(x + step / 2, y + step / 2, step / 2, step / 2), checkerPaint);
            }
          }
        }
        break;
      case PatternKind.wave:
      case PatternKind.diag:
        final anglePaint = soft;
        for (double i = -size.height; i < size.width + size.height; i += pattern == PatternKind.diag ? 12 : 9) {
          canvas.drawLine(Offset(i, size.height), Offset(i + size.height, 0), anglePaint);
        }
        break;
    }

    final vignette = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.transparent, (dark ? AppColors.ink : AppColors.accent).withValues(alpha: 0.05)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant PatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern || oldDelegate.dark != dark;
  }
}

class CornerMark extends StatelessWidget {
  const CornerMark({required this.alignment, super.key});
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    return Align(
      alignment: alignment,
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppColors.ink) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppColors.ink) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppColors.ink) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppColors.ink) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class SectionBorder extends StatelessWidget {
  const SectionBorder({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: child,
    );
  }
}

class Tag extends StatelessWidget {
  const Tag({required this.text, this.compact = false, this.dark = false, super.key});
  final String text;
  final bool compact;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 7, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: dark ? AppColors.heroChip : null,
        border: Border.all(color: dark ? AppColors.heroChip : AppColors.line),
      ),
      child: MonoText(text, size: compact ? 9.5 : 10, weight: FontWeight.w600, color: dark ? AppColors.ink : (compact ? AppColors.ink3 : AppColors.ink)),
    );
  }
}

class BadgePill extends StatelessWidget {
  const BadgePill({required this.text, required this.color, this.ink = Colors.white, this.bordered = false, this.compact = false, super.key});
  final String text;
  final Color color;
  final Color ink;
  final bool bordered;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(color: color, border: bordered ? Border.all(color: AppColors.line) : null),
      child: MonoText(text, size: compact ? 9 : 9.5, color: ink, weight: FontWeight.w700),
    );
  }
}

class MonoText extends StatelessWidget {
  const MonoText(this.text, {this.size = 12, this.color = AppColors.ink, this.weight = FontWeight.w400, this.align, super.key});
  final String text;
  final double size;
  final Color color;
  final FontWeight weight;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: monoStyle.copyWith(fontSize: size, color: color, fontWeight: weight),
    );
  }
}

class StrikeText extends StatelessWidget {
  const StrikeText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: monoStyle.copyWith(
        fontSize: 10.5,
        color: AppColors.ink4,
        decoration: TextDecoration.lineThrough,
        decorationColor: AppColors.ink4,
      ),
    );
  }
}
