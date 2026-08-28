part of '../main.dart';

// ─────────────────────────────────────────────────────────────────────────
// v2 주문 완료 흐름 — 결제 → 배송 안내 → [확인] → 주문 결과("사실은요, 안 보냈습니다").
// 욕망의장바구니는 물건을 보내지 않는다. 배송 안내는 끝까지 담백하게 진짜인 척하고,
// 확인을 누른 다음 화면에서 전표에 '미발송' 도장을 찍어 참아서 굳은 돈을 돌려준다.
// 두 화면 모두 v2 문법만 쓴다 — 상세와 같은 그린 바, V2SectionHeader, V2Panel,
// 그린 블록(pot + 골드 1.2px) CTA. 농담 한 줄만 앱의 손글씨체(HSBombaram)로 목소리를 바꾼다.
// (시안: design_mockups/order-flow)
// ─────────────────────────────────────────────────────────────────────────

/// 주문 한 건의 스냅샷 — 결제 시점에 장바구니에서 떠내어 두 화면이 함께 쓴다.
/// 장바구니는 결제 즉시 비워지므로 화면은 store가 아니라 이 스냅샷을 읽는다.
/// 날짜를 필드로 들고 있어 위젯 트리 안에서 DateTime.now()를 부르지 않는다(골든 결정성).
class V2OrderReceipt {
  const V2OrderReceipt({
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

  /// 이번 달 누적 절약액(이번 주문 포함) — 결과 화면 금액 블록 우측에 붙는다.
  final int savedThisMonth;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);
  DateTime get shippingAt => placedAt.add(const Duration(days: 1));
  DateTime get arrivalAt => placedAt.add(const Duration(days: 2));

  /// 주문번호 — 'DD-2608-0417'(연월 + 일련번호). 결제 시점에 한 번 만들어 고정한다.
  static String buildCode(DateTime at, Random random) {
    final yy = (at.year % 100).toString().padLeft(2, '0');
    final mm = at.month.toString().padLeft(2, '0');
    final serial = random.nextInt(10000).toString().padLeft(4, '0');
    return 'DD-$yy$mm-$serial';
  }
}

/// 결제 → 배송 안내 화면을 셸 위(루트 네비게이터)에 띄운다.
void openV2OrderFlow(BuildContext context, V2OrderReceipt receipt) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(builder: (_) => V2OrderDeliveryPage(receipt: receipt)),
  );
}

// ── 공통 조각 ────────────────────────────────────────────────────────────

const _v2OrderWeekdays = ['월', '화', '수', '목', '금', '토', '일'];

String _v2ShortDate(DateTime at) => '${at.month}.${at.day}';

String _v2LongDate(DateTime at) => '${at.month}월 ${at.day}일 (${_v2OrderWeekdays[at.weekday - 1]})';

String _v2ClockTime(DateTime at) => '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

/// 주문 흐름 상단 바 — 상품 상세(_bar)와 같은 그린 바 + 층 표찰.
class _V2OrderBar extends StatelessWidget {
  const _V2OrderBar({required this.title, this.onBack});
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: V2Space.headerHeight,
      padding: EdgeInsets.fromLTRB(onBack == null ? V2Space.pad : 8, 0, 12, 0),
      decoration: const BoxDecoration(
        color: V2Colors.pot,
        border: Border(bottom: BorderSide(color: V2Colors.gold, width: 2)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left_rounded, color: V2Colors.potInk),
            ),
          Text(title, style: V2Text.title.copyWith(color: V2Colors.potInk, fontSize: 17)),
          const Spacer(),
          // 층 레일이 없는 주문 화면에서도 백화점 은유를 잇는 층 표찰(1층 계산대).
          Text('1F · CHECKOUT', style: V2Text.mono.copyWith(color: V2Colors.gold, fontSize: 9)),
        ],
      ),
    );
  }
}

/// 섹션 머리 — V2SectionHeader와 같은 문법(헤어라인 → 인덱스/eyebrow → 타이틀)이지만
/// 주문 화면은 스크롤 상단 여백이 달라 자체 패딩으로 쓴다.
class _V2OrderSectionHead extends StatelessWidget {
  const _V2OrderSectionHead({
    required this.index,
    required this.typeLine,
    required this.title,
    this.typeLineColor = V2Colors.inkFaint,
    this.titleSize = 24,
  });

  final String index;
  final String typeLine;
  final String title;
  final Color typeLineColor;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, thickness: 1, color: V2Colors.line),
        const SizedBox(height: 14),
        Row(
          children: [
            Text('NO.$index', style: V2Text.mono.copyWith(color: V2Colors.inkFaint, fontSize: 10)),
            const Spacer(),
            V2TypeLine(typeLine, color: typeLineColor),
          ],
        ),
        const SizedBox(height: 6),
        Text(title, style: V2Text.title.copyWith(fontSize: titleSize)),
      ],
    );
  }
}

