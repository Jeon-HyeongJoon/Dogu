import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../atoms/icon_box.dart';
import '../brand/dogu_brand_lockup.dart';

/// 상단 헤더 줄 — 메뉴 · 브랜드 락업 · 검색 · 장바구니. 무엇을 열지는 콜백으로만 알린다.
class DoguHeaderBar extends StatelessWidget {
  const DoguHeaderBar({this.cartBadge, this.onMenu, this.onSearch, this.onCart, super.key});

  /// 장바구니 아이콘 배지(없으면 숨김).
  final String? cartBadge;
  final VoidCallback? onMenu;
  final VoidCallback? onSearch;
  final VoidCallback? onCart;

  @override
  Widget build(BuildContext context) {
    // 아래 선은 가운데가 금빛인 한 줄(시안의 금박 rule) — 예전 1px 테두리와 높이가 같다.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpace.pad, 10, AppSpace.pad, 4),
          color: AppColors.bg,
          child: Row(
            children: [
              IconBox(icon: Icons.menu, label: '메뉴', onTap: onMenu),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    // 락업(마크 크기·오프셋)은 DoguBrandLockup에 있다 — 푸터와 공유.
                    // 헤더에 위젯을 더 추가하지 말 것: 좁은 뷰포트에서 오버플로한다.
                    DoguBrandLockup(),
                  ],
                ),
              ),
              Row(
                children: [
                  IconBox(icon: Icons.search, label: '검색', onTap: onSearch),
                  const SizedBox(width: 8),
                  IconBox(icon: Icons.shopping_cart_outlined, label: '장바구니', inverted: true, count: cartBadge, onTap: onCart),
                ],
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.line, AppColors.accent, AppColors.line]),
          ),
        ),
      ],
    );
  }
}
