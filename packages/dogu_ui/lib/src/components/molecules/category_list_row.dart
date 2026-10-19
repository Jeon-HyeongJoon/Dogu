import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../atoms/mono_text.dart';

/// 카테고리 목록 한 줄 — 두 자리 번호 · 이름 · 설명 · 화살표.
class CategoryListRow extends StatelessWidget {
  const CategoryListRow({required this.index, required this.name, required this.description, this.onTap, super.key});

  /// 1부터 — 두 자리로 찍는다.
  final int index;
  final String name;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: MonoText(index.toString().padLeft(2, '0'), size: 11, color: AppColors.ink4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 11.5, color: AppColors.ink3, height: 1.5)),
                ],
              ),
            ),
            const Text('→'),
          ],
        ),
      ),
    );
  }
}
