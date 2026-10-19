import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class RecentSearchTag extends StatelessWidget {
  const RecentSearchTag({required this.label, this.onTap, this.onRemove, super.key});

  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), color: AppColors.bg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            key: Key('recent-remove-$label'),
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: const Text('×', style: TextStyle(fontSize: 12, color: AppColors.ink4)),
          ),
        ],
      ),
    );
  }
}
