import 'package:flutter/material.dart';

import '../atoms/price_text.dart';
import '../../tokens/tokens.dart';

class SummaryLine extends StatelessWidget {
  const SummaryLine({required this.label, required this.value, this.accent = false, this.total = false, super.key});
  final String label;
  final String value;
  final bool accent;
  final bool total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: total ? 14 : 13, fontWeight: total ? FontWeight.w700 : FontWeight.w400, color: AppColors.ink2)), PriceText(value, size: total ? 22 : 14, color: accent ? AppColors.alertBright : (total ? AppColors.accentBright : AppColors.ink))]),
    );
  }
}
