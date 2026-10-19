// 기능 모듈 테스트의 공통 준비. 모든 test/features/<기능>/*_test.dart는 main() 첫 줄에서 부른다.
//
// 모듈 구조: test/features/<기능>/ 디렉터리 하나가 CI의 잡 하나다(.github/workflows/ci.yml이
// 디렉터리를 찾아 매트릭스로 돌린다). 새 기능은 디렉터리를 추가하면 CI에 자동으로 들어간다.
// 로컬: app/scripts/test_modules.sh [기능 ...]
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void setUpDoguTest() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // 테스트마다 기기 저장소(장바구니·찜·최근 검색어)를 비운다.
  setUp(() => SharedPreferences.setMockInitialValues({}));
}
