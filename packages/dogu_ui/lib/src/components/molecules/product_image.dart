import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import 'preparing_image_surface.dart';

/// 상품 이미지. [url]은 앱이 이미 풀어 둔 주소(프록시·축소본 등)다 — 디자인 시스템은 주소 규칙을 모른다.
/// 주소가 없거나, 받는 중이거나, 실패하면 모두 같은 '이미지 준비 중' 자리를 보여 준다.
class ProductImage extends StatelessWidget {
  const ProductImage({this.url, this.child, this.dark = false, super.key});

  final String? url;

  /// 이미지 위에 겹칠 것(할인·뱃지 등).
  final Widget? child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final preparing = PreparingImageSurface(dark: dark, child: child);
    final source = url?.trim();
    if (source == null || source.isEmpty) return preparing;

    return Container(
      decoration: BoxDecoration(border: Border.all(color: dark ? AppColors.deepLine : AppColors.line, width: AppStroke.hair)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            source,
            fit: BoxFit.cover,
            loadingBuilder: (context, childWidget, loadingProgress) {
              if (loadingProgress == null) return childWidget;
              return preparing;
            },
            errorBuilder: (context, error, stackTrace) => preparing,
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
