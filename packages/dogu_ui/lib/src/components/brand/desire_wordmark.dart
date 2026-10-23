import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// 'DESIRE' 워드마크 — 시안의 광고 머리. 금박 세리프에 가운데 'SI'만 이탤릭, 아래로 짙은 금 그림자를 깐다.
class DesireWordmark extends StatelessWidget {
  const DesireWordmark({this.size = 96, super.key});
  final double size;

  static const word = 'DESIRE';

  /// 글자 크기 대비 폭(Dogu Serif로 잰 값) — 화면 폭에 맞는 크기를 고를 때 쓴다.
  static const widthRatio = 3.7;

  /// [width] 안에 들어가는 가장 큰 크기(최대 [max]).
  static double sizeFor(double width, {double max = 168}) => (width * 0.94 / widthRatio).clamp(48.0, max);

  @override
  Widget build(BuildContext context) {
    final style = serifStyle.copyWith(
      fontSize: size,
      height: 0.95,
      letterSpacing: -size * 0.01,
      color: AppColors.accentBright,
      shadows: [
        Shadow(color: AppColors.accentDeep, offset: Offset(0, size * 0.025)),
        Shadow(color: const Color(0x80000000), offset: Offset(0, size * 0.05), blurRadius: size * 0.12),
      ],
    );
    return Semantics(
      label: word,
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            style: style,
            children: const [
              TextSpan(text: 'DE'),
              TextSpan(text: 'SI', style: TextStyle(fontStyle: FontStyle.italic)),
              TextSpan(text: 'RE'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
