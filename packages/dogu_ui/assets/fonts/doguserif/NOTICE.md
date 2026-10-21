# Dogu Serif — Playfair Display 서브셋

이 디렉터리의 `DoguSerif-Bold.ttf`·`DoguSerif-BoldItalic.ttf`는 **Playfair Display(가변 서체, 바로·이탤릭)의
Bold(700) 인스턴스를 서브셋**한 것이다. 가격·큰 숫자·영문 디스플레이(섹션 제목, 광고 워드마크와 태그라인)에만
쓰여 라틴 글자·숫자 기호(`charset.txt`)만 남겼다(각 약 49KB). 첫 화면에 보여서 본문체와 함께 첫 페인트 전에 받는다.

## 바꾼 것

- 이름: 원본은 OFL **예약 폰트 이름(Reserved Font Name) "Playfair Display"**를 달고 있어, 수정본(인스턴스·서브셋)을
  원본 이름으로 배포할 수 없다. 내부 name 레코드를 `Dogu Serif`로 바꿔 담는다.
- 원화 기호(₩, U+20A9): 원본에 없어서 W 글리프 위에 가로줄 두 개를 그어 합성했다(`scripts/build_fonts.sh`의
  `add_won_sign`). 나머지 자형은 원본 그대로다.

## 출처와 라이선스

- Copyright 2017 The Playfair Display Project Authors (https://github.com/clauseggers/Playfair-Display)
- 라이선스: SIL Open Font License 1.1 — `OFL.txt`
- 재생성: `scripts/build_fonts.sh`
