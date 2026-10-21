import 'package:flutter/material.dart';

import '../atoms/loading_dots.dart';
import '../atoms/mono_text.dart';
import '../atoms/price_text.dart';
import '../../tokens/tokens.dart';

/// 숫자 요약 줄(히어로의 신상품·브랜드·평균 할인 등). [loading]이면 같은 자리에 로딩 점.
class StatGrid extends StatelessWidget {
  const StatGrid({required this.stats, this.dark = false, this.loading = false, super.key});

  final List<(String, String)> stats;
  final bool dark;
  final bool loading;

  // 로딩 중 높이를 재는 데 쓰는 보이지 않는 자리 표시 — 숫자·라벨 한 줄씩이면 된다.
  static const _placeholder = [('0', '0')];

  @override
  Widget build(BuildContext context) {
    final lineColor = dark ? AppColors.heroLine : AppColors.line;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: lineColor, width: AppStroke.hair), bottom: BorderSide(color: lineColor, width: AppStroke.hair)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: loading
          // 숫자 줄과 같은 높이를 글꼴과 무관하게 확보한다 — 보이지 않는 숫자 줄을 깔고 그 위에 로딩 점.
          // (예전엔 높이를 44로 어림잡아 실제 글꼴에서 2px, 테스트 글꼴에선 31px 어긋났다.)
          ? Stack(
              alignment: Alignment.center,
              children: [
                Visibility(
                  visible: false,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: _row(stats.isEmpty ? _placeholder : stats, lineColor),
                ),
                const LoadingDots(),
              ],
            )
          : _row(stats, lineColor),
    );
  }

  Widget _row(List<(String, String)> stats, Color lineColor) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: i == 0 ? null : Border(left: BorderSide(color: lineColor, width: AppStroke.hair)),
              ),
              // 가운데 맞춤 띠(시안의 24K GOLD SEASON · LIMITED HOUSE EDITION 줄)
              child: Column(
                children: [
                  PriceText(stats[i].$1, size: 22, color: dark ? AppColors.accentBright : AppColors.ink),
                  const SizedBox(height: 3),
                  MonoText(stats[i].$2, size: 10, color: dark ? AppColors.heroInk3 : AppColors.ink4, weight: FontWeight.w500),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
