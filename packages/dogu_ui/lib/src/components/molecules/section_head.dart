import 'package:flutter/material.dart';

import '../atoms/mono_text.dart';
import '../../tokens/tokens.dart';

/// 섹션 머리 — 시안처럼 영문 제목을 대문자 세리프(금)로 크게, 한글 제목은 그 아래 크림색으로 작게 쓴다.
/// 맨 위 'No.01' 뒤로 머리카락 금선이 끝까지 이어진다. [trailing]은 오른쪽 끝(딜 마감 시계 등),
/// [link]는 '전체 →' 같은 이동 링크.
class SectionHead extends StatelessWidget {
  const SectionHead({
    required this.index,
    required this.eyebrow,
    required this.title,
    this.link,
    this.onLinkTap,
    this.trailing,
    super.key,
  });

  final String index;

  /// 영문 제목(대문자) — 'SHOP BY CATEGORY'.
  final String eyebrow;

  /// 한글 제목 — '카테고리'.
  final String title;
  final String? link;
  final VoidCallback? onLinkTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 0, AppSpace.pad, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MonoText('No.$index', size: 9.5, color: AppColors.accent, weight: FontWeight.w600),
              const SizedBox(width: 10),
              Expanded(child: Container(height: AppStroke.hair, color: AppColors.line)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(eyebrow, style: displayStyle.copyWith(fontSize: 20, color: AppColors.accentBright)),
                    const SizedBox(height: 5),
                    Text(title, style: const TextStyle(fontSize: 12.5, height: 1.3, color: AppColors.ink2, fontWeight: FontWeight.w500, letterSpacing: 0.4)),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              if (link != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onLinkTap,
                  child: Text(link!, style: const TextStyle(fontSize: 11.5, color: AppColors.accent, letterSpacing: 0.6, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
