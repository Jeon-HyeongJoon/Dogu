@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:dogu_mobile_shop/main.dart';

// 프론트–백엔드 연동(계약) 테스트 — 실제로 떠 있는 백엔드에 붙어서
// DoguRepository가 응답을 앱 모델로 파싱하는지 확인한다.
// 위젯 테스트의 가짜 리포지토리로는 잡히지 않는 것들을 잡는다:
//   · 백엔드 응답 스키마가 바뀌어 프론트 파서가 빈 리스트를 뱉는 회귀
//   · API_BASE_URL이 주입되지 않아 배포본이 localhost를 호출하는 사고
//
// 기본은 skip — 백엔드 없이 도는 `flutter test`를 깨뜨리지 않는다.
// 실행:
//   backend/scripts/run_local.sh  (또는 CI의 backend-integration 잡)
//   flutter test test/backend_contract_test.dart \
//     --dart-define=BACKEND_INTEGRATION=true \
//     --dart-define=API_BASE_URL=http://127.0.0.1:8000
const _enabled = bool.fromEnvironment('BACKEND_INTEGRATION');
const _skipReason = '살아 있는 백엔드가 필요하다 — --dart-define=BACKEND_INTEGRATION=true 로 실행';

void main() {
  final repository = DoguRepository();

  test('API_BASE_URL이 주입되면 ApiConfig가 그 주소를 쓴다 (localhost 폴백 금지)', () {
    // 배포 사고의 근본 원인을 그대로 고정한다: dart-define이 없으면 localhost로 폴백한다.
    expect(ApiConfig.baseUrl, isNotEmpty);
    expect(
      ApiConfig.baseUrl,
      isNot(contains('localhost')),
      reason: 'API_BASE_URL이 주입되지 않았다 — 이 상태로 빌드하면 배포본이 사용자의 localhost를 호출한다',
    );
  }, skip: _enabled ? false : _skipReason);

  test('/health 응답', () async {
    await repository.checkHealth();
  }, skip: _enabled ? false : _skipReason);

  test('/api/home 이 히어로 섹션을 준다', () async {
    final home = await repository.fetchHome();
    expect(home, isNotEmpty);
    expect(home.containsKey('hero'), isTrue, reason: '홈 히어로가 없으면 첫 화면이 폴백 seed로 떨어진다');
  }, skip: _enabled ? false : _skipReason);

  test('/api/products 가 앱 모델로 파싱된다', () async {
    final products = await repository.fetchProducts(limit: 5);
    expect(products, isNotEmpty, reason: '파서가 빈 리스트를 뱉으면 스키마가 어긋난 것');
    final first = products.first;
    expect(first.id, isNotEmpty);
    expect(first.name, isNotEmpty);
    expect(first.price, isNotEmpty);
    expect(first.numericPrice, greaterThan(0), reason: '가격 문자열에서 숫자를 못 뽑으면 합계·결제가 0원이 된다');
  }, skip: _enabled ? false : _skipReason);

  test('/api/products/:id 가 같은 상품을 준다', () async {
    final products = await repository.fetchProducts(limit: 1);
    final detail = await repository.fetchProduct(products.first.id);
    expect(detail.id, products.first.id);
    expect(detail.name, isNotEmpty);
  }, skip: _enabled ? false : _skipReason);

  test('/api/categories 가 앱 모델로 파싱된다', () async {
    final categories = await repository.fetchCategories();
    expect(categories, isNotEmpty);
    expect(categories.first.name, isNotEmpty);
  }, skip: _enabled ? false : _skipReason);

  test('/api/search 가 결과를 준다', () async {
    final products = await repository.fetchProducts(limit: 1);
    final term = products.first.name.split(' ').first;
    final results = await repository.searchProducts(term);
    expect(results, isNotEmpty, reason: '"$term" 검색이 비었다면 검색 계약이 깨진 것');
  }, skip: _enabled ? false : _skipReason);

  test('검색 트렌드·추천어·뉴스레터가 파싱된다', () async {
    expect(await repository.fetchTrending(), isNotEmpty);
    expect(await repository.fetchSuggestions(), isNotEmpty);
    final newsletter = await repository.fetchNewsletter();
    expect(newsletter['title'], isNotNull);
  }, skip: _enabled ? false : _skipReason);

  test('/api/orders 가 주문을 받는다 — 결제 완료 흐름의 입구', () async {
    final products = await repository.fetchProducts(limit: 1);
    final response = await repository.submitOrder([(product: products.first, quantity: 2)]);
    expect(response['order_id'], isNotNull);
    expect((response['items'] as List).length, 1);
    expect((response['total_price'] as num).toInt(), products.first.numericPrice * 2);
  }, skip: _enabled ? false : _skipReason);
}
