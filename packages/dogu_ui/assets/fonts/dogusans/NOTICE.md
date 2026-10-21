# Dogu Sans — Pretendard 서브셋

이 디렉터리의 `DoguSans-*.otf`는 **Pretendard v1.3.9의 서브셋**이다.
원본은 한글 11,172자를 모두 담아 굵기당 약 1.5MB인데, 앱이 실제로 그리는 글자만
남겨 굵기당 약 350KB로 줄였다. `charset.txt`가 담긴 문자 집합이다.

## 이름을 바꾼 이유

Pretendard는 SIL Open Font License 1.1이면서 예약 폰트 이름(Reserved Font Name)
`Pretendard`가 선언돼 있다. 서브셋은 OFL이 정의하는 Modified Version이므로,
사용자에게 보이는 폰트 이름으로 예약 이름을 쓸 수 없다(OFL 1.1 §3).
그래서 내부 name 레코드를 `Dogu Sans`로 바꿔 담는다. 자형은 원본 그대로다.

- 원저작권: Copyright (c) 2021, Kil Hyung-jin — https://github.com/orioncactus/pretendard
- 라이선스: `LICENSE.txt`(OFL 1.1 원문, 원본 배포본에서 그대로 가져옴)
- 재생성: `scripts/build_fonts.sh`

