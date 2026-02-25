import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OrderCardData {
  const OrderCardData({
    required this.orderId,
    required this.title,
    required this.time,
    required this.store,
    required this.price,
    required this.place,
  });

  final String orderId;
  final String title;
  final String time;
  final String store;
  final String price;
  final String place;
}

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.data,
    this.onTap,
  });

  final OrderCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
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
              Text(
                data.title,
                style: const TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: -0.44,
                ),
              ),
              const SizedBox(height: 12),
              InfoLine(
                iconPath: 'lib/assets/icons/clock.svg',
                text: data.time,
                bold: true,
                iconSize: 20,
              ),
              const SizedBox(height: 12),
              InfoLine(
                iconPath: 'lib/assets/icons/store.svg',
                text: data.store,
              ),
              const SizedBox(height: 8),
              InfoLine(
                iconPath: 'lib/assets/icons/card.svg',
                text: data.price,
              ),
              const SizedBox(height: 8),
              InfoLine(
                iconPath: 'lib/assets/icons/location.svg',
                text: data.place,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoLine extends StatelessWidget {
  const InfoLine({
    super.key,
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