/// 주 CTA — 장바구니 결제 버튼과 같은 그린 블록(pot + 골드 1.2px, 높이 54).
class _V2OrderCta extends StatelessWidget {
  const _V2OrderCta({required this.label, required this.onTap, super.key});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: V2Colors.pot,
          borderRadius: BorderRadius.circular(V2Space.radius),
          border: Border.all(color: V2Colors.gold, width: 1.2),
        ),
        child: Text(label, style: V2Text.title.copyWith(color: V2Colors.potInk, fontSize: 16)),
      ),
    );
  }
}

/// 주문 상품 한 줄 — 장바구니 행(V2CartLineRow)과 같은 anatomy(52 아트 + 브랜드/이름/가격).
class _V2OrderLineRow extends StatelessWidget {
  const _V2OrderLineRow({required this.product, required this.quantity});
  final ProductItem product;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return V2Panel(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          SizedBox(width: 52, height: 52, child: V2Artwork(product: product)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand,
                  style: V2Text.body.copyWith(fontSize: 11, color: V2Colors.inkFaint, fontWeight: FontWeight.w700),
                ),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: V2Text.title.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatWon(product.numericPrice * quantity),
                      style: V2Text.body.copyWith(fontSize: 13, color: V2Colors.ink, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 6),
                    Text('· $quantity개', style: V2Text.body.copyWith(fontSize: 12)),
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
class V2OrderDeliveryPage extends StatelessWidget {
  const V2OrderDeliveryPage({required this.receipt, super.key});
  final V2OrderReceipt receipt;

  void _confirm(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => V2OrderRevealPage(receipt: receipt)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Colors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _V2OrderBar(title: '배송 안내', onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: V2Space.phoneMax),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(V2Space.pad, 32, V2Space.pad, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _V2OrderSectionHead(index: '01', typeLine: 'Delivery', title: '배송 준비 중'),
                          const SizedBox(height: 16),
                          _arrivalPanel(),
                          const SizedBox(height: 22),
                          _timeline(),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Text(
                                'SHIPMENT · ${receipt.itemCount}건',
                                style: V2Text.mono.copyWith(color: V2Colors.inkFaint, fontSize: 10),
                              ),
                              const Spacer(),
                              const V2TypeLine('묶음 배송', color: V2Colors.goldDeep),
                            ],
                          ),
                          for (final line in receipt.lines)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: _V2OrderLineRow(product: line.product, quantity: line.quantity),
                            ),
                          const SizedBox(height: 18),
                          const Divider(height: 1, thickness: 1, color: V2Colors.line),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('결제 금액 (${receipt.itemCount})', style: V2Text.title.copyWith(fontSize: 15)),
                              Text(
                                formatWon(receipt.total),
                                style: V2Text.title.copyWith(fontSize: 20, color: V2Colors.crave),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: V2Space.phoneMax),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(V2Space.pad, 0, V2Space.pad, 24),
                  child: Column(
                    children: [
                      _V2OrderCta(
                        key: const Key('v2_order_confirm'),
                        label: '확인',
                        onTap: () => _confirm(context),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '확인을 누르면 이번 주문의 결과를 알려드립니다.',
                        style: V2Text.body.copyWith(fontSize: 11, color: V2Colors.inkFaint),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _arrivalPanel() {
    return V2Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              V2SetCode(receipt.code),
              const SizedBox(height: 6),
              Text('도착 예정', style: V2Text.body.copyWith(fontSize: 13)),
            ],
          ),
          const Spacer(),
          Text(
            _v2LongDate(receipt.arrivalAt),
            style: V2Text.title.copyWith(fontSize: 20, color: V2Colors.pot),
          ),
        ],
      ),
    );
  }

  Widget _timeline() {
    final steps = <({String label, String meta, _V2StepState state})>[
      (
        label: '결제 완료',
        meta: '${_v2ShortDate(receipt.placedAt)} ${_v2ClockTime(receipt.placedAt)}',
        state: _V2StepState.done
      ),
      (label: '상품 준비 중', meta: 'NOW', state: _V2StepState.current),
      (label: '배송 중', meta: '${_v2ShortDate(receipt.shippingAt)} 예정', state: _V2StepState.todo),
      (label: '배송 완료', meta: '${_v2ShortDate(receipt.arrivalAt)} 예정', state: _V2StepState.todo),
    ];
    return Stack(
      children: [
        // 단계를 잇는 세로 괘선 — 첫/마지막 점 중심까지만 그린다.
        Positioned(top: 10, bottom: 10, left: 5, width: 2, child: Container(color: V2Colors.line)),
        Column(
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 20),
                child: _V2TimelineRow(label: steps[i].label, meta: steps[i].meta, state: steps[i].state),
              ),
          ],
        ),
      ],
    );
  }
}

enum _V2StepState { done, current, todo }

class _V2TimelineRow extends StatelessWidget {
  const _V2TimelineRow({required this.label, required this.meta, required this.state});
  final String label;
  final String meta;
  final _V2StepState state;

