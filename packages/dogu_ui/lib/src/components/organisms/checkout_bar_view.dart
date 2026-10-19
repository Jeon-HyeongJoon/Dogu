import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../atoms/mono_text.dart';

/// 화면 아래 결제 바 — 금액과 결제 버튼. [enabled]가 아니면 버튼이 어두워지고 눌리지 않는다.
class CheckoutBarView extends StatelessWidget {
  const CheckoutBarView({required this.label, required this.total, required this.buttonLabel, this.enabled = true, this.onCheckout, super.key});

  /// 결제 바 높이(기기 하단 여백 제외).
  static const barHeight = 83.0;

  final String label;
  final String total;
  final String buttonLabel;
  final bool enabled;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: barHeight,
      padding: const EdgeInsets.fromLTRB(AppSpace.pad, 16, AppSpace.pad, 18),
      decoration: const BoxDecoration(color: AppColors.ink, border: Border(top: BorderSide(color: Color(0xff1a1a1a)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [MonoText(label, size: 10, color: AppColors.ink4), MonoText(total, size: 18, color: AppColors.invert, weight: FontWeight.w800)]),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onCheckout : null,
            child: Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 22), alignment: Alignment.center, color: enabled ? AppColors.alert : AppColors.ink2, child: Text(buttonLabel, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
          ),
        ],
      ),
    );
  }
}
