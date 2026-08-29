part of '../main.dart';

// ─────────────────────────────────────────────────────────────────────────
// 주문 완료 흐름 — 결제 → 배송 안내 → [확인] → 주문 결과("사실은요, 안 보냈습니다").
// 욕망의장바구니는 물건을 보내지 않는다. 배송 안내는 끝까지 담백하게 진짜인 척하고,
// 확인을 누른 다음 화면에서 전표에 '미발송' 도장을 찍어 참아서 굳은 돈을 돌려준다.
// 두 화면 모두 v1 문법만 쓴다 — 흰 배경 + 헤어라인 박스, MonoText 마이크로 레이블,
// 30px 대형 진술, AppButton(primary) 그린 CTA, 잉크 블랙 금액 블록(결제바와 같은 결).
// 농담 한 줄만 브랜드 손글씨체(HSBombaram)로 목소리를 바꾼다.
// ─────────────────────────────────────────────────────────────────────────

/// 주문 한 건의 스냅샷 — 결제 시점에 떠내어 두 화면이 함께 쓴다.
/// 장바구니는 결제와 함께 비워지므로 화면은 store가 아니라 이 스냅샷을 읽는다.
/// 날짜를 필드로 들고 있어 위젯 트리 안에서 DateTime.now()를 부르지 않는다(골든 결정성).
class OrderReceipt {
  const OrderReceipt({
    required this.code,
    required this.lines,
    required this.total,
    required this.placedAt,
    required this.savedThisMonth,
  });

  final String code;
  final List<({ProductItem product, int quantity})> lines;
  final int total;
  final DateTime placedAt;

  /// 이번 달 누적 절약액(이번 주문 포함) — 결과 화면 금액 블록에 붙는다.
  final int savedThisMonth;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);
  DateTime get shippingAt => placedAt.add(const Duration(days: 1));
  DateTime get arrivalAt => placedAt.add(const Duration(days: 2));

  /// 백엔드 응답(submitSelectedOrder)과 스토어 카탈로그로 스냅샷을 만든다.
  /// 응답의 product_id로 상품을 되찾고, 못 찾으면 그 줄은 건너뛴다.
  static OrderReceipt fromResponse(
    AppStore store,
    Map<String, dynamic> response, {
    required DateTime placedAt,
    required int savedThisMonth,
  }) {
    final rawItems = (response['items'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    return OrderReceipt(
      code: (response['order_id'] ?? '').toString(),
      lines: [
        for (final item in rawItems)
          (
            product: store.productById((item['product_id'] ?? '').toString()),
            quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          ),
      ],
      total: (response['total_price'] as num?)?.toInt() ?? 0,
      placedAt: placedAt,
      savedThisMonth: savedThisMonth,
    );
  }
}

/// 배송 안내 화면을 루트 네비게이터에 띄운다(결제 오버레이가 닫힌 뒤).
Future<void> openOrderFlow(BuildContext context, OrderReceipt receipt, {VoidCallback? onDone}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(builder: (_) => OrderDeliveryPage(receipt: receipt, onDone: onDone)),
  );
}

// ── 공통 조각 ────────────────────────────────────────────────────────────

const _orderWeekdays = ['월', '화', '수', '목', '금', '토', '일'];

String _shortDate(DateTime at) => '${at.month}.${at.day}';

String _longDate(DateTime at) => '${at.month}월 ${at.day}일 (${_orderWeekdays[at.weekday - 1]})';

String _clockTime(DateTime at) => '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

/// 주문 화면 상단 바 — 상품 정보 페이지와 같은 플랫 화이트 앱바.
PreferredSizeWidget _orderAppBar(String title, {bool back = true}) {
  return AppBar(
    backgroundColor: AppColors.bg,
    surfaceTintColor: AppColors.bg,
    elevation: 0,
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: back,
    title: Text(title, style: const TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w700)),
    iconTheme: const IconThemeData(color: AppColors.ink),
  );
}

/// 대형 진술 — v1 필드 노트와 같은 30px / height 1.05 / letterSpacing -1.
class _OrderStatement extends StatelessWidget {
  const _OrderStatement(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 30, height: 1.05, letterSpacing: -1, fontWeight: FontWeight.w700),
    );
  }
}

