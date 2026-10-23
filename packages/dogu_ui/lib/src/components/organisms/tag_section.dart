import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../atoms/loading_dots.dart';
import '../atoms/tag.dart';
import '../molecules/recent_search_tag.dart';

/// 제목 + 태그 묶음(검색 탭의 최근 검색·추천 브랜드 등).
/// [onRemove]가 있으면 태그마다 지우기(×)가 붙는다. [loading]이면 태그 자리에 로딩 점,
/// 태그가 없으면 [emptyText](없으면 빈 자리). 동작 버튼([action])은 태그가 있을 때만 보인다.
class TagSection extends StatelessWidget {
  const TagSection({
    required this.title,
    required this.tags,
    this.action,
    this.onAction,
    this.onTagTap,
    this.onRemove,
    this.loading = false,
    this.emptyText,
    super.key,
  });

  final String title;
  final List<String> tags;
  final String? action;
  final VoidCallback? onAction;
  final ValueChanged<String>? onTagTap;
  final ValueChanged<String>? onRemove;
  final bool loading;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 22, AppSpace.pad, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _title(),
              if (action != null && tags.isNotEmpty) GestureDetector(onTap: onAction, child: Text(action!, style: const TextStyle(fontSize: 11, color: AppColors.ink4))),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LoadingDots())
          else if (tags.isEmpty && emptyText != null)
            Text(emptyText!, style: const TextStyle(fontSize: 12.5, color: AppColors.ink4))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in tags)
                  onRemove != null
                      ? RecentSearchTag(
                          label: tag,
                          onTap: onTagTap == null ? null : () => onTagTap!(tag),
                          onRemove: () => onRemove!(tag),
                        )
                      : GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onTagTap == null ? null : () => onTagTap!(tag),
                          child: Tag(text: tag, compact: true),
                        ),
              ],
            ),
        ],
      ),
    );
  }

  /// '[ 01 ] 최근 검색' — 대괄호 번호만 금, 한글 이름은 크림(금색 한글은 쓰지 않는다).
  Widget _title() {
    final close = title.indexOf(']');
    final style = monoStyle.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ink2, letterSpacing: 1.2);
    if (!title.startsWith('[') || close < 0) return Text(title, style: style);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: title.substring(0, close + 1), style: const TextStyle(color: AppColors.accent)),
          TextSpan(text: title.substring(close + 1)),
        ],
      ),
    );
  }
}
