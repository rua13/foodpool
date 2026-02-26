import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class LogoScreen extends StatefulWidget {
  const LogoScreen({super.key});

  @override
  State<LogoScreen> createState() => _LogoScreenState();
}

class _LogoScreenState extends State<LogoScreen>
    with SingleTickerProviderStateMixin {
  static const double _iconWidth = 14;
  static const double _iconHeight = 24;
  static const double _iconTextGap = 6;
  static const double _pairGap = 24;

  late final AnimationController _controller;
  late final Animation<double> _bothToLeftProgress;
  late final Animation<double> _knifeToRightProgress;
  late final Animation<double> _textFollowKnifeProgress;
  late final Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _bothToLeftProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.12, 0.44, curve: Curves.easeOutCubic),
    );
    _knifeToRightProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.44, 0.88, curve: Curves.easeOutCubic),
    );
    _textFollowKnifeProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.96, curve: Curves.easeOutCubic),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.56, 0.86, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final brandStyle = GoogleFonts.unbounded(
              color: const Color(0xFFFF5751),
              fontSize: 30.01,
              fontWeight: FontWeight.w700,
              height: 0.74,
              letterSpacing: 0.19,
            );
            final textPainter = TextPainter(
              text: TextSpan(text: 'FOODPOOL', style: brandStyle),
              textDirection: TextDirection.ltr,
            )..layout();
            final targetIconOffset =
                (textPainter.width / 2) + _iconTextGap + (_iconWidth / 2);
            final forkStart = -_pairGap / 2;
            final knifeStart = _pairGap / 2;
            final forkFinal = -targetIconOffset;
            final knifeFinal = targetIconOffset;

            // Phase 1 end: both icons are on the left while keeping their pair gap.
            final forkAtLeft = forkFinal;
            final knifeAtLeftEnd = forkFinal + _pairGap;

            final forkX = forkStart +
                (forkAtLeft - forkStart) * _bothToLeftProgress.value;
            final knifeAtLeft = knifeStart +
                (knifeAtLeftEnd - knifeStart) * _bothToLeftProgress.value;
            final knifeX = knifeAtLeft +
                (knifeFinal - knifeAtLeft) * _knifeToRightProgress.value;
            final textFollowKnifeBase = (knifeX - knifeFinal) * 0.75;
            final textX = textFollowKnifeBase *
                (1 - _textFollowKnifeProgress.value);

            return SizedBox(
              width: 320,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(forkX, 0),
                    child: SvgPicture.asset(
                      'lib/assets/icons/logo1.svg',
                      width: _iconWidth,
                      height: _iconHeight,
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(knifeX, 0),
                    child: SvgPicture.asset(
                      'lib/assets/icons/logo2.svg',
                      width: _iconWidth,
                      height: _iconHeight,
                    ),
                  ),
                  Opacity(
                    opacity: _textOpacity.value,
                    child: Transform.translate(
                      offset: Offset(textX, 0),
                      child: Text(
                        'FOODPOOL',
                        textAlign: TextAlign.center,
                        style: brandStyle,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
