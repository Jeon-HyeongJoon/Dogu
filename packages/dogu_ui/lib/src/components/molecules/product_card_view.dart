import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../atoms/badge_pill.dart';
import '../atoms/mono_text.dart';
import '../atoms/price_text.dart';
import '../atoms/strike_text.dart';
import 'product_image.dart';

/// 상품 카드에 그릴 내용 — 앱의 상품 모델을 모른다. 문자열은 앱이 표시 형식으로 만들어 넘긴다.
class ProductCardData {
  const ProductCardData({
    required this.brand,
    required this.name,
    required this.price,
    this.oldPrice = '',
    this.discount = '',
    this.hasDiscount = false,
    this.badge,
    this.subtitle = '',
    this.meta = '',
    this.imageUrl,
  });

  final String brand;
  final String name;
  final String price;
  final String oldPrice;
  final String discount;
  final bool hasDiscount;
  final String? badge;
  final String subtitle;
  final String meta;

  /// 앱이 풀어 둔 이미지 주소(없으면 '이미지 준비 중').
  final String? imageUrl;
}

/// 상품 카드 — 격자에 3~5개씩 놓는 작은 카드. 누르면 살짝 줄어든다(0.97). 탭·찜은 콜백으로만 알린다.
class ProductCardView extends StatefulWidget {
  const ProductCardView({required this.data, this.wished = false, this.dark = false, this.onTap, this.onWishTap, super.key});

  final ProductCardData data;
  final bool wished;

  /// 어두운 섹션(오늘의 딜) 위에 놓일 때.
  final bool dark;
  final VoidCallback? onTap;
  final VoidCallback? onWishTap;

  @override
  State<ProductCardView> createState() => _ProductCardViewState();
}

class _ProductCardViewState extends State<ProductCardView> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final wished = widget.wished;
    final product = widget.data;
    final dark = widget.dark;
    // 상품명은 늘 두 줄 자리를 잡는다 — 한 줄짜리 옆 카드와 가격 줄이 어긋나지 않게.
    final nameHeight = MediaQuery.textScalerOf(context).scale(_nameSize) * _nameLineHeight * 2;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ProductImage(
                url: product.imageUrl,
                dark: dark,
                child: Stack(
                  children: [
                    if (product.hasDiscount)
                      Positioned(top: 5, left: 5, child: BadgePill(text: product.discount, color: AppColors.alert, compact: true)), // 할인은 빨간 면
                    if (product.badge != null)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: BadgePill(text: product.badge!, color: dark ? AppColors.deep : AppColors.bgAlt, ink: AppColors.accentBright, bordered: true, compact: true),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            MonoText(product.brand, size: 8.5, color: AppColors.ink4, maxLines: 1),
            const SizedBox(height: 3),
            SizedBox(
              height: nameHeight,
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: _nameSize, height: _nameLineHeight, color: AppColors.ink, fontWeight: FontWeight.w500),
              ),
            ),
            if (product.subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(product.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.ink3)),
              ),
            const SizedBox(height: 6),
            PriceText(product.price, size: 13.5),
            if (product.hasDiscount)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Wrap(
                  spacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PriceText(product.discount, size: 10.5, color: AppColors.alertBright),
                    StrikeText(product.oldPrice, size: 9.5),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: MonoText(product.meta, size: 8.5, color: AppColors.ink4, maxLines: 1)),
                const SizedBox(width: 4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onWishTap,
                  child: MonoText(wished ? 'WISH ♥' : 'WISH +', size: 8.5, color: wished ? AppColors.alertBright : AppColors.ink3, weight: wished ? FontWeight.w700 : FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _nameSize = 11.5;
  static const _nameLineHeight = 1.3;
}
