import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class SoftDividerBlock extends StatelessWidget {
  const SoftDividerBlock({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.bgSoft, width: 8))),
      child: child,
    );
  }
}
