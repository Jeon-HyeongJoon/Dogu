import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class SmallChip extends StatelessWidget {
  const SmallChip({required this.text, this.active = false, super.key});
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: active ? AppColors.accent : AppColors.bg, border: Border.all(color: active ? AppColors.accent : AppColors.line)),
      child: Text(text, style: TextStyle(fontSize: 12, color: active ? AppColors.invert : AppColors.ink2)),
    );
  }
}
