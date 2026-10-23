import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// 카드 격자 — 폭에 맞춰 3·4·5열로 놓는다(좁은 휴대폰도 3열). 예전엔 한 줄에 2개였다.
/// 칸 높이를 고정하지 않고 줄마다 위에 맞춰 쌓는다 — 상품명이 한 줄이든 두 줄이든 넘치지 않는다.
class CardGrid extends StatelessWidget {
  const CardGrid({required this.children, this.spacing = AppSpace.gutter, this.runSpacing = 22, super.key});

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  /// 폭에 따른 열 수 — 560 미만 3열, 1100 미만 4열, 그 위 5열.
  static int columnsFor(double width) => width >= 1100 ? 5 : (width >= 560 ? 4 : 3);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnsFor(constraints.maxWidth);
        final rows = (children.length / columns).ceil();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var row = 0; row < rows; row++)
              Padding(
                padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : runSpacing),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var col = 0; col < columns; col++) ...[
                      if (col > 0) SizedBox(width: spacing),
                      Expanded(child: row * columns + col < children.length ? children[row * columns + col] : const SizedBox.shrink()),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
