import 'dart:async';

import 'package:flutter/material.dart';

import '../atoms/mono_text.dart';
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
          MonoText(_format(remaining), size: 18, color: AppColors.invert, weight: FontWeight.w600),
    );
  }
}
