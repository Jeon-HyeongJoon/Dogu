// 앱 번들의 에셋 키 → 저장소의 실제 파일 경로. 디자인 시스템이 담은 에셋(폰트·로고)은 키가
// 'packages/dogu_ui/…'이고, 파일은 저장소의 ../packages/dogu_ui/… 에 있다(테스트는 app/에서 돈다).
String assetFile(String key) => key.startsWith('packages/') ? '../$key' : key;

/// 디자인 시스템이 담은 폰트 디렉터리(charset.txt·NOTICE 포함).
const designFontsDir = '../packages/dogu_ui/assets/fonts';
