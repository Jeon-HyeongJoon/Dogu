import 'package:flutter/material.dart';

import '../atoms/mono_text.dart';
import '../../tokens/tokens.dart';

class QtyBox extends StatelessWidget {
  const QtyBox({required this.value, this.onMinus, this.onPlus, this.buttonExtent = 48, this.valueExtent = 40, super.key});
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final double buttonExtent;
  final double valueExtent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
      child: Row(children: [GestureDetector(behavior: HitTestBehavior.opaque, onTap: onMinus, child: SizedBox(width: buttonExtent, height: buttonExtent, child: const Center(child: MonoText('−', size: 16)))), Container(width: valueExtent, height: buttonExtent, alignment: Alignment.center, decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.line), right: BorderSide(color: AppColors.line))), child: MonoText(value, size: 13, weight: FontWeight.w700)), GestureDetector(behavior: HitTestBehavior.opaque, onTap: onPlus, child: SizedBox(width: buttonExtent, height: buttonExtent, child: const Center(child: MonoText('+', size: 16))))]),
    );
  }
}
