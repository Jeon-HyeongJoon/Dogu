// 여러 모듈이 쓰는 고정 상품 데이터.
import 'package:dogu_mobile_shop/main.dart';

const homeProduct = ProductItem(
  id: 'home-soft-knit',
  brand: 'HOME',
  name: '홈 니트',
  price: '₩39,000',
  oldPrice: '₩49,000',
  discount: '-20%',
  pattern: PatternKind.dots,
);

const searchProduct = ProductItem(
  id: 'search-lamp',
  brand: 'SEARCH',
  name: '검색 램프',
  price: '₩79,000',
  oldPrice: '₩99,000',
  discount: '-20%',
  pattern: PatternKind.grid,
);

// 시작 카탈로그(백엔드 상위 100개 + 홈) 밖에 있는 상품 — 장바구니·찜 스냅샷 테스트용.
const knit = ProductItem(
  id: 'food-honey', brand: '믿음벌꿀', name: '천연 아카시아꿀', price: '₩23,900', oldPrice: '₩29,000', discount: '-18%',
  pattern: PatternKind.dots, categoryIds: ['10000114'], imageUrl: 'https://shopping-phinf.pstatic.net/a.jpg',
  rating: 4.7, reviews: 1200, tags: ['today_deal'],
  artwork: ProductArtwork(hue: 10, saturation: 20, lightness: 30, mono: '//', motif: 'dots'),
);
