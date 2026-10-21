import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class QuickFilterRow extends StatefulWidget {
  const QuickFilterRow({required this.items, this.activeIndex, this.onSelectedIndex, super.key});
  final List<String> items;
  final int? activeIndex;
  final ValueChanged<int>? onSelectedIndex;

  @override
  State<QuickFilterRow> createState() => _QuickFilterRowState();
}

class _QuickFilterRowState extends State<QuickFilterRow> {
  int _activeIndex = 0;

  @override
  void didUpdateWidget(covariant QuickFilterRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != null && widget.activeIndex != _activeIndex) {
      _activeIndex = widget.activeIndex!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = widget.activeIndex ?? _activeIndex;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.pad, vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line, width: AppStroke.hair))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < widget.items.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (widget.onSelectedIndex != null) {
                    widget.onSelectedIndex!(i);
                  } else {
                    setState(() => _activeIndex = i);
                  }
                },
                child: Container(
                  height: 32,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == activeIndex ? AppColors.accent : AppColors.bg,
                    border: Border.all(color: i == activeIndex ? AppColors.accent : AppColors.line, width: AppStroke.hair),
                  ),
                  child: Text(widget.items[i], style: TextStyle(fontSize: 12.5, color: i == activeIndex ? AppColors.invert : AppColors.ink2)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
