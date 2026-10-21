import 'package:flutter/material.dart';

import '../atoms/gold_sparkle.dart';
import '../../tokens/tokens.dart';
import 'dogu_brand_mark.dart';

/// 항아리 메달 — 브랜드 엠블럼(가로형)을 타원으로 잘라 금테 두 겹을 두르고 양옆에 금 별을 단다(시안의 광고 메달).
/// 그림은 정본 design/assets/logo.jpg의 파생본(scripts/sync_logo.sh).
class DoguMedal extends StatelessWidget {
  const DoguMedal({this.width = 280, super.key});

  /// 타원(그림) 폭 — 높이는 그림 비율(약 0.55)을 따른다.
  final double width;

  static const assetKey = 'packages/dogu_ui/assets/logo-medal.jpg';
  static const aspect = 720 / 393;

  @override
  Widget build(BuildContext context) {
    final height = width / aspect;
    final sparkle = (width * 0.07).clamp(10.0, 22.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GoldSparkle(size: sparkle),
        SizedBox(width: width * 0.06),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const ShapeDecoration(
            color: AppColors.potDeep,
            shape: OvalBorder(side: BorderSide(color: AppColors.accent, width: 1.2)),
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const ShapeDecoration(
              shape: OvalBorder(side: BorderSide(color: AppColors.accentDeep, width: AppStroke.hair)),
            ),
            child: ClipOval(
              child: Image.asset(
                assetKey,
                width: width,
                height: height,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stack) => SizedBox(
                  width: width,
                  height: height,
                  child: const ColoredBox(color: AppColors.cream, child: Center(child: DoguBrandMark(size: 48))),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: width * 0.06),
        GoldSparkle(size: sparkle),
      ],
    );
  }
}
