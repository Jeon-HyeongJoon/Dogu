import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../atoms/badge_pill.dart';

/// 하단 탭 하나 — 배지가 있으면 [badgeColor]로 아이콘 오른쪽 위에 띄운다.
class DoguTab {
  const DoguTab({required this.icon, required this.label, this.badge, this.badgeColor = AppColors.accent});

  final IconData icon;
  final String label;
  final String? badge;
  final Color badgeColor;
}

/// 하단 탭 바. 선택된 탭은 위쪽 막대와 진한 색으로 표시한다.
class DoguTabBar extends StatelessWidget {
  const DoguTabBar({required this.tabs, required this.currentIndex, required this.onTap, this.bottomInset = 0, super.key});

  /// 탭 바 높이(기기 하단 여백 제외).
  static const barHeight = 70.0;

  final List<DoguTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// 홈 인디케이터 등 기기 하단 여백.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: barHeight + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.potDeep,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (i == currentIndex) Container(width: 38, height: 2, color: AppColors.accent),
                    Padding(
                      padding: const EdgeInsets.only(top: 11),
                      child: Column(
                        children: [
                          Icon(tabs[i].icon, size: 21, color: i == currentIndex ? AppColors.accentBright : AppColors.ink4),
                          const SizedBox(height: 4),
                          Text(tabs[i].label, style: TextStyle(fontSize: 10.5, color: i == currentIndex ? AppColors.accentBright : AppColors.ink4, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (tabs[i].badge != null) Positioned(top: 7, right: 20, child: BadgePill(text: tabs[i].badge!, color: tabs[i].badgeColor, compact: true)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
