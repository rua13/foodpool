import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foodpool/widgets/order_card.dart';
import 'package:foodpool/widgets/foodpool_logo.dart';
import 'package:foodpool/widgets/status_chip.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
    this.allOrders = const [],
    this.myOrders = const [],
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

  List<_OrderCardData> get _visibleOrders {
    final selectedOrders = _showMyOrders ? widget.myOrders : widget.allOrders;
    return selectedOrders
        .map(
          (order) => _OrderCardData(
            orderId: order.orderId,
            title: order.title,
            time: order.time,
            store: order.store,
            price: order.price,
            place: order.place,
            status: OrderStatus.inProgress,
          ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      floatingActionButton: _WriteButton(onTap: widget.onTapWrite),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 51),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: const FoodpoolLogo(
                          textSize: 19.3,
                          iconHeight: 23.26,
                          iconWidth: 13.1,
                          spacing: 2,
                          letterSpacing: 0.07,
                        ),
                      ),
                    ),
                  ),
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
              const SizedBox(height: 11),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  reverseDuration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.linear,
                  layoutBuilder: (currentChild, previousChildren) {
                    final children = <Widget>[...previousChildren];
                    if (currentChild != null) children.add(currentChild);

                    return Stack(
                      alignment: Alignment.topCenter,
                      children: children,
                    );
                  },
                  transitionBuilder: (child, animation) {
                    final isIncoming = child.key == ValueKey<bool>(_showMyOrders);

                    final fadeIn = Tween<double>(
                      begin: 0.86,
                      end: 1,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: const Cubic(0.2, 0.0, 0.0, 1.0),
                      ),
                    );

                    final fadeOut = TweenSequence<double>([
                      TweenSequenceItem<double>(
                        tween: ConstantTween<double>(1),
                        weight: 35,
                      ),
                      TweenSequenceItem<double>(
                        tween: Tween<double>(begin: 1, end: 0),
                        weight: 65,
                      ),
                    ]).animate(
                      CurvedAnimation(
                        parent: ReverseAnimation(animation),
                        curve: Curves.easeOut,
                      ),
                    );

                    return FadeTransition(
                      opacity: isIncoming ? fadeIn : fadeOut,
                      child: child,
                    );
                  },
                  child: ListView.separated(
                    key: ValueKey<bool>(_showMyOrders),
                    padding: const EdgeInsets.only(bottom: 10),
                    itemCount: _visibleOrders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final order = _visibleOrders[index];
                      return _OrderCard(
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
      padding: const EdgeInsets.all(5),
      decoration: ShapeDecoration(
        color: const Color(0x7FECECF0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.25,
            letterSpacing: -0.15,
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.data,
    this.onTap,
  });

  final _OrderCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 192.19),
          padding: const EdgeInsets.fromLTRB(20.61, 20.61, 20.61, 20.61),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 0.62,
                color: Colors.black.withValues(alpha: 0.10),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            shadows: const [
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
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0A0A0A),
                        fontSize: 18,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        letterSpacing: -0.44,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  StatusChip(status: data.status),
                ],
              ),
              const SizedBox(height: 11.5),
              _InfoLine(
                iconPath: 'lib/assets/icons/clock.svg',
                text: data.time,
                bold: true,
                iconSize: 20,
              ),
              const SizedBox(height: 12.77),
              _InfoLine(
                iconPath: 'lib/assets/icons/store.svg',
                text: data.store,
                iconSize: 18,
              ),
              const SizedBox(height: 7.99),
              _InfoLine(
                iconPath: 'lib/assets/icons/card.svg',
                text: data.price,
                iconSize: 18,
              ),
              const SizedBox(height: 7.99),
              _InfoLine(
                iconPath: 'lib/assets/icons/location.svg',
                text: data.place,
                iconSize: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.iconPath,
    required this.text,
    this.bold = false,
    this.iconSize = 18,
  });

  final String iconPath;
  final String text;
  final bool bold;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          iconPath,
          width: iconSize,
          height: iconSize,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: bold ? const Color(0xFF0A0A0A) : const Color(0xB20A0A0A),
              fontSize: bold ? 16 : 14,
              fontFamily: 'Inter',
              fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
              height: bold ? 1.5 : 1.43,
              letterSpacing: bold ? -0.31 : -0.15,
            ),
          ),
        ),
      ],
    );
  }
}

class _WriteButton extends StatelessWidget {
  const _WriteButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9999),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
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
                  'lib/assets/icons/pencil.svg',
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
    );
  }
}

class _OrderCardData {
  const _OrderCardData({
    required this.orderId,
    required this.title,
    required this.time,
    required this.store,
    required this.price,
    required this.place,
    required this.status,
  });

  final String orderId;
  final String title;
  final String time;
  final String store;
  final String price;
  final String place;
  final OrderStatus status;
}
