import 'package:flutter/material.dart';

import '../atoms/eyebrow.dart';
import '../../tokens/tokens.dart';

class SectionHead extends StatelessWidget {
  const SectionHead({required this.index, required this.eyebrow, required this.title, this.link, this.onLinkTap, super.key});
  final String index;
  final String eyebrow;
  final String title;
  final String? link;
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 0, AppSpace.pad, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(index: index, text: eyebrow),
              Text(title, style: const TextStyle(fontSize: 34, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1.3)),
            ],
          ),
          if (link != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onLinkTap,
              child: Text(link!, style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
            ),
        ],
      ),
    );
  }
}
