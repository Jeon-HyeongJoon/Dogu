import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class SectionBorder extends StatelessWidget {
  const SectionBorder({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: child,
    );
  }
}