  @override
  Widget build(BuildContext context) {
    final isCurrent = state == _V2StepState.current;
    final isTodo = state == _V2StepState.todo;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isTodo
                ? V2Colors.paper
                : isCurrent
                    ? V2Colors.crave
                    : V2Colors.pot,
            border: isTodo ? Border.all(color: V2Colors.line, width: 2) : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: V2Text.body.copyWith(
              fontSize: 13,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
              color: isTodo ? V2Colors.inkFaint : (isCurrent ? V2Colors.ink : V2Colors.inkSoft),
            ),
          ),
        ),
        if (isCurrent)
          Text(meta, style: V2Text.mono.copyWith(fontSize: 10, color: V2Colors.crave))
        else
          Text(meta, style: V2Text.body.copyWith(fontSize: 11, color: V2Colors.inkFaint)),
      ],
    );
  }
}

// ── 2. 주문 결과(반전) ───────────────────────────────────────────────────

/// 주문 결과 — 전표는 그대로 두고 '미발송' 도장만 얹어 앞 화면이 거짓이었음을 보여준다.
class V2OrderRevealPage extends StatelessWidget {
  const V2OrderRevealPage({required this.receipt, super.key});
  final V2OrderReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Colors.paper,
      body: SafeArea(
        child: Column(
          children: [
            const _V2OrderBar(title: '주문 결과'),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: V2Space.phoneMax),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(V2Space.pad, 32, V2Space.pad, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _V2OrderSectionHead(
                            index: '02',
                            typeLine: 'Order result',
                            title: '사실은요,\n안 보냈습니다',
                            typeLineColor: V2Colors.crave,
                            titleSize: 28,
                          ),
                          const SizedBox(height: 14),
                          // 농담 한 줄만 손글씨체로 목소리를 바꾼다 — 나머지는 본문체 그대로.
                          // 두 줄로 접히면 농담이 죽으므로 좁은 화면에선 축소해서 한 줄을 지킨다.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '상자는 비어 있었어요, 헤헤.',
                              key: const Key('v2_order_joke'),
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: doguTitleFontFamily,
                                // Thin 한 굵기만 등록된 손글씨체 — w100을 명시해야 폴백으로 새지 않는다.
                                fontFamilyFallback: const [doguHeroFontFamily, doguFontFamily],
                                fontWeight: FontWeight.w100,
                                fontSize: 30,
                                height: 1.25,
                                color: V2Colors.crave,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('결제도 이루어지지 않았습니다.', style: V2Text.body.copyWith(fontSize: 13)),
                          const SizedBox(height: 20),
                          _slip(),
                          const SizedBox(height: 18),
                          _savedBlock(),
                          const SizedBox(height: 16),
                          _potWord(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: V2Space.phoneMax),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(V2Space.pad, 0, V2Space.pad, 24),
                  child: _V2OrderCta(
                    key: const Key('v2_order_done'),
                    label: '오늘은 내가 이겼다',
                    onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 전표 — 앞 화면과 같은 서식에 '미발송' 도장이 비스듬히 찍힌다.
  Widget _slip() {
    return Stack(
      children: [
        V2CardFrame(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              V2SetCode(receipt.code),
              const SizedBox(height: 9),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('결제 예정이던 금액', style: V2Text.body.copyWith(fontSize: 13)),
                  Text(
                    formatWon(receipt.total),
                    style: V2Text.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: V2Colors.inkFaint,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 9),
                child: Divider(height: 1, thickness: 1, color: V2Colors.line),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('실제로 나간 돈', style: V2Text.title.copyWith(fontSize: 15)),
                  Text('₩0', style: V2Text.title.copyWith(fontSize: 20, color: V2Colors.pot)),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          right: 10,
          top: -8,
          child: Transform.rotate(
            angle: -11 * pi / 180,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: V2Colors.paper.withValues(alpha: 0.78),
                border: Border.all(color: V2Colors.crave, width: 2),
                borderRadius: BorderRadius.circular(V2Space.radiusSm),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '미발송',
                    style: V2Text.title.copyWith(fontSize: 15, color: V2Colors.crave, letterSpacing: 2),
                  ),
                  const SizedBox(height: 2),
                  Text('NOT SHIPPED', style: V2Text.mono.copyWith(fontSize: 7, color: V2Colors.crave)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 굳은 돈 — 장바구니 토스트·CTA와 같은 그린 블록(pot + 골드 1.2px).
  Widget _savedBlock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: V2Colors.pot,
        borderRadius: BorderRadius.circular(V2Space.radius),
        border: Border.all(color: V2Colors.gold, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('참아서 굳은 돈', style: V2Text.body.copyWith(fontSize: 12, color: V2Colors.potSoft)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatWon(receipt.total),
                    style: V2Text.title.copyWith(fontSize: 40, color: V2Colors.potInk, letterSpacing: -1.4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${receipt.placedAt.month}월 누적 ${formatWon(receipt.savedThisMonth)}',
                style: V2Text.body.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: V2Colors.gold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _potWord() {
    return V2Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(child: Image.asset('assets/logo-square.png', width: 34, height: 34, fit: BoxFit.cover)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              '욕망은 제 항아리에 잘 담아 뒀습니다.\n돈은 손님 통장에 그대로 두고요.',
              style: V2Text.body.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
