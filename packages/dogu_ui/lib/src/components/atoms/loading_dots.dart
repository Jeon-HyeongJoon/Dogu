import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// 점 세 개 로딩 표시 — 세 점이 차례로 밝아진다. 점은 글리프가 아니라 도형으로 그린다
/// (서브셋 폰트에 없는 글자를 늘리지 않으려고). 애니메이션 끄기 설정이면 멈춘 점.
class LoadingDots extends StatefulWidget {
  const LoadingDots({this.color = AppColors.ink3, super.key});
  final Color color;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 점 i는 0.2주기씩 늦게 밝아졌다가 어두워진다(삼각파). 멈춰 있으면 중간 밝기.
  double _opacity(int i) {
    if (!_controller.isAnimating) return 0.6;
    final phase = (_controller.value - i * 0.2) % 1.0;
    return 0.25 + 0.75 * (1 - (phase * 2 - 1).abs());
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '불러오는 중',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(color: widget.color.withValues(alpha: _opacity(i)), shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
