# dogu_ui_catalog

dogu_ui 디자인 시스템 카탈로그(Widgetbook).

- `lib/use_cases.dart` — 컴포넌트별 사용 사례. 카탈로그와 컴포넌트 골든 테스트가 **같은 목록**을 쓴다
- `test/component_goldens_test.dart` — 사례마다 골든 하나(`test/goldens/<group>/<Component>/<case>.png`).
  정본은 CI(ubuntu) 렌더 — 로컬 macOS에선 폰트/AA 차이로 깨지니 `flutter test --exclude-tags golden`

```sh
flutter run -d chrome        # 카탈로그 띄우기
flutter build web            # 정적 사이트로 빌드
```
