part of '../main.dart';

class PaymentToastOverlay extends StatefulWidget {
  const PaymentToastOverlay({required this.orderSummary, this.onConfirm, super.key});

  final Map<String, dynamic> orderSummary;
  /// 확인 탭 — 완료된 주문 응답을 넘겨 배송 안내 흐름으로 잇는다.
  final void Function(Map<String, dynamic> response)? onConfirm;

  @override
  State<PaymentToastOverlay> createState() => _PaymentToastOverlayState();
}

class _PaymentToastOverlayState extends State<PaymentToastOverlay> {
  bool _submitting = false;
  Map<String, dynamic>? _response;

  Future<void> _completePayment() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
    });
    final store = AppStateScope.read(context);
    try {
      final results = await Future.wait<dynamic>([
        store.submitSelectedOrder(),
        Future<void>.delayed(const Duration(milliseconds: 650)),
      ]);
      if (!mounted) return;
      setState(() {
        _response = results.first as Map<String, dynamic>;
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.orderSummary['items'] as List<dynamic>? ?? const []).cast<String>();
    final count = widget.orderSummary['count'] as int? ?? 0;
    final total = widget.orderSummary['total'] as int? ?? 0;

    // 하단 네비게이션 바 높이만큼 띄워 바로 위에 밀착(이어져 올라오는 느낌)
    final navBarHeight = AppLayout.tabHeight + MediaQuery.viewPaddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: navBarHeight),
          decoration: BoxDecoration(
            color: AppColors.bg,
            border: Border.all(color: AppColors.accentDeep, width: AppStroke.hair),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 24, offset: Offset(0, -2))],
          ),
            padding: const EdgeInsets.fromLTRB(AppSpace.pad, 14, AppSpace.pad, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_response == null) ...[
                  const Text('결제 진행', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 6),
                  Text('선택 상품 $count개 · ${formatWon(total)}', style: const TextStyle(fontSize: 13, color: AppColors.ink3)),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 10),
                  ],
                  for (final item in items.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(item, style: const TextStyle(fontSize: 13.5, color: AppColors.ink2)),
                    ),
                  if (items.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('외 ${items.length - 2}개 상품', style: const TextStyle(fontSize: 12, color: AppColors.ink4)),
                    ),
                  const SizedBox(height: 12),
                  if (_submitting)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else
                    AppButton(text: '결제하기', primary: true, large: true, onTap: _completePayment),
                ] else ...[
                  const Text('결제가 완료되었습니다.', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 6),
                  Text('주문번호: ${_response!['order_id']}', style: const TextStyle(fontSize: 13, color: AppColors.ink3)),
                  const SizedBox(height: 10),
                  for (final item in (_response!['items'] as List<dynamic>).take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${item['name']} × ${item['quantity']}', style: const TextStyle(fontSize: 13.5, color: AppColors.ink2)),
                    ),
                  if ((_response!['items'] as List<dynamic>).length > 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('외 ${(_response!['items'] as List<dynamic>).length - 2}개 상품', style: const TextStyle(fontSize: 12, color: AppColors.ink4)),
                    ),
                  const SizedBox(height: 12),
                  AppButton(text: '확인', primary: true, large: true, onTap: () {
                    final response = _response!;
                    Navigator.of(context).pop();
                    widget.onConfirm?.call(response);
                  }),
                ],
              ],
            ),
          ),
        ),
      );
  }
}

// 전역 장바구니 토스트 — 결제바(CheckoutBar)가 보이면 그 위로 미끄러져 올라가고, 없으면 다시 내려온다
class CartToast extends StatefulWidget {
  const CartToast({super.key});

  @override
  State<CartToast> createState() => _CartToastState();
}

class _CartToastState extends State<CartToast> {
  String _lastMessage = '';

  @override
  Widget build(BuildContext context) {
    final store = AppStateScope.watch(context);
    final message = store.cartToastMessage;
    final visible = message != null;
    if (visible) _lastMessage = message;

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final navBarHeight = AppLayout.tabHeight + bottomInset;
    // 결제바가 떠 있으면 그 행의 위쪽으로, 아니면 네비게이션 바 바로 위로
    final restingBottom = navBarHeight + (store.checkoutBarVisible ? AppLayout.checkoutHeight : 0) + 12;

    return AnimatedPositioned(
      // 결제바 유무 변화 시 부드럽게 위/아래로 미끄러짐
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      left: 12,
      right: 12,
      bottom: restingBottom,
      child: AnimatedSlide(
        // 표시/숨김은 아래에서 미끄러져 올라오고 내려가는 모션
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, 1.6),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: visible ? 1 : 0,
          child: IgnorePointer(
            ignoring: !visible,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.potDeep,
                  border: Border.all(color: AppColors.accent, width: AppStroke.hair),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4))],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.accentBright, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _lastMessage,
                        style: const TextStyle(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class PatternBox extends StatelessWidget {
  const PatternBox({required this.pattern, this.child, this.dark = false, super.key});
  final PatternKind pattern;
  final Widget? child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PatternPainter(pattern: pattern, dark: dark),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: dark ? const Color(0xff1f1f1f) : AppColors.line, width: AppStroke.hair)),
        child: child,
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  const PatternPainter({required this.pattern, this.dark = false});
  final PatternKind pattern;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = dark ? const Color(0xff0f0f0f) : AppColors.bgAlt;
    canvas.drawRect(Offset.zero & size, bgPaint);
    final paint = Paint()
      ..color = dark ? const Color(0xff2a2a2a) : AppColors.ink4
      ..strokeWidth = 1;
    final soft = Paint()
      ..color = dark ? const Color(0xff1c1c1c) : AppColors.line
      ..strokeWidth = 1;

    switch (pattern) {
      case PatternKind.dots:
      case PatternKind.halftone:
        final radius = pattern == PatternKind.halftone ? 1.7 : 1.1;
        for (double x = 4; x < size.width; x += 8) {
          for (double y = 4; y < size.height; y += 8) {
            canvas.drawCircle(Offset(x, y), radius, pattern == PatternKind.halftone ? soft : paint);
          }
        }
        break;
      case PatternKind.grid:
      case PatternKind.cross:
        final step = pattern == PatternKind.cross ? 18.0 : 14.0;
        for (double x = 0; x < size.width; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), soft);
        }
        for (double y = 0; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), soft);
        }
        break;
      case PatternKind.lines:
        for (double x = 0; x < size.width; x += 7) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        break;
      case PatternKind.checker:
        final checkerPaint = Paint()..color = dark ? const Color(0xff161616) : AppColors.lineSoft;
        const step = 14.0;
        for (double y = 0; y < size.height; y += step) {
          for (double x = 0; x < size.width; x += step) {
            if (((x / step).floor() + (y / step).floor()).isEven) {
              canvas.drawRect(Rect.fromLTWH(x, y, step / 2, step / 2), checkerPaint);
              canvas.drawRect(Rect.fromLTWH(x + step / 2, y + step / 2, step / 2, step / 2), checkerPaint);
            }
          }
        }
        break;
      case PatternKind.wave:
      case PatternKind.diag:
        final anglePaint = soft;
        for (double i = -size.height; i < size.width + size.height; i += pattern == PatternKind.diag ? 12 : 9) {
          canvas.drawLine(Offset(i, size.height), Offset(i + size.height, 0), anglePaint);
        }
        break;
    }

    final vignette = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.transparent, (dark ? AppColors.ink : AppColors.accent).withValues(alpha: 0.05)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant PatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern || oldDelegate.dark != dark;
  }
}


