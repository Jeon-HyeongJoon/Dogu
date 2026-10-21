import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../atoms/mono_text.dart';
import '../atoms/price_text.dart';
import '../atoms/strike_text.dart';
import '../molecules/product_image.dart';
import '../molecules/qty_box.dart';

/// 장바구니 한 줄 — 선택 표시 · 썸네일 · 이름 · 가격 · 수량 · 삭제. 동작은 콜백으로만 알린다.
class CartLineView extends StatelessWidget {
  const CartLineView({
    required this.index,
    required this.brand,
    required this.name,
    required this.price,
    required this.quantity,
    this.oldPrice = '',
    this.discount = '',
    this.hasDiscount = false,
    this.note,
    this.imageUrl,
    this.selected = false,
    this.onToggle,
    this.onMinus,
    this.onPlus,
    this.onRemove,
    super.key,
  });

  /// 1부터 — 썸네일 위에 세 자리로 찍는다(001 …).
  final int index;
  final String brand;
  final String name;
  final String price;
  final int quantity;
  final String oldPrice;
  final String discount;
  final bool hasDiscount;

  /// 이름 아래 한 줄 안내(없으면 생략).
  final String? note;

  /// 앱이 풀어 둔 썸네일 주소.
  final String? imageUrl;
  final bool selected;
  final VoidCallback? onToggle;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.pad - 2),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [SizedBox(width: 96, height: 96, child: ProductImage(url: imageUrl, child: Padding(padding: const EdgeInsets.all(6), child: MonoText(index.toString().padLeft(3, '0'), size: 9, color: AppColors.ink4)))), Positioned(top: -2, left: -2, child: Container(width: 18, height: 18, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? AppColors.accent : AppColors.bg, border: Border.all(color: selected ? AppColors.accent : AppColors.line)), child: Text(selected ? '✓' : '', style: const TextStyle(color: AppColors.invert, fontSize: 11))))]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonoText(brand, size: 10, color: AppColors.ink4),
                  const SizedBox(height: 4),
                  Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.accentBright)),
                  if (note != null) ...[
                    const SizedBox(height: 4),
                    MonoText(note!, size: 10.5, color: AppColors.ink3),
                  ],
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [if (hasDiscount) PriceText(discount, size: 12, color: AppColors.alertBright), PriceText(price, size: 15), if (hasDiscount) StrikeText(oldPrice)]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [QtyBox(value: quantity.toString(), onMinus: onMinus, onPlus: onPlus), GestureDetector(onTap: onRemove, child: const MonoText('삭제 ×', size: 11, color: AppColors.ink4))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
