import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../atoms/loading_dots.dart';
import '../atoms/nav_label.dart';

/// 상단 텍스트 내비게이션 항목.
class DoguNavItem {
  const DoguNavItem({required this.label, this.active = false, this.sale = false});

  final String label;
  final bool active;

  /// 세일 강조(초록 굵은 글씨).
  final bool sale;
}

/// '신상품 | 베스트 | … | SALE' 같은 가로 내비게이션. [loadingIndex]가 있으면 그 자리에 로딩 점을 끼운다.
class DoguNavBar extends StatelessWidget {
  const DoguNavBar({required this.items, required this.onTap, this.loadingIndex, super.key});

  final List<DoguNavItem> items;
  final ValueChanged<int> onTap;
  final int? loadingIndex;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      for (var i = 0; i < items.length; i++)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(i),
          child: NavLabel(text: items[i].label, sale: items[i].sale, active: items[i].active),
        ),
    ];
    if (loadingIndex != null) cells.insert(loadingIndex!, const Padding(padding: EdgeInsets.only(top: 6), child: LoadingDots()));
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 12, AppSpace.pad, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              cells[i],
              if (i != cells.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 11),
                  child: Text('|', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300, color: AppColors.ink4)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
