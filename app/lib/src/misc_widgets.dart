part of '../main.dart';

class PaymentToastOverlay extends StatefulWidget {
  const PaymentToastOverlay({required this.orderSummary, this.onConfirm, super.key});

  final Map<String, dynamic> orderSummary;
  final VoidCallback? onConfirm;

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
    final navBarHeight = AppSpace.tabHeight + MediaQuery.viewPaddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: navBarHeight),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 24, offset: Offset(0, -2))],
          ),
            padding: const EdgeInsets.fromLTRB(AppSpace.pad, 14, AppSpace.pad, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_response == null) ...[
                  const Text('결제 진행', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
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
                  const Text('결제가 완료되었습니다.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
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
                    Navigator.of(context).pop();
                    widget.onConfirm?.call();
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
    final navBarHeight = AppSpace.tabHeight + bottomInset;
    // 결제바가 떠 있으면 그 행의 위쪽으로, 아니면 네비게이션 바 바로 위로
    final restingBottom = navBarHeight + (store.checkoutBarVisible ? AppSpace.checkoutHeight : 0) + 12;

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
                  color: AppColors.ink,
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
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
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

class Eyebrow extends StatelessWidget {
  const Eyebrow({required this.index, required this.text, this.inverted = false, super.key});
  final String index;
  final String text;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: monoStyle.copyWith(fontSize: 10, color: inverted ? AppColors.ink4 : AppColors.ink3, letterSpacing: 0.4),
          children: [
            TextSpan(text: '[ $index ] ', style: const TextStyle(color: AppColors.accent)),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

class SkeletonProductCard extends StatelessWidget {
  const SkeletonProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AspectRatio(aspectRatio: 1, child: ColoredBox(color: AppColors.bgAlt)),
        Container(height: 1, color: AppColors.line),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 9, width: 56, color: AppColors.bgAlt, margin: const EdgeInsets.only(bottom: 6)),
              Container(height: 11, color: AppColors.bgAlt, margin: const EdgeInsets.only(bottom: 4)),
              Container(height: 11, width: 90, color: AppColors.bgAlt, margin: const EdgeInsets.only(bottom: 12)),
              Container(height: 13, width: 72, color: AppColors.bgAlt),
            ],
          ),
        ),
      ],
    );
  }
}

class AppButton extends StatelessWidget {
  const AppButton({required this.text, this.primary = false, this.large = false, this.onDark = false, this.onTap, super.key});
  final String text;
  final bool primary;
  final bool large;
  final bool onDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    if (onDark) {
      // 검은 광고 배경 위에서 테마색(accent)을 또렷하게 보여주는 버튼
      if (primary) {
        bgColor = AppColors.accentDeep;
        borderColor = AppColors.accentDeep;
        textColor = Colors.white;
      } else {
        // 노트 버튼: 밝은 회색 배경 + 검은 글씨 + 검은 테두리
        bgColor = AppColors.heroChip;
        borderColor = AppColors.ink;
        textColor = AppColors.ink;
      }
    } else {
      bgColor = primary ? AppColors.accent : AppColors.bg;
      borderColor = primary ? AppColors.accent : AppColors.line;
      textColor = primary ? AppColors.invert : AppColors.ink;
    }
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: large ? 48 : 42,
          padding: EdgeInsets.symmetric(horizontal: large ? 22 : 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
          ),
          child: Text(text, style: TextStyle(fontSize: (large ? 13.5 : 13) + (onDark && primary ? 2 : 0), fontWeight: FontWeight.w600, color: textColor)),
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
        decoration: BoxDecoration(border: Border.all(color: dark ? const Color(0xff1f1f1f) : AppColors.line)),
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

class CornerMark extends StatelessWidget {
  const CornerMark({required this.alignment, super.key});
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    return Align(
      alignment: alignment,
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppColors.ink) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppColors.ink) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppColors.ink) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppColors.ink) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class SectionBorder extends StatelessWidget {
  const SectionBorder({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: child,
    );
  }
}

class Tag extends StatelessWidget {
  const Tag({required this.text, this.compact = false, this.dark = false, super.key});
  final String text;
  final bool compact;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 7, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: dark ? AppColors.heroChip : null,
        border: Border.all(color: dark ? AppColors.heroChip : AppColors.line),
      ),
      child: MonoText(text, size: compact ? 9.5 : 10, weight: FontWeight.w600, color: dark ? AppColors.ink : (compact ? AppColors.ink3 : AppColors.ink)),
    );
  }
}

class BadgePill extends StatelessWidget {
  const BadgePill({required this.text, required this.color, this.ink = Colors.white, this.bordered = false, this.compact = false, super.key});
  final String text;
  final Color color;
  final Color ink;
  final bool bordered;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(color: color, border: bordered ? Border.all(color: AppColors.line) : null),
      child: MonoText(text, size: compact ? 9 : 9.5, color: ink, weight: FontWeight.w700),
    );
  }
}

class MonoText extends StatelessWidget {
  const MonoText(this.text, {this.size = 12, this.color = AppColors.ink, this.weight = FontWeight.w400, this.align, super.key});
  final String text;
  final double size;
  final Color color;
  final FontWeight weight;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: monoStyle.copyWith(fontSize: size, color: color, fontWeight: weight),
    );
  }
}

class StrikeText extends StatelessWidget {
  const StrikeText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: monoStyle.copyWith(
        fontSize: 10.5,
        color: AppColors.ink4,
        decoration: TextDecoration.lineThrough,
        decorationColor: AppColors.ink4,
      ),
    );
  }
}
