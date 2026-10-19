import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class NavLabel extends StatelessWidget {
  const NavLabel({required this.text, this.active = false, this.sale = false, super.key});
  final String text;
  final bool active;
  final bool sale;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: sale ? FontWeight.w700 : FontWeight.w500,
            color: sale ? AppColors.accent : (active ? AppColors.ink : AppColors.ink3),
          ),
        ),
        const SizedBox(height: 14),
        Container(width: active ? 42 : 0, height: 2, color: active ? AppColors.ink : Colors.transparent),
      ],
    );
  }
}
