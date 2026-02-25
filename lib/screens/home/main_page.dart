import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foodpool/widgets/order_card.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
    required this.allOrders,
    required this.myOrders,
    this.onTapWrite,
    this.onTapProfile,
    this.onTapOrder,
  });

  final List<OrderCardData> allOrders;
  final List<OrderCardData> myOrders;


  final VoidCallback? onTapWrite;
  final VoidCallback? onTapProfile;
  final ValueChanged<String>? onTapOrder;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _showMyOrders = false;

  void _setOrderMode(bool showMyOrders) {
    if (_showMyOrders == showMyOrders) return;
    setState(() => _showMyOrders = showMyOrders);
  }

  List<OrderCardData> get _visibleOrders {
    if (!_showMyOrders) return widget.allOrders;
    return widget.allOrders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _WriteButton(onTap: widget.onTapWrite),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'FOODPOOL',
                    style: TextStyle(
                      color: Color(0xFFFF5751),
                      fontSize: 24,
                      fontFamily: 'Unbounded',
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      letterSpacing: 0.07,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: widget.onTapProfile,
                    child: SvgPicture.asset(
                      'lib/assets/icons/profile.svg',
                      width: 28,
                      height: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _OrderSegment(
                showMyOrders: _showMyOrders,
                onSelectAll: () => _setOrderMode(false),
                onSelectMine: () => _setOrderMode(true),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  reverseDuration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.linear,
                  switchOutCurve: Curves.linear,
                  transitionBuilder: (child, animation) {
                    final isIncoming =
                        child.key == ValueKey<bool>(_showMyOrders);

                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: isIncoming
                          // Figma-like gentle ease out for entering content.
                          ? const Cubic(0.22, 1.0, 0.36, 1.0)
                          // Slightly faster ease in for exiting content.
                          : const Cubic(0.4, 0.0, 1.0, 1.0),
                    );

                    final fade = Tween<double>(
                      begin: isIncoming ? 0.0 : 1.0,
                      end: isIncoming ? 1.0 : 0.0,
                    ).animate(curved);

                    return FadeTransition(
                      opacity: fade,
                      child: child,
                    );
                  },
                  child: ListView.separated(
                    key: ValueKey<bool>(_showMyOrders),
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: _visibleOrders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final order = _visibleOrders[index];
                      return OrderCard(
                        data: order,
                        onTap: widget.onTapOrder == null
                            ? null
                            : () => widget.onTapOrder!(order.orderId),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSegment extends StatelessWidget {
  const _OrderSegment({
    required this.showMyOrders,
    required this.onSelectAll,
    required this.onSelectMine,
  });

  final bool showMyOrders;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectMine;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 49,
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: const Color(0x7FECECF0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: '전체 주문',
              selected: !showMyOrders,
              onTap: onSelectAll,
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: '내 주문',
              selected: showMyOrders,
              onTap: onSelectMine,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: ShapeDecoration(
          color: selected ? Colors.white : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          shadows: selected
              ? const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                    spreadRadius: -1,
                  ),
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? const Color(0xFF0A0A0A) : const Color(0xFF717182),
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.43,
            letterSpacing: -0.15,
          ),
        ),
      ),
    );
  }
}

class _WriteButton extends StatelessWidget {
  const _WriteButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(9999),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 44,
            minWidth: 104.3,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: ShapeDecoration(
              color: const Color(0xFFFF5751),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              shadows: const [
                BoxShadow(
                  color: Color(0x19000000),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Color(0x19000000),
                  blurRadius: 15,
                  offset: Offset(0, 10),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'lib/assets/icons/card.svg',
                    width: 20,
                    height: 20,
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '글쓰기',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.43,
                      letterSpacing: -0.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}