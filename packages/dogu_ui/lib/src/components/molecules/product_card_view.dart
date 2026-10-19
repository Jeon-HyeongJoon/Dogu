import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../atoms/badge_pill.dart';
import '../atoms/mono_text.dart';
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

/// 상품 카드 — 누르면 살짝 줄어든다(0.97). 탭·찜은 콜백으로만 알린다.
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
    final line = dark ? const Color(0xff1f1f1f) : AppColors.line;
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
                      onTap: widget.onWishTap,
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