/// 주문 상품 한 줄 — 장바구니 행의 anatomy를 요약형으로(썸네일 + 브랜드/이름/금액).
class _OrderLineRow extends StatelessWidget {
  const _OrderLineRow({required this.index, required this.product, required this.quantity});
  final int index;
  final ProductItem product;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: ProductImageSurface(
              pattern: product.pattern,
              imageUrl: product.imageUrl,
              artwork: product.artwork,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: MonoText(index.toString().padLeft(3, '0'), size: 9, color: AppColors.ink4),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonoText(product.brand, size: 10, color: AppColors.ink4),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    MonoText(formatWon(product.numericPrice * quantity), size: 14, weight: FontWeight.w700),
                    const SizedBox(width: 8),
                    MonoText('× $quantity', size: 11, color: AppColors.ink3),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 1. 배송 안내 ─────────────────────────────────────────────────────────

/// 배송 안내 — 끝까지 담백하게. 앞장에서 힌트를 흘리면 다음 장의 반전이 죽는다.
class OrderDeliveryPage extends StatelessWidget {
  const OrderDeliveryPage({required this.receipt, this.onDone, super.key});
  final OrderReceipt receipt;
  final VoidCallback? onDone;

  void _confirm(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => OrderRevealPage(receipt: receipt, onDone: onDone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _orderAppBar('배송 안내'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.pad, 10, AppSpace.pad, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MonoText('ORDER — ${receipt.code}', size: 10, color: AppColors.ink3),
                    const SizedBox(height: 14),
                    const _OrderStatement('배송 준비 중'),
                    const SizedBox(height: 12),
                    const Text(
                      '주문이 접수됐습니다. 아래 일정으로 보내드릴 예정입니다.',
                      style: TextStyle(fontSize: 13.5, height: 1.65, color: AppColors.ink2),
                    ),
                    const SizedBox(height: 22),
                    _arrivalBox(),
                    const SizedBox(height: 24),
                    _timeline(),
                    const SizedBox(height: 26),
                    MonoText('SHIPMENT — ${receipt.itemCount}건', size: 10, weight: FontWeight.w700),
                    const SizedBox(height: 2),
                    for (var i = 0; i < receipt.lines.length; i++)
                      _OrderLineRow(
                        index: i + 1,
                        product: receipt.lines[i].product,
                        quantity: receipt.lines[i].quantity,
                      ),
                    const SizedBox(height: 6),
                    SummaryLine(label: '배송비', value: '무료'),
                    SummaryLine(label: '결제 금액', value: formatWon(receipt.total), total: true),
                  ],
                ),
              ),
            ),
          ),
          _OrderBottomBar(
            label: '확인',
            note: '// 확인을 누르면 이번 주문의 결과를 알려드립니다',
            buttonKey: const Key('order_confirm'),
            onTap: () => _confirm(context),
          ),
        ],
      ),
    );
  }

  Widget _arrivalBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bgAlt, border: Border.all(color: AppColors.line)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const MonoText('도착 예정', size: 11, color: AppColors.ink3),
          const Spacer(),
          Text(
            _longDate(receipt.arrivalAt),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }

  Widget _timeline() {
    final steps = <({String label, String meta, _StepState state})>[
      (label: '결제 완료', meta: '${_shortDate(receipt.placedAt)} ${_clockTime(receipt.placedAt)}', state: _StepState.done),
      (label: '상품 준비 중', meta: 'NOW', state: _StepState.current),
      (label: '배송 중', meta: '${_shortDate(receipt.shippingAt)} 예정', state: _StepState.todo),
      (label: '배송 완료', meta: '${_shortDate(receipt.arrivalAt)} 예정', state: _StepState.todo),
    ];
    return Stack(
      children: [
        // 단계를 잇는 세로 괘선 — 첫/마지막 점 중심까지만 그린다.
        Positioned(top: 9, bottom: 9, left: 4, width: 1, child: Container(color: AppColors.line)),
        Column(
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 18),
                child: _TimelineRow(label: steps[i].label, meta: steps[i].meta, state: steps[i].state),
              ),
          ],
        ),
      ],
    );
  }
}

enum _StepState { done, current, todo }

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.label, required this.meta, required this.state});
  final String label;
  final String meta;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final isCurrent = state == _StepState.current;
    final isTodo = state == _StepState.todo;
    return Row(
      children: [
        // 각진 v1 문법에 맞춰 점은 정사각형.
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: isTodo
                ? AppColors.bg
                : isCurrent
                    ? AppColors.alert
                    : AppColors.ink,
            border: isTodo ? Border.all(color: AppColors.line) : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isTodo ? AppColors.ink4 : AppColors.ink,
            ),
          ),
        ),
        MonoText(
          meta,
          size: isCurrent ? 10 : 11,
          weight: isCurrent ? FontWeight.w700 : FontWeight.w400,
          color: isCurrent
              ? AppColors.alert
              : isTodo
                  ? AppColors.ink4
                  : AppColors.ink3,
        ),
      ],
    );
  }
}

