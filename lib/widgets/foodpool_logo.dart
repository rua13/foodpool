import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class FoodpoolLogo extends StatelessWidget {
  const FoodpoolLogo({
    super.key,
    this.textSize = 30,
    this.iconHeight = 24,
    this.iconWidth = 14,
    this.spacing = 2.5,
    this.color = const Color(0xFFFF5751),
    this.letterSpacing = 0.19,
    this.fontWeight = FontWeight.w700,
  });

  final double textSize;
  final double iconHeight;
  final double iconWidth;
  final double spacing;
  final Color color;
  final double letterSpacing;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'lib/assets/icons/logo1.svg',
          width: iconWidth,
          height: iconHeight,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        SizedBox(width: spacing),
        Text(
          'FOODPOOL',
          textAlign: TextAlign.center,
          style: GoogleFonts.unbounded(
            color: color,
            fontSize: textSize,
            fontWeight: fontWeight,
            height: 1,
            letterSpacing: letterSpacing,
          ),
        ),
        SizedBox(width: spacing),
        SvgPicture.asset(
          'lib/assets/icons/logo2.svg',
          width: iconWidth,
          height: iconHeight,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ],
    );
  }
}
