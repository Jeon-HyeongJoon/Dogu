import 'dart:math';

import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// 브랜드 마크 — 쇼핑백 실루엣 + 중앙의 "욕망의 도트".
/// 벡터(CustomPainter)라 어떤 크기에서도 선명하고, 색을 테마에
/// 맞춰 바꿀 수 있다. 기존 항아리 일러스트는 소형에서 뭉개져 벡터로 교체.
class DoguBrandMark extends StatelessWidget {
  const DoguBrandMark({
    required this.size,
    this.bag = AppColors.accent,
    this.dot = AppColors.alert,
    super.key,
  });

  final double size;
  final Color bag;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _DoguBrandMarkPainter(bag: bag, dot: dot),
    );
  }
}

class _DoguBrandMarkPainter extends CustomPainter {
  const _DoguBrandMarkPainter({required this.bag, required this.dot});
  final Color bag;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 24; // 24 그리드 기준 좌표계

    // 손잡이 — 몸통 위로 솟은 반원 스트로크
    canvas.drawArc(
      Rect.fromCircle(center: Offset(12 * u, 8.6 * u), radius: 4.1 * u),
      pi,
      pi,
      false,
      Paint()
        ..color = bag
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1 * u
        ..strokeCap = StrokeCap.round,
    );
    // 몸통
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(3.6 * u, 8.4 * u, 20.4 * u, 21.6 * u),
        Radius.circular(2.4 * u),
      ),
      Paint()..color = bag,
    );
    // 욕망의 도트 — 몸통 중앙 액센트
    canvas.drawCircle(Offset(12 * u, 15 * u), 2.7 * u, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_DoguBrandMarkPainter oldDelegate) =>
      oldDelegate.bag != bag || oldDelegate.dot != dot;
}