// ── 2. 주문 결과(반전) ───────────────────────────────────────────────────

/// 주문 결과 — 전표는 그대로 두고 '미발송' 도장만 얹어 앞 화면이 거짓이었음을 보여준다.
class OrderRevealPage extends StatelessWidget {
  const OrderRevealPage({required this.receipt, this.onDone, super.key});
  final OrderReceipt receipt;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _orderAppBar('주문 결과', back: false),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.pad, 10, AppSpace.pad, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MonoText('ORDER RESULT', size: 10, color: AppColors.alert, weight: FontWeight.w700),
                    const SizedBox(height: 14),
                    const _OrderStatement('사실은요,\n안 보냈습니다'),
                    const SizedBox(height: 12),
                    // 농담 한 줄만 손글씨체로 목소리를 바꾼다 — 나머지는 본문체 그대로.
                    // 두 줄로 접히면 농담이 죽으므로 좁은 화면에선 축소해 한 줄을 지킨다.
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '상자는 비어 있었어요, 헤헤.',
                        key: Key('order_joke'),
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: doguTitleFontFamily,
                          // Thin 한 굵기만 등록된 손글씨체 — w100을 명시해야 폴백으로 새지 않는다.
                          fontFamilyFallback: [doguHeroFontFamily, doguFontFamily],
                          fontWeight: FontWeight.w100,
                          fontSize: 30,
                          height: 1.25,
                          color: AppColors.alert,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '결제도 이루어지지 않았습니다.',
                      style: TextStyle(fontSize: 13.5, height: 1.65, color: AppColors.ink2),
                    ),
                    const SizedBox(height: 22),
                    _slip(),
                    const SizedBox(height: 18),
                    _savedBlock(),
                    const SizedBox(height: 14),
                    const MonoText(
                      '// 욕망은 여기 두고 갑니다 — 돈은 그대로 손님 것',
                      size: 10.5,
                      color: AppColors.ink4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _OrderBottomBar(
            label: '오늘은 내가 이겼다',
            buttonKey: const Key('order_done'),
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              onDone?.call();
            },
          ),
        ],
      ),
    );
  }

  /// 전표 — 앞 화면과 같은 서식에 '미발송' 도장이 비스듬히 찍힌다.
  Widget _slip() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.bg, border: Border.all(color: AppColors.line)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MonoText(receipt.code, size: 9, color: AppColors.ink4),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('결제 예정이던 금액', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
                  StrikeText(formatWon(receipt.total)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, thickness: 1, color: AppColors.line),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('실제로 나간 돈', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const MonoText('₩0', size: 22, weight: FontWeight.w800, color: AppColors.accent),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          right: 10,
          top: -10,
          child: Transform.rotate(
            angle: -11 * pi / 180,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.bg,
                border: Border.all(color: AppColors.alert, width: 2),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '미발송',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppColors.alert,
                    ),
                  ),
                  SizedBox(height: 2),
                  MonoText('NOT SHIPPED', size: 7, color: AppColors.alert, weight: FontWeight.w700),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 굳은 돈 — 결제바와 같은 잉크 블랙 블록.
  Widget _savedBlock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      color: AppColors.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MonoText('참아서 굳은 돈', size: 11, color: AppColors.ink4),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: MonoText(
                    formatWon(receipt.total),
                    size: 34,
                    color: AppColors.invert,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              MonoText(
                '${receipt.placedAt.month}월 누적 ${formatWon(receipt.savedThisMonth)}',
                size: 11,
                color: AppColors.ink4,
                weight: FontWeight.w700,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 하단 고정 CTA — 헤어라인 위 그린 버튼(+ 선택적 모노 캡션).
class _OrderBottomBar extends StatelessWidget {
  const _OrderBottomBar({required this.label, required this.onTap, required this.buttonKey, this.note});
  final String label;
  final VoidCallback onTap;
  final Key buttonKey;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.pad, 14, AppSpace.pad, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(key: buttonKey, text: label, primary: true, large: true, onTap: onTap),
              if (note != null) ...[
                const SizedBox(height: 10),
                Center(child: MonoText(note!, size: 10.5, color: AppColors.ink4)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
