import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../atoms/mono_text.dart';

/// 카테고리 칸 — 두 자리 번호와 이름.
class CategoryTile extends StatelessWidget {
  const CategoryTile({required this.index, required this.name, this.onTap, super.key});

  /// 1부터 — 두 자리로 찍는다(01, 02 …).
  final int index;
  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MonoText(index.toString().padLeft(2, '0'), size: 8.5, color: AppColors.accent),
            const SizedBox(height: 5),
            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
