import 'dart:async';

import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

// 매초 카운트다운 텍스트만 업데이트 — DealSection 전체 rebuild 방지
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({required this.initialSeconds, super.key});
  final int initialSeconds;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late final ValueNotifier<int> _seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _seconds = ValueNotifier(widget.initialSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds.value > 0) _seconds.value -= 1;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _seconds.dispose();
    super.dispose();
  }

  static String _format(int total) {
    final h = (total ~/ 3600).toString().padLeft(2, '0');
    final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _seconds,
      builder: (_, remaining, __) =>
          // 마감 시계는 빨간 면 — 딜의 '지금 아니면 없다'. 자릿수 폭이 고른 숫자로 초가 바뀌어도 흔들리지 않는다.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: AppColors.alert,
            child: Text(
              _format(remaining),
              style: const TextStyle(
                fontFamily: doguFontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.ink,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
    );
  }
}
